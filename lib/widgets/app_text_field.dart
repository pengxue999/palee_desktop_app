import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

enum DigitOnly { integer, decimal }

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  final double? maxValue;

  _ThousandsSeparatorFormatter({this.maxValue});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    if (!RegExp(r'^\d+$').hasMatch(digits)) return oldValue;

    // Strip leading zeros (e.g. "0", "05" -> "5"); empty result means cleared.
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    if (maxValue != null) {
      final value = double.tryParse(digits) ?? 0;
      if (value > maxValue!) {
        return oldValue;
      }
    }

    final formatted = _format(digits);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buf = StringBuffer();
    final reversed = digits.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(',');
      buf.write(reversed[i]);
    }
    return buf.toString().split('').reversed.join();
  }
}

class _NumericRangeFormatter extends TextInputFormatter {
  final bool allowDecimal;
  final double? maxValue;
  final bool noLeadingZero;

  _NumericRangeFormatter({
    required this.allowDecimal,
    this.maxValue,
    this.noLeadingZero = false,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    final hasInvalidCharacter = text.runes.any((char) {
      final isDigit = char >= 48 && char <= 57;
      final isDecimalPoint = allowDecimal && char == 46;
      return !isDigit && !isDecimalPoint;
    });
    if (hasInvalidCharacter) {
      return oldValue;
    }

    // Reject a leading zero (e.g. "0", "05"). For decimals, "0.5" is allowed.
    if (noLeadingZero && text.startsWith('0')) {
      final isDecimalZero = allowDecimal && text.startsWith('0.');
      if (!isDecimalZero) {
        return oldValue;
      }
    }

    if (!allowDecimal && text.contains('.')) {
      return oldValue;
    }

    final decimalPoints = '.'.allMatches(text).length;
    if (decimalPoints > 1) {
      return oldValue;
    }

    if (text == '.') {
      return allowDecimal ? newValue : oldValue;
    }

    if (maxValue != null) {
      final value = double.tryParse(text);
      if (value != null && value > maxValue!) {
        return oldValue;
      }
    }

    return newValue;
  }
}

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final bool required;
  final bool enabled;
  final DigitOnly? digitOnly;
  final int? maxLength;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool thousandsSeparator;
  final double? maxValue;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final bool noLeadingZero;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.required = false,
    this.enabled = true,
    this.digitOnly,
    this.maxLength,
    this.fontSize,
    this.fontWeight,
    this.thousandsSeparator = false,
    this.maxValue,
    this.inputFormatters,
    this.errorText,
    this.noLeadingZero = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  late final AnimationController _animController;
  late final Animation<double> _borderAnim;
  late final VoidCallback _focusListener;
  bool _isFocused = false;
  String? _errorText;

  static const _borderRadius = 10.0;

  String? get _effectiveError => widget.errorText ?? _errorText;

  Color get _borderColor {
    if (_effectiveError != null) {
      return AppColors.destructive.withOpacity(0.35);
    }
    if (!widget.enabled) {
      return AppColors.border.withOpacity(0.55);
    }
    if (_isFocused) {
      return AppColors.primary.withOpacity(0.45);
    }
    return const Color(0xFFD5DEE9);
  }

  Color get _labelColor {
    if (!widget.enabled) return AppColors.mutedForeground.withOpacity(0.75);
    if (_isFocused) return AppColors.primaryDark.withOpacity(0.9);
    return AppColors.foreground.withOpacity(0.72);
  }

  Color get _iconColor {
    if (!widget.enabled) return AppColors.border;
    if (_isFocused) return AppColors.primary.withOpacity(0.78);
    return AppColors.mutedForeground.withOpacity(0.85);
  }

  List<TextInputFormatter> get _inputFormatters {
    final custom = widget.inputFormatters ?? [];
    if (widget.thousandsSeparator) {
      return [
        ...custom,
        _ThousandsSeparatorFormatter(maxValue: widget.maxValue),
      ];
    }
    switch (widget.digitOnly) {
      case DigitOnly.integer:
        return [
          ...custom,
          _NumericRangeFormatter(
            allowDecimal: false,
            maxValue: widget.maxValue,
            noLeadingZero: widget.noLeadingZero,
          ),
        ];
      case DigitOnly.decimal:
        return [
          ...custom,
          _NumericRangeFormatter(
            allowDecimal: true,
            maxValue: widget.maxValue,
            noLeadingZero: widget.noLeadingZero,
          ),
        ];
      case null:
        return custom;
    }
  }

  TextInputType get _keyboardType {
    switch (widget.digitOnly) {
      case DigitOnly.integer:
        return TextInputType.number;
      case DigitOnly.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case null:
        return widget.keyboardType;
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _borderAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _focusListener = () {
      if (!mounted) return;
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    };
    _focusNode.addListener(_focusListener);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  Color get _fillColor {
    if (!widget.enabled) return const Color(0xFFF8FAFC);
    if (_isFocused) return const Color(0xFFFFFFFF);
    return AppColors.card;
  }

  String? _validate(String? value) {
    final error = widget.validator?.call(value);
    if (error != _errorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && error != _errorText) {
          setState(() => _errorText = error);
        }
      });
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: _labelColor,
                  fontFamily: 'NotoSansLao',
                ),
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destructive,
                    fontFamily: 'NotoSansLao',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        AnimatedBuilder(
          animation: _borderAnim,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _fillColor,
                borderRadius: BorderRadius.circular(_borderRadius),
                border: Border.all(
                  color: _borderColor,
                  width: _isFocused ? 1.8 : 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.10),
                          blurRadius: 0,
                          spreadRadius: 2.2,
                        ),
                      ]
                    : [],
              ),
              child: child,
            );
          },
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: _keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: _inputFormatters,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            validator: _validate,
            onFieldSubmitted: widget.onFieldSubmitted,
            onChanged: (v) {
              widget.onChanged?.call(v);
              final err = widget.validator?.call(v);
              if (err != _errorText && mounted) {
                setState(() => _errorText = err);
              }
            },
            maxLength: widget.maxLength,
            style: TextStyle(
              fontSize: widget.fontSize ?? 14,
              fontWeight: widget.fontWeight ?? FontWeight.w500,
              color: widget.enabled
                  ? AppColors.foreground
                  : AppColors.mutedForeground,
              letterSpacing: 0.1,
              fontFamily: 'NotoSansLao',
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.mutedForeground.withOpacity(0.62),
                fontFamily: 'NotoSansLao',
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 13, right: 8),
                      child: IconTheme(
                        data: IconThemeData(size: 17, color: _iconColor),
                        child: widget.prefixIcon!,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 0,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 13),
                      child: IconTheme(
                        data: IconThemeData(size: 17, color: _iconColor),
                        child: widget.suffixIcon!,
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 0,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              errorStyle: const TextStyle(fontSize: 0, height: 0),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: widget.maxLines != null && widget.maxLines! > 1
                    ? 14
                    : 13,
              ),
              isDense: true,
              counterText: '',
            ),
          ),
        ),

        if (_effectiveError != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 12,
                color: AppColors.destructive.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _effectiveError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.destructive.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoSansLao',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/widgets/modern_date_picker.dart';

class AppDateField extends StatefulWidget {
  final String? label;
  final TextEditingController controller;
  final bool required;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(String)? onChanged;
  final String? errorText;

  const AppDateField({
    super.key,
    this.label,
    required this.controller,
    this.required = false,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.errorText,
  });

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _animController;
  late final TextEditingController _displayController;
  bool _isFocused = false;
  bool _iconHovered = false;
  String _lastValidIso = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _displayController = TextEditingController(
      text: _toDisplay(widget.controller.text),
    );
    _lastValidIso = _isValidCommittedDate(widget.controller.text)
        ? widget.controller.text
        : '';

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
        _commitDisplay(_displayController.text);
      }
    });

    widget.controller.addListener(_syncFromExternal);
  }

  void _syncFromExternal() {
    final display = _toDisplay(widget.controller.text);
    if (_displayController.text != display) {
      _displayController.text = display;
    }
    if (_isValidCommittedDate(widget.controller.text)) {
      _lastValidIso = widget.controller.text;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    _displayController.dispose();
    widget.controller.removeListener(_syncFromExternal);
    super.dispose();
  }

  String _toDisplay(String iso) {
    if (iso.isEmpty) return '';
    final parts = iso.split('-');
    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return iso;
  }

  String _toIso(String display) {
    if (display.isEmpty) return '';
    final parts = display.split('-');
    if (parts.length == 3 && parts[2].length == 4) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return display;
  }

  DateTime? _parseIsoDate(String iso) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(iso)) {
      return null;
    }

    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return null;
    }

    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    return normalized == iso ? parsed : null;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isInRange(DateTime date) {
    final dateOnly = _dateOnly(date);
    final firstDate = widget.firstDate == null
        ? null
        : _dateOnly(widget.firstDate!);
    final lastDate = widget.lastDate == null
        ? null
        : _dateOnly(widget.lastDate!);

    if (firstDate != null && dateOnly.isBefore(firstDate)) {
      return false;
    }
    if (lastDate != null && dateOnly.isAfter(lastDate)) {
      return false;
    }
    return true;
  }

  bool _isValidCommittedDate(String iso) {
    final parsed = _parseIsoDate(iso);
    return parsed != null && _isInRange(parsed);
  }

  void _commitDisplay(String display) {
    final iso = _toIso(display);
    final parsed = _parseIsoDate(iso);

    if (display.isEmpty) {
      if (widget.controller.text.isNotEmpty) {
        widget.controller.text = '';
      }
      _lastValidIso = '';
      widget.onChanged?.call('');
      return;
    }

    if (parsed != null && !_isInRange(parsed)) {
      final lastValidDisplay = _toDisplay(_lastValidIso);
      if (_displayController.text != lastValidDisplay) {
        _displayController.value = TextEditingValue(
          text: lastValidDisplay,
          selection: TextSelection.collapsed(offset: lastValidDisplay.length),
        );
      }
      if (widget.controller.text != _lastValidIso) {
        widget.controller.text = _lastValidIso;
        widget.onChanged?.call(_lastValidIso);
      }
      return;
    }

    if (widget.controller.text != iso) {
      widget.controller.text = iso;
      widget.onChanged?.call(iso);
    } else if (display == _displayController.text) {
      widget.onChanged?.call(iso);
    }

    if (parsed != null) {
      _lastValidIso = iso;
    }
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    if (widget.controller.text.isNotEmpty) {
      try {
        final parts = widget.controller.text.split('-');
        if (parts.length == 3) {
          initial = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (_) {}
    }

    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => ModernDatePicker(
        initialDate: initial,
        firstDate: widget.firstDate ?? DateTime(2000),
        lastDate: widget.lastDate ?? DateTime(2100),
      ),
    );

    if (picked != null) {
      final iso =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      widget.controller.text = iso;
      _displayController.text = _toDisplay(iso);
      _lastValidIso = iso;
      widget.onChanged?.call(iso);
      setState(() {});
    }
  }

  Color get _fillColor {
    if (!widget.enabled) return Colors.white;
    if (_isFocused) return AppColors.primary.withValues(alpha: 0.04);
    return Colors.white;
  }

  Color get _borderColor {
    if (widget.errorText != null) {
      return AppColors.destructive.withValues(alpha: 0.35);
    }
    if (_isFocused) {
      return AppColors.primary.withValues(alpha: 0.7);
    }
    return AppColors.border;
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: _isFocused
                      ? AppColors.primary
                      : widget.enabled
                      ? AppColors.foreground.withValues(alpha: 0.85)
                      : AppColors.mutedForeground,
                ),
              ),
              if (widget.required)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destructive,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _borderColor,
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _displayController,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                    LengthLimitingTextInputFormatter(10),
                    DateInputFormatter(),
                  ],
                  onChanged: _commitDisplay,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: widget.enabled
                        ? AppColors.foreground
                        : AppColors.mutedForeground,
                    letterSpacing: 0.1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'DD-MM-YYYY',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.accentForeground,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (widget.enabled)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _iconHovered = true),
                  onExit: (_) => setState(() => _iconHovered = false),
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _iconHovered
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 17,
                        color: _iconHovered
                            ? AppColors.primary
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 17,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 12,
                color: AppColors.destructive.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.destructive.withValues(alpha: 0.9),
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

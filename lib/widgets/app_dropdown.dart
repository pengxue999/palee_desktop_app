import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

class AppDropdown<T> extends StatefulWidget {
  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? hint;
  final bool required;
  final bool enabled;
  final String? errorText;

  const AppDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.required = false,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _isOpen = false;

  static const _borderRadius = 10.0;

  Color get _borderColor {
    if (widget.errorText != null) {
      return AppColors.destructive.withOpacity(0.35);
    }
    if (!widget.enabled) return AppColors.border.withOpacity(0.55);
    return _isOpen
        ? AppColors.primary.withOpacity(0.45)
        : const Color(0xFFD5DEE9);
  }

  Color get _fillColor {
    if (!widget.enabled) return const Color(0xFFF8FAFC);
    return _isOpen ? const Color(0xFFFFFFFF) : AppColors.card;
  }

  Color get _labelColor {
    if (!widget.enabled) return AppColors.mutedForeground.withOpacity(0.75);
    if (_isOpen) return AppColors.primaryDark.withOpacity(0.9);
    return AppColors.foreground.withOpacity(0.72);
  }

  Color get _iconColor {
    if (!widget.enabled) return AppColors.border;
    if (_isOpen) return AppColors.primary.withOpacity(0.78);
    return AppColors.mutedForeground.withOpacity(0.85);
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

        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(color: _borderColor, width: _isOpen ? 1.8 : 1),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.10),
                      blurRadius: 0,
                      spreadRadius: 1.2,
                    ),
                  ]
                : [],
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<T>(
                value: widget.value,
                hint: widget.hint != null
                    ? Text(
                        widget.hint!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mutedForeground.withOpacity(0.62),
                          fontFamily: 'NotoSansLao',
                        ),
                      )
                    : null,
                isExpanded: true,
                icon: AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _iconColor,
                    size: 20,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: BorderRadius.circular(_borderRadius),
                dropdownColor: AppColors.card,
                menuMaxHeight: 280,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: widget.enabled
                      ? AppColors.foreground
                      : AppColors.mutedForeground,
                  fontFamily: 'NotoSansLao',
                ),
                selectedItemBuilder: widget.items.isEmpty
                    ? null
                    : (context) => widget.items
                          .map(
                            (item) => DropdownMenuItem<T>(
                              value: item.value,
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                  color: widget.enabled
                                      ? AppColors.foreground
                                      : AppColors.mutedForeground,
                                  fontFamily: 'NotoSansLao',
                                ),
                                child: item.child,
                              ),
                            ),
                          )
                          .toList(),
                items: widget.items.map((item) {
                  final isSelected = item.value == widget.value;
                  return DropdownMenuItem<T>(
                    value: item.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.foreground,
                                fontFamily: 'NotoSansLao',
                              ),
                              child: item.child,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: widget.enabled
                    ? (value) {
                        setState(() => _isOpen = false);
                        widget.onChanged?.call(value);
                      }
                    : null,
                onTap: () => setState(() => _isOpen = !_isOpen),
                elevation: 3,
              ),
            ),
          ),
        ),

        if (widget.errorText != null) ...[
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
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: 14,
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

import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

class AppSearchableItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String searchText;

  AppSearchableItem({
    required this.value,
    required this.label,
    this.subtitle,
    String? searchText,
  }) : searchText = (searchText ?? '$label ${subtitle ?? ''}').toLowerCase();
}

class AppSearchableDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? searchHint;
  final String emptyText;
  final T? value;
  final List<AppSearchableItem<T>> items;
  final void Function(T?)? onChanged;
  final bool required;
  final bool enabled;
  final String? errorText;

  const AppSearchableDropdown({
    super.key,
    this.label,
    this.hint,
    this.searchHint,
    this.emptyText = 'ບໍ່ພົບຂໍ້ມູນ',
    required this.value,
    required this.items,
    this.onChanged,
    this.required = false,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<AppSearchableDropdown<T>> createState() =>
      _AppSearchableDropdownState<T>();
}

class _AppSearchableDropdownState<T> extends State<AppSearchableDropdown<T>> {
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  OverlayEntry? _overlay;
  String _query = '';

  static const _borderRadius = 10.0;

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isOpen => _overlay != null;

  AppSearchableItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  List<AppSearchableItem<T>> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final query = _query.toLowerCase();
    return widget.items
        .where((item) => item.searchText.contains(query))
        .toList();
  }

  Color get _borderColor {
    if (widget.errorText != null) {
      return AppColors.destructive.withOpacity(0.35);
    }
    if (!widget.enabled) return AppColors.border.withOpacity(0.55);
    return _isOpen
        ? AppColors.primary.withOpacity(0.45)
        : const Color(0xFFD5DEE9);
  }

  Color get _labelColor {
    if (!widget.enabled) return AppColors.mutedForeground.withOpacity(0.75);
    if (_isOpen) return AppColors.primaryDark.withOpacity(0.9);
    return AppColors.foreground.withOpacity(0.72);
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _query = '';
    _searchController.clear();
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  void _select(AppSearchableItem<T> item) {
    _removeOverlay();
    widget.onChanged?.call(item.value);
  }

  Widget _buildOverlay(BuildContext context) {
    final box = this.context.findRenderObject() as RenderBox;
    final width = box.size.width;
    final items = _filteredItems;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
          ),
        ),
        Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(0, 6),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(_borderRadius),
              color: AppColors.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        _query = value;
                        _overlay?.markNeedsBuild();
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foreground,
                        fontFamily: 'NotoSansLao',
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.searchHint ?? 'ຄົ້ນຫາ...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground.withOpacity(0.62),
                          fontFamily: 'NotoSansLao',
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD5DEE9),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD5DEE9),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        widget.emptyText,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                          fontFamily: 'NotoSansLao',
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 6),
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = item.value == widget.value;
                          return InkWell(
                            onTap: () => _select(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.06)
                                  : null,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.label,
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
                                        ),
                                        if (item.subtitle != null &&
                                            item.subtitle!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.mutedForeground,
                                              fontFamily: 'NotoSansLao',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;

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

        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            borderRadius: BorderRadius.circular(_borderRadius),
            onTap: widget.enabled ? _toggleOverlay : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? (_isOpen ? const Color(0xFFFFFFFF) : AppColors.card)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(_borderRadius),
                border: Border.all(
                  color: _borderColor,
                  width: _isOpen ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: selected == null
                        ? Text(
                            widget.hint ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground.withOpacity(
                                0.62,
                              ),
                              fontFamily: 'NotoSansLao',
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selected.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                  color: widget.enabled
                                      ? AppColors.foreground
                                      : AppColors.mutedForeground,
                                  fontFamily: 'NotoSansLao',
                                ),
                              ),
                              if (selected.subtitle != null &&
                                  selected.subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  selected.subtitle!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                    fontFamily: 'NotoSansLao',
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: widget.enabled
                          ? (_isOpen
                                ? AppColors.primary.withOpacity(0.78)
                                : AppColors.mutedForeground.withOpacity(0.85))
                          : AppColors.border,
                    ),
                  ),
                ],
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

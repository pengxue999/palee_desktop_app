import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'loading_widget.dart';
import 'empty_widget.dart';

class AppDataTable<T extends Object> extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final Widget? headerTrailing;
  final List<T> data;
  final List<DataColumnDef<T>> columns;
  final VoidCallback? onAdd;
  final void Function(T)? onEdit;
  final void Function(T)? onDelete;
  final void Function(T)? onView;
  final void Function(T)? onPrint;
  final bool Function(T)? canDelete;
  final List<String> searchKeys;
  final String addLabel;
  final bool showActions;
  final bool isLoading;
  final double rowHeight;
  final bool Function(T)? isRowMuted;

  const AppDataTable({
    super.key,
    this.title,
    this.subtitle,
    this.headerTrailing,
    required this.data,
    required this.columns,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.onPrint,
    this.canDelete,
    this.searchKeys = const [],
    this.addLabel = "ເພີ່ມໃໝ່",
    this.showActions = true,
    this.isLoading = false,
    this.rowHeight = 48,
    this.isRowMuted,
  });

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T extends Object> extends State<AppDataTable<T>> {
  static const double _rowDividerThickness = 1;

  String searchQuery = '';
  int currentPage = 1;
  int _calculatedPageSize = 10;
  double? _lastMeasuredBodyHeight;
  double? _measuredRowExtent;
  final _hoveredRow = ValueNotifier<int?>(null);
  final _searchController = TextEditingController();
  final GlobalKey _firstRowKey = GlobalKey();

  double get _estimatedRowExtent =>
      (_measuredRowExtent ?? widget.rowHeight) + _rowDividerThickness;

  @override
  void didUpdateWidget(covariant AppDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onEdit != widget.onEdit ||
        oldWidget.onDelete != widget.onDelete ||
        oldWidget.onView != widget.onView ||
        oldWidget.onPrint != widget.onPrint ||
        oldWidget.showActions != widget.showActions) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _hoveredRow.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<T> get filteredData {
    if (searchQuery.isEmpty || widget.searchKeys.isEmpty) return widget.data;
    final q = searchQuery.toLowerCase();
    return widget.data.where((row) {
      return widget.searchKeys.any((key) {
        final value = _getValue(row, key);
        return value != null && value.toString().toLowerCase().contains(q);
      });
    }).toList();
  }

  int get pageSize => _calculatedPageSize;

  List<T> get pagedData {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredData.length);
    if (startIndex >= filteredData.length) return [];
    return filteredData.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredData.length / pageSize).ceil().clamp(1, 999);

  void _updatePageSizeForAvailableHeight(double availableHeight) {
    final calculatedSize = (availableHeight / _estimatedRowExtent)
        .floor()
        .clamp(1, 50);

    if (calculatedSize != _calculatedPageSize) {
      final newMaxPage = (filteredData.length / calculatedSize).ceil().clamp(
        1,
        999,
      );
      if (currentPage > newMaxPage) {
        currentPage = newMaxPage;
      }

      setState(() {
        _calculatedPageSize = calculatedSize;
      });
    }
  }

  void _measureRenderedRowHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final context = _firstRowKey.currentContext;
      if (context == null) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      final measuredHeight = renderBox?.size.height;
      if (measuredHeight == null || measuredHeight <= 0) return;

      if (_measuredRowExtent != measuredHeight) {
        setState(() {
          _measuredRowExtent = measuredHeight;
        });

        if (_lastMeasuredBodyHeight != null) {
          _updatePageSizeForAvailableHeight(_lastMeasuredBodyHeight!);
        }
      }
    });
  }

  dynamic _getValue(T row, String key) {
    try {
      final value = (row as dynamic)[key];
      return value ?? '-';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = _hasHeaderContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[_buildHeader(), const SizedBox(height: 16)],
        Expanded(child: _buildTable()),
      ],
    );
  }

  bool get _hasHeaderContent {
    return widget.searchKeys.isNotEmpty ||
        widget.onAdd != null ||
        widget.headerTrailing != null ||
        (widget.title?.isNotEmpty ?? false) ||
        widget.subtitle != null;
  }

  Widget _buildHeader() {
    final hasSearch = widget.searchKeys.isNotEmpty;
    final hasTitle =
        (widget.title?.isNotEmpty ?? false) || widget.subtitle != null;
    final titleSection = hasTitle ? _buildTitleSection() : null;

    return ResponsiveBuilder(
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleSection != null) ...[
            titleSection,
            const SizedBox(height: 12),
          ],
          if (hasSearch)
            AppTextField(
              hint: 'ຄົ້ນຫາ...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.mutedForeground,
                      ),
                      onPressed: () => setState(() {
                        searchQuery = '';
                        _searchController.clear();
                        currentPage = 1;
                      }),
                    )
                  : null,
              onChanged: (v) => setState(() {
                searchQuery = v;
                currentPage = 1;
              }),
            ),
          if (hasSearch && widget.headerTrailing != null)
            const SizedBox(height: 12),
          if (widget.headerTrailing != null) widget.headerTrailing!,
          if (hasSearch && widget.onAdd != null) const SizedBox(height: 12),
          if (widget.onAdd != null)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: widget.addLabel,
                icon: Icons.add_rounded,
                onPressed: widget.onAdd,
              ),
            ),
        ],
      ),
      tablet: Row(
        children: [
          if (titleSection != null) ...[
            Expanded(child: titleSection),
            const SizedBox(width: 16),
          ],
          if (hasSearch) _buildSearchField(maxWidth: 400, expanded: true),
          if (hasSearch && widget.headerTrailing != null)
            const SizedBox(width: 12),
          if (widget.headerTrailing != null) widget.headerTrailing!,
          if (hasSearch && widget.onAdd != null) const SizedBox(width: 12),
          if (widget.onAdd != null)
            AppButton(
              label: widget.addLabel,
              icon: Icons.add_rounded,
              onPressed: widget.onAdd,
            ),
        ],
      ),
      desktop: Row(
        children: [
          if (titleSection != null) ...[
            Expanded(child: titleSection),
            const SizedBox(width: 16),
          ],
          if (hasSearch) _buildSearchField(maxWidth: 400),
          if (hasSearch && widget.headerTrailing != null)
            const SizedBox(width: 12),
          if (widget.headerTrailing != null) widget.headerTrailing!,
          if (hasSearch && widget.onAdd != null) const SizedBox(width: 12),
          if (widget.onAdd != null)
            AppButton(
              label: widget.addLabel,
              icon: Icons.add_rounded,
              onPressed: widget.onAdd,
            ),
          if (!hasTitle) const Spacer(),
        ],
      ),
      wideDesktop: Row(
        children: [
          if (titleSection != null) ...[
            Expanded(child: titleSection),
            const SizedBox(width: 16),
          ],
          if (hasSearch) _buildSearchField(maxWidth: 400),
          if (hasSearch && widget.headerTrailing != null)
            const SizedBox(width: 12),
          if (widget.headerTrailing != null) widget.headerTrailing!,
          if (hasSearch && widget.onAdd != null) const SizedBox(width: 12),
          if (widget.onAdd != null)
            AppButton(
              label: widget.addLabel,
              icon: Icons.add_rounded,
              onPressed: widget.onAdd,
            ),
          if (!hasTitle) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title?.isNotEmpty ?? false)
          Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
        if (widget.subtitle != null) ...[
          if (widget.title?.isNotEmpty ?? false) const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchField({double? maxWidth, bool expanded = false}) {
    final field = AppTextField(
      hint: 'ຄົ້ນຫາ...',
      controller: _searchController,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: searchQuery.isNotEmpty
          ? IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.mutedForeground,
              ),
              onPressed: () => setState(() {
                searchQuery = '';
                _searchController.clear();
                currentPage = 1;
              }),
            )
          : null,
      onChanged: (v) => setState(() {
        searchQuery = v;
        currentPage = 1;
      }),
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: expanded ? Expanded(child: field) : field,
      );
    }
    return field;
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: Skeletonizer(
              enabled: widget.isLoading,
              child: _buildTableBody(),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            child: Text(
              'ລຳດັບ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedForeground,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 50),
          ...widget.columns.map(
            (col) => Expanded(
              flex: col.flex,
              child: Text(
                col.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedForeground,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          if (widget.showActions && _hasActions)
            const SizedBox(
              width: 120,
              child: Text(
                'ຈັດການ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedForeground,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    if (widget.isLoading) {
      return const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...');
    }

    final data = pagedData;
    if (data.isEmpty) {
      return EmptyWidget(
        title: searchQuery.isNotEmpty ? 'ບໍ່ພົບຂໍ້ມູນ' : 'ບໍ່ມີຂໍ້ມູນ',
        subtitle: searchQuery.isNotEmpty
            ? 'ລອງປ່ຽນຄຳຄົ້ນຫາ ຫຼື ລ້າງຟິວເຕີ'
            : 'ຍັງບໍ່ມີຂໍ້ມູນ ກົດ "ເພີ່ມໃໝ່" ເພື່ອເລີ່ມຕົ້ນ',
        icon: searchQuery.isNotEmpty
            ? Icons.search_off_rounded
            : Icons.inbox_rounded,
        onAction: searchQuery.isNotEmpty ? null : widget.onAdd,
        actionLabel: searchQuery.isNotEmpty ? null : widget.addLabel,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final measuredHeight = constraints.maxHeight;
        if (_lastMeasuredBodyHeight != measuredHeight) {
          _lastMeasuredBodyHeight = measuredHeight;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updatePageSizeForAvailableHeight(measuredHeight);
            }
          });
        }

        return _buildTableBodyContent(data);
      },
    );
  }

  Widget _buildTableBodyContent(List<T> data) {
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final row = data[index];
        if (index == 0) {
          _measureRenderedRowHeight();
        }
        final isMuted = widget.isRowMuted?.call(row) ?? false;
        return ValueListenableBuilder<int?>(
          valueListenable: _hoveredRow,
          builder: (context, hoveredIndex, _) {
            final isHovered = hoveredIndex == index;
            return MouseRegion(
              onEnter: (_) => _hoveredRow.value = index,
              onExit: (_) => _hoveredRow.value = null,
              child: AnimatedContainer(
                key: index == 0 ? _firstRowKey : null,
                duration: const Duration(milliseconds: 150),
                constraints: BoxConstraints(minHeight: widget.rowHeight),
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : index % 2 == 0
                      ? Colors.transparent
                      : AppColors.muted.withValues(alpha: 0.3),
                  border: isHovered
                      ? Border(
                          left: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            width: 3,
                          ),
                        )
                      : const Border(
                          left: BorderSide(color: Colors.transparent, width: 3),
                        ),
                ),
                child: Opacity(
                  opacity: isMuted ? 0.5 : 1.0,
                  child: InkWell(
                    onTap: widget.onView != null
                        ? () => widget.onView!(row)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.muted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${(currentPage - 1) * pageSize + index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isHovered
                                      ? AppColors.primary
                                      : AppColors.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 50),
                          ...widget.columns.map((col) {
                            final value = _getValue(row, col.key);
                            return Expanded(
                              flex: col.flex,
                              child: col.render != null
                                  ? col.render!(value, row)
                                  : Text(
                                      value?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.foreground,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            );
                          }),
                          if (widget.showActions && _hasActions)
                            SizedBox(
                              width: 120,
                              child: _buildActionButtons(row, isHovered),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool get _hasActions {
    return widget.onEdit != null ||
        widget.onDelete != null ||
        widget.onView != null ||
        widget.onPrint != null;
  }

  Widget _buildActionButtons(T row, bool rowHovered) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: rowHovered ? 1.0 : 0.6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.onView != null)
            _ActionChip(
              icon: Icons.visibility_rounded,
              color: AppColors.primary,
              tooltip: 'ເບິ່ງ',
              onTap: () => widget.onView!(row),
            ),
          if (widget.onPrint != null) ...[
            if (widget.onView != null) const SizedBox(width: 4),
            _ActionChip(
              icon: Icons.print_rounded,
              color: AppColors.success,
              tooltip: 'ພິມ',
              onTap: () => widget.onPrint!(row),
            ),
          ],
          if (widget.onEdit != null) ...[
            if (widget.onView != null || widget.onPrint != null)
              const SizedBox(width: 4),
            _ActionChip(
              icon: Icons.edit_square,
              color: AppColors.primary,
              tooltip: 'ແກ້ໄຂ',
              onTap: () => widget.onEdit!(row),
            ),
          ],
          if (widget.onDelete != null &&
              (widget.canDelete == null || widget.canDelete!(row))) ...[
            const SizedBox(width: 4),
            _ActionChip(
              icon: Icons.delete_outline_rounded,
              color: AppColors.destructive,
              tooltip: 'ລຶບ',
              onTap: () => widget.onDelete!(row),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final filtered = filteredData;
    final start = filtered.isEmpty
        ? 0
        : ((currentPage - 1) * pageSize + 1).clamp(1, filtered.length);
    final end = (currentPage * pageSize).clamp(0, filtered.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'ສະແດງ $start–$end ຈາກ ${filtered.length} ລາຍການ',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PageButton(
                    icon: Icons.chevron_left_rounded,
                    enabled: currentPage > 1,
                    onTap: () => setState(() => currentPage--),
                  ),
                  const SizedBox(width: 4),
                  ..._buildPageNumbers(),
                  const SizedBox(width: 4),
                  _PageButton(
                    icon: Icons.chevron_right_rounded,
                    enabled: currentPage < totalPages,
                    onTap: () => setState(() => currentPage++),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    for (final p in _pageRange()) {
      pages.add(
        _PageNumber(
          number: p,
          isActive: p == currentPage,
          onTap: () => setState(() => currentPage = p),
        ),
      );
      pages.add(const SizedBox(width: 4));
    }
    return pages;
  }

  List<int> _pageRange() {
    if (totalPages <= 5) return List.generate(totalPages, (i) => i + 1);
    final start = (currentPage - 2).clamp(1, totalPages - 4);
    return List.generate(5, (i) => start + i);
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hovered = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: hovered,
      builder: (context, isHovered, _) => Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'NotoSansLao',
        ),
        child: MouseRegion(
          onEnter: (_) => hovered.value = true,
          onExit: (_) => hovered.value = false,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isHovered
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isHovered
                      ? color.withValues(alpha: 0.5)
                      : color.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: 15, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.foreground : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  final int number;
  final bool isActive;
  final VoidCallback onTap;

  const _PageNumber({
    required this.number,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hovered = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: hovered,
      builder: (context, isHovered, _) => MouseRegion(
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : isHovered
                  ? AppColors.muted
                  : AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DataColumnDef<T> {
  final String key;
  final String label;
  final int flex;
  final Widget Function(dynamic value, T row)? render;

  const DataColumnDef({
    required this.key,
    required this.label,
    this.flex = 1,
    this.render,
  });
}

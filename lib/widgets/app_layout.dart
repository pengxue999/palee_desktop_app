import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/enum_localization.dart';
import '../core/utils/responsive_utils.dart';
import '../providers/auth_provider.dart';
import 'sidebar.dart';

class AppLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final List<String> searchKeys;
  final Function(String)? onSearch;
  final bool showSidebar;
  final Function(String)? onTitleChange;

  const AppLayout({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.searchKeys = const [],
    this.onSearch,
    this.showSidebar = true,
    this.onTitleChange,
  });

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
  }

  void _updateTitle(String newTitle) {
    setState(() {
      _currentTitle = newTitle;
    });
    if (widget.onTitleChange != null) {
      widget.onTitleChange!(newTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final shouldShowSidebar = widget.showSidebar && !isMobile;

    return Scaffold(
      body: Row(
        children: [
          if (shouldShowSidebar) Sidebar(onTitleChange: _updateTitle),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, isMobile),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isMobile
          ? Drawer(child: Sidebar(onTitleChange: _updateTitle))
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final auth = ref.watch(authProvider);
    final userName = auth.userName ?? 'ຜູ້ໃຊ້';
    final role = auth.role ?? '';
    final roleLabel = _roleLabel(role);
    final initials = userName.isNotEmpty
        ? userName.substring(0, userName.length >= 2 ? 2 : 1).toUpperCase()
        : 'U';
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.mutedForeground,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          if (_currentTitle != null) ...[
            if (isMobile) const SizedBox(width: 8),
            Text(
              _currentTitle ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.update,
                color: AppColors.accentForeground,
                size: 18,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 32, color: AppColors.border),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    return localizeUserRole(role);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import '../core/utils/enum_localization.dart';
import '../providers/auth_provider.dart';
import '../core/utils/responsive_utils.dart';

final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

class Sidebar extends ConsumerStatefulWidget {
  final Function(String)? onTitleChange;

  const Sidebar({super.key, this.onTitleChange});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  final Set<String> _expandedItems = {};

  static const _sidebarBg = Color(0xFF2563EB);
  static const _sidebarHeader = Color(0xFF1D4ED8);
  static const _sidebarBottom = Color(0xFF1D4ED8);
  static const _dividerColor = Color(0x33FFFFFF);
  static const _iconMuted = Color(0xBFFFFFFF);
  static const _textMuted = Color(0xA6FFFFFF);

  static const double _collapsedWidth = 64.0;

  final List<MenuItemModel> menuItems = [
    MenuItemModel(
      id: 'dashboard',
      label: 'ໜ້າຫຼັກ',
      icon: Icons.home_rounded,
      path: '/',
    ),
    MenuItemModel(
      id: 'basic',
      label: 'ຈັດການຂໍ້ມູນພື້ນຖານ',
      icon: Icons.layers_rounded,
      tableName: 'basic_data',
      children: [
        MenuItemModel(
          id: '_g1_students',
          label: 'ຂໍ້ມູນນັກຮຽນ',
          icon: Icons.school_rounded,
          path: '/students',
          tableName: 'student',
        ),
        MenuItemModel(
          id: '_g1_teachers',
          label: 'ຂໍ້ມູນອາຈານ',
          icon: Icons.people_rounded,
          path: '/teachers',
          tableName: 'teacher',
        ),
        MenuItemModel(
          id: '_g1_teaching',
          label: 'ຂໍ້ມູນການສອນຂອງອາຈານ',
          icon: Icons.menu_book_rounded,
          path: '/teaching-info',
          tableName: 'teacher_assignment',
        ),
        MenuItemModel(
          id: '_g1_donors',
          label: 'ຂໍ້ມູນຜູ້ບໍລິຈາກ',
          icon: Icons.favorite_rounded,
          path: '/donors',
          tableName: 'donor',
        ),
        MenuItemModel(
          id: '_g1_users',
          label: 'ຂໍ້ມູນຜູ້ໃຊ້',
          icon: Icons.admin_panel_settings_rounded,
          path: '/users',
          tableName: 'user',
        ),
        MenuItemModel(
          id: '_divider1',
          label: '__divider__',
          icon: Icons.remove,
          path: null,
        ),
        MenuItemModel(
          id: 'academic-years',
          label: 'ຂໍ້ມູນສົກຮຽນ',
          icon: Icons.calendar_today_rounded,
          path: '/academic-years',
          tableName: 'academic_years',
        ),
        MenuItemModel(
          id: 'subject-categories',
          label: 'ຂໍ້ມູນໝວດວິຊາ',
          icon: Icons.label_rounded,
          path: '/subject-categories',
          tableName: 'subject_category',
        ),
        MenuItemModel(
          id: 'subjects',
          label: 'ຂໍ້ມູນວິຊາ',
          icon: Icons.book_rounded,
          path: '/subjects',
          tableName: 'subject',
        ),
        MenuItemModel(
          id: 'levels',
          label: 'ຂໍ້ມູນຊັ້ນຮຽນ',
          icon: Icons.business_rounded,
          path: '/levels',
          tableName: 'level',
        ),

        MenuItemModel(
          id: 'subject-details',
          label: 'ຂໍ້ມູນລາຍລະອຽດວິຊາ',
          icon: Icons.description_rounded,
          path: '/subject-details',
          tableName: 'subject_detail',
        ),
        MenuItemModel(
          id: 'fees',
          label: 'ຂໍ້ມູນຄ່າຮຽນ',
          icon: Icons.attach_money_rounded,
          path: '/fees',
          tableName: 'fee',
        ),
        MenuItemModel(
          id: 'discounts',
          label: 'ຂໍ້ມູນສ່ວນຫຼຸດ',
          icon: Icons.percent_rounded,
          path: '/discounts',
          tableName: 'discount',
        ),
        MenuItemModel(
          id: '_divider2',
          label: '__divider__',
          icon: Icons.remove,
          path: null,
        ),
        MenuItemModel(
          id: 'expense-types',
          label: 'ຂໍ້ມູນປະເພດລາຍຈ່າຍ',
          icon: Icons.payments_rounded,
          path: '/expense-types',
          tableName: 'expense_category',
        ),
        MenuItemModel(
          id: 'donation-categories',
          label: 'ຂໍ້ມູນປະເພດການບໍລິຈາກ',
          icon: Icons.straighten_rounded,
          path: '/donation-categories',
          tableName: 'donation_category',
        ),
        MenuItemModel(
          id: '_divider2',
          label: '__divider__',
          icon: Icons.remove,
          path: null,
        ),
        MenuItemModel(
          id: 'provinces',
          label: 'ຂໍ້ມູນແຂວງ',
          icon: Icons.map_rounded,
          path: '/provinces',
          tableName: 'province',
        ),
        MenuItemModel(
          id: 'districts',
          label: 'ຂໍ້ມູນເມືອງ',
          icon: Icons.location_city_rounded,
          path: '/districts',
          tableName: 'district',
        ),
      ],
    ),
    MenuItemModel(
      id: 'registration',
      label: 'ລົງທະບຽນ',
      icon: Icons.app_registration_rounded,
      path: '/registration',
      tableName: 'registration',
      displayFields: [
        'registration_id',
        'student_id',
        'discount_id',
        'total_amount',
        'final_amount',
        'status',
        'registration_date',
      ],
      fieldLabels: {
        'registration_id': 'ລະຫັດການລົງທະບຽນ',
        'student_id': 'ນັກຮຽນ',
        'discount_id': 'ສ່ວນລຸດ',
        'total_amount': 'ຈຳນວນລວດ',
        'final_amount': 'ຈຳນວນສຸດ',
        'status': 'ສະຖານະ',
        'registration_date': 'ວັນທີເລີ່ລົງທະບຽນ',
      },
    ),
    MenuItemModel(
      id: 'payment',
      label: 'ຈ່າຍຄ່າຮຽນ',
      icon: Icons.payment_rounded,
      path: '/payment',
      tableName: 'tuition_payment',
      displayFields: [
        'tuition_payment_id',
        'registration_id',
        'paid_amount',
        'pay_date',
      ],
      fieldLabels: {
        'tuition_payment_id': 'ລະຫັດການຈ່າຍຄ່າຮຽນ',
        'registration_id': 'ການລົງທະບຽນ',
        'paid_amount': 'ຈຳນວນທີ່ຈ່າຍ',
        'pay_date': 'ວັນທີ່ຈ່າຍ',
      },
    ),
    MenuItemModel(
      id: 'teaching-track',
      label: 'ຕິດຕາມການສອນ',
      icon: Icons.visibility_rounded,
      path: '/teaching-tracking',
      tableName: 'teaching_log',
      displayFields: [
        'teaching_log_id',
        'assignment_id',
        'teaching_date',
        'remark',
      ],
      fieldLabels: {
        'teaching_log_id': 'ລະຫັດບັນທຶກການສອນ',
        'assignment_id': 'ການມອບໝາຍສອນ',
        'teaching_date': 'ວັນທີ່ສອນ',
        'remark': 'ຄຳເຫັນ',
      },
    ),
    MenuItemModel(
      id: 'salary',
      label: 'ເບີກຈ່າຍເງິນສອນ',
      icon: Icons.account_balance_wallet_rounded,
      path: '/salary',
      tableName: 'salary_payment',
      displayFields: [
        'salary_payment_id',
        'teacher_id',
        'user_id',
        'payment_date',
        'total_amount',
        'status',
      ],
      fieldLabels: {
        'salary_payment_id': 'ລະຫັດການຈ່າຍເງິນສອນ',
        'teacher_id': 'ອາຈານ',
        'user_id': 'ຜູ້ບັນທຶກ',
        'payment_date': 'ວັນທີ່ຈ່າຍ',
        'total_amount': 'ຈຳນວນລວດ',
        'status': 'ສະຖານະ',
      },
    ),
    MenuItemModel(
      id: 'evaluate-student',
      label: 'ປະເມີນຜົນການຮຽນ',
      icon: Icons.emoji_events_rounded,
      path: '/evaluate-student',
      tableName: 'evaluation',
      displayFields: [
        'evaluation_id',
        'academic_id',
        'semester',
        'evaluation_date',
      ],
      fieldLabels: {
        'evaluation_id': 'ລະຫັດການປະເມີນ',
        'academic_id': 'ສົກຮຽນ',
        'semester': 'ພາກສະໄວາ',
        'evaluation_date': 'ວັນທີ່ປະເມີນ',
      },
    ),
    MenuItemModel(
      id: 'finance',
      label: 'ຈັດການການເງິນ',
      icon: Icons.trending_up_rounded,
      path: '/finance',
      tableName: 'finance',
    ),
    MenuItemModel(
      id: 'donation',
      label: 'ຈັດການການບໍລິຈາກ',
      icon: Icons.volunteer_activism_rounded,
      path: '/donation',
      tableName: 'donation',
    ),
    MenuItemModel(
      id: 'reports',
      label: 'ລາຍງານ',
      icon: Icons.bar_chart_rounded,
      tableName: 'reports',
      children: [
        MenuItemModel(
          id: 'report-students',
          label: 'ລາຍງານຂໍ້ມູນນັກຮຽນ',
          icon: Icons.school_rounded,
          path: '/reports/students',
          tableName: 'student',
        ),
        MenuItemModel(
          id: 'report-assessment',
          label: 'ລາຍງານຜົນການຮຽນ',
          icon: Icons.emoji_events_rounded,
          path: '/reports?type=assessment',
          tableName: 'evaluation',
        ),
        MenuItemModel(
          id: 'report-registrations',
          label: 'ລາຍງານການລົງທະບຽນ',
          icon: Icons.how_to_reg_rounded,
          path: '/reports?type=registrations',
          tableName: 'registration',
        ),
        MenuItemModel(
          id: 'report-finance',
          label: 'ລາຍງານການເງິນ',
          icon: Icons.payments_rounded,
          path: '/reports?type=finance',
          tableName: 'finance',
        ),
        MenuItemModel(
          id: 'report-donation',
          label: 'ລາຍງານການບໍລິຈາກ',
          icon: Icons.favorite_rounded,
          path: '/reports?type=donation',
          tableName: 'donation',
        ),
        MenuItemModel(
          id: 'report-teaching',
          label: 'ລາຍງານການຂື້ນສອນຂອງອາຈານ',
          icon: Icons.book_rounded,
          path: '/reports?type=teaching',
          tableName: 'teaching_log',
        ),
        MenuItemModel(
          id: 'report-salary-payment',
          label: 'ລາຍງານເບີກຈ່າຍເງິນສອນ',
          icon: Icons.receipt_long_rounded,
          path: '/reports?type=salary-payment',
          tableName: 'salary_payment',
        ),

        // ປິດການນຳໃຊ້ຊົ່ວຄາວ (disabled, not removed)
        // MenuItemModel(
        //   id: 'report-popular',
        //   label: 'ລາຍງານສະຖິຕິວິຊານິຍົມ',
        //   icon: Icons.pie_chart_rounded,
        //   path: '/reports?type=popular-subjects',
        //   tableName: 'subject_detail',
        // ),
      ],
    ),
  ];

  static const Set<String> _teacherAllowedMenuIds = {
    'dashboard',
    'teaching-track',
    'evaluate-student',
  };

  List<MenuItemModel> _getFilteredMenuItems(String? role) {
    if (!isTeacherRole(role)) {
      return menuItems;
    }
    return menuItems
        .where((item) => _teacherAllowedMenuIds.contains(item.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final isMobile = context.isMobile;
    final sidebarWidth = isMobile ? 300.0 : context.sidebarWidth;
    final authState = ref.watch(authProvider);
    final filteredMenuItems = _getFilteredMenuItems(authState.role);

    if (isMobile) {
      return Container(
        width: sidebarWidth,
        color: _sidebarBg,
        child: _buildSidebarContent(true, filteredMenuItems),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      width: isExpanded ? sidebarWidth : _collapsedWidth,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: _sidebarBg,
        border: Border(right: BorderSide(color: _dividerColor, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showExpandedContent = isExpanded && constraints.maxWidth >= 220;
          return _buildSidebarContent(showExpandedContent, filteredMenuItems);
        },
      ),
    );
  }

  Widget _buildSidebarContent(bool isExpanded, List<MenuItemModel> items) {
    return Column(
      children: [
        _buildLogoSection(isExpanded),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Column(
              children: items
                  .map((item) => _buildMenuItem(item, isExpanded))
                  .toList(),
            ),
          ),
        ),
        _buildBottomSection(isExpanded),
      ],
    );
  }

  Widget _buildLogoSection(bool isExpanded) {
    final logoIcon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 12 : 0,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _sidebarHeader,
        border: Border(bottom: BorderSide(color: _dividerColor, width: 1)),
      ),
      child: isExpanded
          ? Row(
              children: [
                logoIcon,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ລະບົບບໍລິຫານຈັດການ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ສູນປາລີບຳລຸງນັກຮຽນເກັ່ງ',
                        style: TextStyle(color: _textMuted, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Center(child: logoIcon),
    );
  }

  Widget _buildBottomSection(bool isExpanded) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 12),
      decoration: BoxDecoration(
        color: _sidebarBottom,
        border: Border(top: BorderSide(color: _dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          _buildToggleButton(isExpanded),
          const SizedBox(height: 4),
          _buildLogoutButton(isExpanded),
        ],
      ),
    );
  }

  Widget _buildToggleButton(bool isExpanded) {
    final hovered = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: hovered,
      builder: (context, isHovered, _) => Tooltip(
        message: isExpanded ? 'ຫຍໍ້ເມນູ' : 'ຂະຫຍາຍເມນູ',
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () =>
                ref.read(sidebarExpandedProvider.notifier).state = !isExpanded,
            onHover: (value) => hovered.value = value,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isHovered
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isExpanded
                  ? Row(
                      children: [
                        Icon(
                          Icons.keyboard_double_arrow_left_rounded,
                          size: 20,
                          color: isHovered ? Colors.white : _iconMuted,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ຫຍໍ້ເມນູ',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              color: isHovered ? Colors.white : _textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        size: 20,
                        color: isHovered ? Colors.white : _iconMuted,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isExpanded) {
    final hovered = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: hovered,
      builder: (context, isHovered, _) => Tooltip(
        message: isExpanded ? '' : 'ອອກຈາກລະບົບ',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'ແຈ້ງເຕືອນ',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                content: const Text(
                  'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການອອກຈາກລະບົບ?',
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'ຍົກເລີກ',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await windowManager.close();
                    },
                    child: const Text('ຕົກລົງ'),
                  ),
                ],
              ),
            ),
            onHover: (value) => hovered.value = value,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isHovered
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isExpanded
                  ? Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: isHovered ? Colors.white : _iconMuted,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ອອກຈາກລະບົບ',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              color: isHovered ? Colors.white : _textMuted,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: isHovered ? Colors.white : _iconMuted,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(MenuItemModel item, bool isExpanded, {int depth = 0}) {
    if (item.label == '__divider__') {
      if (!isExpanded) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Container(height: 1, color: _dividerColor),
      );
    }

    final location = GoRouterState.of(context).uri.toString();
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final isItemExpanded = _expandedItems.contains(item.id);
    final isActive =
        location == item.path ||
        (hasChildren &&
            item.children!.any(
              (c) => c.path != null && location.startsWith(c.path!),
            ));

    final hovered = ValueNotifier<bool>(false);

    if (hasChildren) {
      return ValueListenableBuilder<bool>(
        valueListenable: hovered,
        builder: (context, isHovered, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  if (!isExpanded) {
                    ref.read(sidebarExpandedProvider.notifier).state = true;
                  }
                  setState(
                    () => isItemExpanded
                        ? _expandedItems.remove(item.id)
                        : _expandedItems.add(item.id),
                  );
                },
                onHover: (value) => hovered.value = value,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.fromLTRB(depth > 0 ? 12 : 8, 11, 8, 11),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : isHovered
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isExpanded
                      ? Row(
                          children: [
                            _buildIcon(
                              item.icon,
                              isActive,
                              isHovered,
                              size: depth > 0 ? 18 : 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: depth > 0 ? 14 : 15,
                                  color: isActive ? Colors.black : Colors.white,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            AnimatedRotation(
                              turns: isItemExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isActive ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: _buildIcon(
                            item.icon,
                            isActive,
                            isHovered,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ),
            if (isExpanded && isItemExpanded)
              Container(
                margin: const EdgeInsets.only(left: 16, bottom: 4),
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  children: item.children!
                      .map(
                        (c) => _buildMenuItem(c, isExpanded, depth: depth + 1),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: hovered,
      builder: (context, isHovered, _) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: item.path != null
              ? () {
                  context.go(item.path!);
                  if (context.isMobile) Navigator.of(context).pop();
                  widget.onTitleChange?.call(item.label);
                }
              : null,
          onHover: (value) => hovered.value = value,
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                clipBehavior: Clip.hardEdge,
                padding: EdgeInsets.fromLTRB(
                  depth > 0 ? 10 : 8,
                  depth > 0 ? 9 : 11,
                  8,
                  depth > 0 ? 9 : 11,
                ),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : isHovered
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive && isExpanded
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: isExpanded
                    ? Row(
                        children: [
                          _buildIcon(
                            item.icon,
                            isActive,
                            isHovered,
                            size: depth > 0 ? 18 : 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: depth > 0 ? 14 : 15,
                                color: isActive ? Colors.black : Colors.white,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isActive)
                            Container(
                              width: 3,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: _buildIcon(
                          item.icon,
                          isActive,
                          isHovered,
                          size: depth > 0 ? 18 : 20,
                        ),
                      ),
              ),
              if (!isExpanded && isActive)
                Positioned(
                  left: 0,
                  top: 2,
                  bottom: 2,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    dynamic icon,
    bool isActive,
    bool isHovered, {
    double size = 20,
  }) {
    return Icon(
      icon as IconData,
      size: size,
      color: isActive
          ? Colors.black
          : isHovered
          ? Colors.white
          : _iconMuted,
    );
  }
}

class MenuItemModel {
  final String id;
  final String label;
  final dynamic icon;
  final String? path;
  final List<MenuItemModel>? children;
  final String? tableName;
  final List<String>? displayFields;
  final Map<String, String>? fieldLabels;

  MenuItemModel({
    required this.id,
    required this.label,
    required this.icon,
    this.path,
    this.children,
    this.tableName,
    this.displayFields,
    this.fieldLabels,
  });
}

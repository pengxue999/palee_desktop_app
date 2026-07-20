import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/enum_localization.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_button.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  UserModel? selectedItem;
  bool isEditing = false;
  bool _showPassword = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String _selectedRole = 'DIRECTOR';

  static const List<Map<String, String>> _roles = [
    {'value': 'DIRECTOR', 'label': 'ຜູ້ອຳນວຍການ'},
    {'value': 'TEACHER', 'label': 'ອາຈານ'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(userProvider.notifier).getUsers();
      if (mounted) {
        final error = ref.read(userProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    _selectedRole = 'DIRECTOR';
    _showPassword = false;
    selectedItem = null;
    isEditing = false;
  }

  void _openAdd() {
    _resetForm();
    setState(() {
      showAddEditModal = true;
      isEditing = false;
    });
  }

  void _openEdit(UserModel item) {
    _usernameController.text = item.userName;
    _passwordController.clear();
    _selectedRole = apiUserRole(item.role);
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_usernameController.text.trim().isEmpty) return;
    if (!isEditing && _passwordController.text.trim().isEmpty) return;

    bool success;
    if (isEditing && selectedItem != null) {
      final request = UserUpdateRequest(
        userName: _usernameController.text.trim(),
        userPassword: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        role: _selectedRole,
      );
      success = await ref
          .read(userProvider.notifier)
          .updateUser(selectedItem!.userId, request);
    } else {
      final request = UserCreateRequest(
        userName: _usernameController.text.trim(),
        userPassword: _passwordController.text.trim(),
        role: _selectedRole,
      );
      success = await ref.read(userProvider.notifier).createUser(request);
    }
    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(userProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(UserModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(userProvider.notifier)
        .deleteUser(selectedItem!.userId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      setState(() {
        selectedItem = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(userProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  String _roleLabel(String role) {
    return localizeUserRole(role);
  }

  Color _roleColor(String role) {
    switch (apiUserRole(role)) {
      case 'DIRECTOR':
        return AppColors.destructive;
      case 'TEACHER':
        return AppColors.primary;
      default:
        return AppColors.mutedForeground;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    final columns = [
      DataColumnDef<UserModel>(
        key: 'userName',
        label: 'ຊື່ຜູ້ໃຊ້',
        flex: 3,
        render: (v, row) => Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  v.toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              v.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
      DataColumnDef<UserModel>(
        key: 'role',
        label: 'ສິດທິ',
        flex: 2,
        render: (context, item) => Text(
          _roleLabel(item.role),
          style: TextStyle(
            color: _roleColor(item.role),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: AppDataTable<UserModel>(
                  data: userState.isLoading ? _getMockUsers() : userState.users,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  canDelete: (item) => apiUserRole(item.role) != 'DIRECTOR',
                  searchKeys: const ['userName'],
                  addLabel: 'ເພີ່ມຜູ້ໃຊ້',
                  isLoading: userState.isLoading,
                ),
              ),
            ],
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<UserModel> _getMockUsers() {
    return List.generate(
      5,
      (index) => UserModel(
        userId: index + 1,
        userName: 'user${index + 1}',
        role: index % 2 == 0 ? 'admin' : 'teacher',
      ),
    );
  }

  bool get _isFormValid {
    final isPasswordValid = isEditing || _passwordController.text.isNotEmpty;
    return _usernameController.text.isNotEmpty &&
        isPasswordValid &&
        _selectedRole.isNotEmpty;
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(userProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຜູ້ໃຊ້' : 'ເພີ່ມຜູ້ໃຊ້ໃໝ່',
          size: AppDialogSize.medium,
          onClose: () => setState(() {
            showAddEditModal = false;
            _resetForm();
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showAddEditModal = false;
                  _resetForm();
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: isEditing ? 'ຢືນຢັນ' : 'ບັນທຶກ',
                icon: Icons.save_rounded,
                isLoading: isLoading,
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'ກຳນົດຊື່ຜູ້ໃຊ້',
                hint: 'ເຊັ່ນ: admin, TC001',
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                textInputAction: TextInputAction.next,
                required: true,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'ລະຫັດຜ່ານ',
                hint: isEditing
                    ? 'ປ້ອນລະຫັດໃໝ່ (ຖ້າຕ້ອງການປ່ຽນລະຫັດ)'
                    : 'ປ້ອນລະຫັດຜ່ານ',
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                required: !isEditing,
                textInputAction: TextInputAction.next,
                obscureText: !_showPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                label: 'ກຳນົດສິດທິ',
                hint: 'ເລືອກສິດທິ',
                value: _selectedRole,
                required: true,
                items: _roles
                    .map(
                      (r) => DropdownMenuItem(
                        value: r['value'],
                        child: Text(r['label'] ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v != null) _selectedRole = v;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(userProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການລຶບ',
          size: AppDialogSize.small,
          onClose: () => setState(() {
            showDeleteDialog = false;
            selectedItem = null;
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showDeleteDialog = false;
                  selectedItem = null;
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ລຶບ',
                icon: Icons.delete_rounded,
                variant: AppButtonVariant.danger,
                isLoading: isLoading,
                onPressed: isLoading ? null : _delete,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.userName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

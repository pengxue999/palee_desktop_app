import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/models/level_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../providers/level_provider.dart';
import '../../services/level_service.dart';

class LevelScreen extends ConsumerStatefulWidget {
  const LevelScreen({super.key});

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  Level? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(levelProvider.notifier).getLevels();
      if (mounted) {
        final error = ref.read(levelProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _nameController.clear();
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

  void _openEdit(Level item) {
    _nameController.text = item.levelName;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty) return;

    final request = LevelRequest(levelName: _nameController.text.trim());

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(levelProvider.notifier)
          .updateLevel(selectedItem!.levelId, request);
    } else {
      success = await ref.read(levelProvider.notifier).createLevel(request);
    }

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else {
      final errorMessage = ref.read(levelProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(Level item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  void _delete() async {
    if (selectedItem != null) {
      final success = await ref
          .read(levelProvider.notifier)
          .deleteLevel(selectedItem!.levelId);

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
        final errorMessage = ref.read(levelProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelState = ref.watch(levelProvider);
    final items = levelState.levels;
    final isLoading = levelState.isLoading && items.isEmpty;

    final columns = [
      DataColumnDef<Level>(
        key: 'levelId',
        label: 'ລະຫັດ',
        flex: 2,
        render: (v, row) => Text(
          v.toString(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<Level>(
        key: 'levelName',
        label: 'ຊັ້ນ/ລະດັບ',
        flex: 3,
        render: (v, row) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            v.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppDataTable<Level>(
                  data: isLoading ? _getMockLevels() : items,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['levelId', 'levelName'],
                  addLabel: 'ເພີ່ມຊັ້ນຮຽນ/ລະດັບ',
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<Level> _getMockLevels() {
    return List.generate(
      5,
      (index) => Level(
        levelId: (index + 1).toString(),
        levelName: 'ຊັ້ນ ${index + 1}',
      ),
    );
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(levelProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຊັ້ນ/ລະດັບ' : 'ເພີ່ມຊັ້ນ/ລະດັບໃໝ່',
          size: AppDialogSize.small,
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
                onPressed: (isLoading || _nameController.text.trim().isEmpty)
                    ? null
                    : _save,
              ),
            ],
          ),
          child: AppTextField(
            label: 'ຊື່ຊັ້ນ/ລະດັບ',
            hint: 'ເຊັ່ນ: ມ.4, ເລີ່ມຕົ້ນຕົ້ນ, HSK1',
            controller: _nameController,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(levelProvider).isLoading;
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.levelName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

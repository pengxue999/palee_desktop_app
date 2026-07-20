import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/enum_localization.dart';
import '../../models/teacher_assignment_model.dart';
import '../../models/teacher_model.dart';
import '../../models/teaching_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../services/teacher_assignment_service.dart';
import '../../services/teacher_service.dart';
import '../../services/teaching_log_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_searchable_dropdown.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import 'widgets/left_panel.dart';
import 'widgets/teacher_info_card.dart';
import 'widgets/teacher_detail_card.dart';
import 'widgets/admin_teacher_summary_card.dart';

class TeachingTrackingScreen extends ConsumerStatefulWidget {
  const TeachingTrackingScreen({super.key});

  @override
  ConsumerState<TeachingTrackingScreen> createState() =>
      _TeachingTrackingScreenState();
}

const _noActiveYearMessage =
    'ບໍ່ມີສົກຮຽນທີ່ກຳລັງດຳເນີນການ, ບໍ່ສາມາດເບິ່ງ ຫຼື ບັນທຶກການສອນໄດ້';

const _noActiveYearTitle = 'ບໍ່ມີສົກຮຽນທີ່ກຳລັງດຳເນີນການ';
const _noActiveYearSubtitle =
    'ການບັນທຶກ ແລະ ການເບິ່ງປະຫວັດການສອນ ໃຊ້ໄດ້ສະເພາະສົກຮຽນທີ່ກຳລັງດຳເນີນການເທົ່ານັ້ນ';

class _TeachingTrackingScreenState
    extends ConsumerState<TeachingTrackingScreen> {
  final _assignmentService = TeacherAssignmentService();
  final _teacherService = TeacherService();
  final _logService = TeachingLogService();

  late final TextEditingController _hourlyController;
  late final TextEditingController _remarkController;

  List<TeacherModel> _teachers = [];
  List<TeacherAssignmentModel> _assignments = [];
  List<TeachingLogModel> _logs = [];

  bool _isLoading = true;
  String? _errorMessage;

  /// ບໍ່ແມ່ນຄວາມຜິດພາດ — ເປັນສະຖານະປົກກະຕິເມື່ອຍັງບໍ່ໄດ້ກຳນົດສົກຮຽນດຳເນີນການ.
  bool _noActiveYear = false;

  TeachingLogModel? _editingLog;

  bool _showAdminForm = false;

  String? _formAssignmentId;
  String _formStatus = 'ຂຶ້ນສອນ';
  final String _statusFilter = 'ທັງໝົດ';

  DateTime? _fromDate;
  DateTime? _toDate;

  String? _selectedTeacherId;

  bool _isSubstituteMode = false;
  String? _subTeacherId;
  String? _substituteForAssignmentId;
  List<TeacherAssignmentModel> _subAssignments = [];
  bool _subAssignmentsLoading = false;

  List<TeachingLogModel> get _filteredLogs {
    if (_statusFilter == 'ທັງໝົດ') return _logs;
    return _logs.where((l) => l.status == _statusFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _hourlyController = TextEditingController(text: '2');
    _remarkController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _hourlyController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  /// ໜ້ານີ້ໃຊ້ໄດ້ສະເພາະສົກຮຽນທີ່ກຳລັງດຳເນີນການເທົ່ານັ້ນ.
  /// ຄືນ null ເມື່ອບໍ່ມີສົກ ACTIVE — ບໍ່ຕ້ອງ fallback ໃສ່ສົກທີ່ສິ້ນສຸດແລ້ວ.
  String? _getActiveAcademicYear(AcademicYearState state) {
    for (final ay in state.academicYears) {
      if (isActiveAcademicStatus(ay.academicStatus)) return ay.academicYear;
    }
    return null;
  }

  String? _getCurrentAcademicYear() =>
      _getActiveAcademicYear(ref.read(academicYearProvider));

  bool get _hasActiveAcademicYear => _getCurrentAcademicYear() != null;

  String? _getFromDateString() {
    if (_fromDate == null) return null;
    return '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}';
  }

  String? _getToDateString() {
    if (_toDate == null) return null;
    return '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}';
  }

  Future<void> _init() async {
    await ref.read(academicYearProvider.notifier).getAcademicYears();
    final auth = ref.read(authProvider);
    if (isTeacherRole(auth.role)) {
      await _loadTeacherData(auth.teacherId!);
    } else {
      await _loadAdminData();
    }
  }

  Future<void> _loadTeacherData(String teacherId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noActiveYear = false;
    });
    final academicYear = _getCurrentAcademicYear();
    if (academicYear == null) {
      setState(() {
        _assignments = [];
        _formAssignmentId = null;
        _logs = [];
        _noActiveYear = true;
        _isLoading = false;
      });
      return;
    }
    try {
      final teachersRes = await _teacherService.getTeachers();
      final assignRes = await _assignmentService.getAssignmentsByTeacher(
        teacherId,
      );
      setState(() {
        _teachers = teachersRes.data;
        _assignments = assignRes.data;
        _formAssignmentId = assignRes.data.isNotEmpty
            ? assignRes.data.first.assignmentId
            : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      return;
    }
    try {
      final logRes = await _logService.getByTeacher(
        teacherId,
        academicYear: academicYear,
        fromDate: _getFromDateString(),
        toDate: _getToDateString(),
      );
      setState(() {
        _logs = logRes.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noActiveYear = false;
    });
    final academicYear = _getCurrentAcademicYear();
    if (academicYear == null) {
      setState(() {
        _selectedTeacherId = null;
        _showAdminForm = false;
        _assignments = [];
        _formAssignmentId = null;
        _logs = [];
        _noActiveYear = true;
        _isLoading = false;
      });
      return;
    }
    try {
      final teachersRes = await _teacherService.getTeachers();
      setState(() {
        _teachers = teachersRes.data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      return;
    }
    try {
      final logRes = await _logService.getAll(academicYear: academicYear);
      setState(() {
        _logs = logRes.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
    if (_selectedTeacherId != null) {
      await _loadAssignmentsOnly(_selectedTeacherId!);
    }
  }

  Future<void> _loadAssignmentsOnly(String teacherId) async {
    try {
      final assignRes = await _assignmentService.getAssignmentsByTeacher(
        teacherId,
      );
      setState(() {
        _assignments = assignRes.data;
        _formAssignmentId = assignRes.data.isNotEmpty
            ? assignRes.data.first.assignmentId
            : null;
      });
    } catch (_) {}
  }

  Future<void> _loadAssignmentsAndLogs(String teacherId) async {
    setState(() {
      _isLoading = true;
      _noActiveYear = false;
    });
    final academicYear = _getCurrentAcademicYear();
    if (academicYear == null) {
      setState(() {
        _assignments = [];
        _formAssignmentId = null;
        _logs = [];
        _noActiveYear = true;
        _isLoading = false;
      });
      return;
    }
    try {
      final assignRes = await _assignmentService.getAssignmentsByTeacher(
        teacherId,
      );
      setState(() {
        _assignments = assignRes.data;
        _formAssignmentId = assignRes.data.isNotEmpty
            ? assignRes.data.first.assignmentId
            : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      return;
    }
    try {
      final logRes = await _logService.getByTeacher(
        teacherId,
        academicYear: academicYear,
        fromDate: _getFromDateString(),
        toDate: _getToDateString(),
      );
      setState(() {
        _logs = logRes.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeachersIfNeeded() async {
    if (_teachers.isNotEmpty) return;
    try {
      final res = await _teacherService.getTeachers();
      if (mounted) setState(() => _teachers = res.data);
    } catch (_) {}
  }

  Future<void> _loadSubAssignments(String teacherId) async {
    setState(() {
      _subAssignmentsLoading = true;
      _substituteForAssignmentId = null;
      _subAssignments = [];
    });
    try {
      final res = await _assignmentService.getAssignmentsByTeacher(teacherId);
      if (mounted) {
        setState(() {
          _subAssignments = res.data;
          _subAssignmentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _subAssignmentsLoading = false);
    }
  }

  void _loadFormFromLog(TeachingLogModel log) {
    setState(() {
      _editingLog = log;
      _isSubstituteMode = false;
      _subTeacherId = null;
      _subAssignments = [];
      _substituteForAssignmentId = null;
      _formAssignmentId = log.assignmentId;
      _formStatus = log.status ?? 'ຂຶ້ນສອນ';
      _hourlyController.text = log.hourly.toStringAsFixed(0);
      _remarkController.text = log.remark ?? '';
    });
  }

  void _resetForm() {
    setState(() {
      _editingLog = null;
      _isSubstituteMode = false;
      _subTeacherId = null;
      _subAssignments = [];
      _substituteForAssignmentId = null;
      _formAssignmentId = _assignments.isNotEmpty
          ? _assignments.first.assignmentId
          : null;
      _formStatus = 'ຂຶ້ນສອນ';
      _hourlyController.text = '2';
      _remarkController.text = '';
    });
  }

  Future<void> _handleSave() async {
    if (!_hasActiveAcademicYear) {
      AppToast.show(
        context: context,
        message: _noActiveYearMessage,
        type: ToastType.warning,
      );
      return;
    }
    if (_formAssignmentId == null) {
      AppToast.show(
        context: context,
        message: 'ກະລຸນາເລືອກວິຊາຂອງຂ້ອຍ',
        type: ToastType.warning,
      );
      return;
    }
    if (_isSubstituteMode &&
        _editingLog == null &&
        _substituteForAssignmentId == null) {
      AppToast.show(
        context: context,
        message: 'ກະລຸນາເລືອກວິຊາທີ່ຈະສອນແທນ',
        type: ToastType.warning,
      );
      return;
    }
    final hourly = double.tryParse(_hourlyController.text.trim()) ?? 0.0;
    if (hourly < 1 || hourly > 2) {
      AppToast.show(
        context: context,
        message: 'ກະລຸນາປ້ອນຈຳນວນຊົ່ວໂມງທີ່ສອນ ລະຫວ່າງ 1 ຫາ 2',
        type: ToastType.warning,
      );
      return;
    }
    String? assignmentId = _formAssignmentId;
    String status = _formStatus;
    String? remark = _remarkController.text.trim().isEmpty
        ? null
        : _remarkController.text.trim();
    if (_editingLog == null) {
      status = 'ຂຶ້ນສອນ';
      remark = _isSubstituteMode ? 'ສອນແທນ' : 'ສອນເອງ';
      if (_isSubstituteMode &&
          assignmentId == null &&
          _assignments.isNotEmpty) {
        assignmentId = _assignments.first.assignmentId;
      }
    }
    if (assignmentId == null) {
      AppToast.show(
        context: context,
        message: 'ກະລຸນາເລືອກວິຊາ',
        type: ToastType.warning,
      );
      return;
    }
    try {
      final request = TeachingLogRequest(
        assignmentId: assignmentId,
        substituteForAssignmentId: (_isSubstituteMode && _editingLog == null)
            ? _substituteForAssignmentId
            : null,
        hourly: hourly,
        remark: remark,
        status: status,
      );
      if (_editingLog != null) {
        await _logService.updateLog(_editingLog!.teachingLogId, request);
      } else {
        await _logService.createLog(request);
      }
      final auth = ref.read(authProvider);
      final wasEditing = _editingLog != null;
      if (isTeacherRole(auth.role)) {
        _resetForm();
        await _loadTeacherData(auth.teacherId!);
      } else {
        _resetForm();
        if (_selectedTeacherId != null) {
          await _loadAssignmentsAndLogs(_selectedTeacherId!);
        }
      }
      if (mounted) {
        AppToast.show(
          context: context,
          message: wasEditing ? 'ອັບເດດບັນທຶກສຳເລັດ' : 'ບັນທຶກການສອນສຳເລັດ',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _handleDelete(TeachingLogModel log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ຢືນຢັນການລຶບ'),
        content: Text(
          'ທ່ານຕ້ອງການລຶບບັນທຶກ "${log.isSubstitute && log.substituteForSubjectName != null ? log.substituteForSubjectName : log.subjectName}" ແທ້ບໍ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ລຶບ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _logService.deleteLog(log.teachingLogId);
      if (_editingLog?.teachingLogId == log.teachingLogId) _resetForm();
      final auth = ref.read(authProvider);
      if (isTeacherRole(auth.role)) {
        await _loadTeacherData(auth.teacherId!);
      } else if (_selectedTeacherId != null) {
        await _loadAssignmentsAndLogs(_selectedTeacherId!);
      }
      if (mounted) {
        AppToast.show(
          context: context,
          message: 'ລຶບບັນທຶກສຳເລັດ',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isTeacher = isTeacherRole(auth.role);
    final hasActiveYear =
        _getActiveAcademicYear(ref.watch(academicYearProvider)) != null;

    final detailTeacher = _detailTeacher(isTeacher, auth);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if ((isTeacher || _showAdminForm) && hasActiveYear)
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LeftPanel(
                  child: isTeacher
                      ? _buildTeacherPanel(auth)
                      : _buildAdminPanel(),
                ),
                if (detailTeacher != null)
                  Container(
                    margin: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    width: 520,
                    child: TeacherDetailCard(teacher: detailTeacher),
                  ),
              ],
            ),
          ),
        Expanded(child: _buildRightPanel(isTeacher, auth)),
      ],
    );
  }

  TeacherModel? _detailTeacher(bool isTeacher, AuthState auth) {
    if (isTeacher) {
      return _teachers.firstWhere(
        (t) => t.teacherId == auth.teacherId,
        orElse: () => TeacherModel(
          teacherId: auth.teacherId ?? '',
          teacherName: auth.userName ?? '',
          teacherLastname: '',
          gender: '',
          teacherContact: '',
          districtName: '',
          provinceName: '',
        ),
      );
    }
    if (_selectedTeacherId == null || _teachers.isEmpty) return null;
    return _teachers.firstWhere(
      (t) => t.teacherId == _selectedTeacherId,
      orElse: () => _teachers.first,
    );
  }

  Widget _buildTeacherPanel(AuthState auth) {
    final currentTeacher = _teachers.firstWhere(
      (t) => t.teacherId == auth.teacherId,
      orElse: () => TeacherModel(
        teacherId: auth.teacherId ?? '',
        teacherName: auth.userName ?? '',
        teacherLastname: '',
        gender: '',
        teacherContact: '',
        districtName: '',
        provinceName: '',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeacherInfoCard(auth: auth, teacherName: currentTeacher.fullName),
        const SizedBox(height: 24),
        Divider(color: AppColors.accentForeground.withOpacity(0.5), height: 1),
        const SizedBox(height: 12),
        if (_editingLog == null) ...[
          _buildModeToggle(),
          const SizedBox(height: 16),
        ],
        if (!_isSubstituteMode) ...[
          AppDropdown<String>(
            label: 'ເລືອກວິຊາ',
            required: true,
            value: _formAssignmentId,
            hint: 'ເລືອກວິຊາ...',
            items: _assignments
                .map(
                  (a) => DropdownMenuItem(
                    value: a.assignmentId,
                    child: Text(
                      '${a.subjectName} (${a.levelName}) - ${_formatNum(a.hourlyRate)} ກີບ/ຊມ',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _formAssignmentId = v),
          ),
          const SizedBox(height: 16),
        ],
        if (_isSubstituteMode && _editingLog == null) ...[
          const SizedBox(height: 16),
          _buildSubstituteTeacherPicker(excludeTeacherId: auth.teacherId),
        ],
        const SizedBox(height: 16),
        AppTextField(
          label: 'ຈຳນວນຊົ່ວໂມງທີ່ສອນ',
          required: true,
          controller: _hourlyController,
          hint: '2',
          digitOnly: DigitOnly.decimal,
          noLeadingZero: true,
          maxValue: 2,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),
        if (_editingLog != null) ...[
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'ຍົກເລີກ',
                  variant: AppButtonVariant.outline,
                  onPressed: _resetForm,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'ບັນທຶກການແກ້ໄຂ',
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ] else
          AppButton(
            label: _isSubstituteMode ? 'ບັນທຶກການສອນແທນ' : 'ບັນທຶກການສອນ',
            icon: _isSubstituteMode
                ? Icons.swap_horiz_rounded
                : Icons.add_rounded,
            isFullWidth: true,
            onPressed: _formAssignmentId != null ? _handleSave : null,
            size: AppButtonSize.large,
          ),
      ],
    );
  }

  Widget _buildAdminPanel() {
    final selectedTeacher = _selectedTeacherId != null && _teachers.isNotEmpty
        ? _teachers.firstWhere(
            (t) => t.teacherId == _selectedTeacherId,
            orElse: () => _teachers.first,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => setState(() {
                _showAdminForm = false;
                _selectedTeacherId = null;
                _assignments = [];
                _logs = [];
                _loadAdminData();
              }),
              icon: Icon(Icons.close_rounded),
              tooltip: 'ປິດ',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        AppSearchableDropdown<String>(
          label: 'ເລືອກອາຈານ',
          required: true,
          value: _teachers.any((t) => t.teacherId == _selectedTeacherId)
              ? _selectedTeacherId
              : null,
          hint: 'ເລືອກອາຈານ...',
          searchHint: 'ຄົ້ນຫາຊື່ອາຈານ...',
          emptyText: 'ບໍ່ພົບອາຈານ',
          items: _teachers
              .map(
                (t) => AppSearchableItem(
                  value: t.teacherId,
                  label: '${t.teacherName} ${t.teacherLastname}',
                ),
              )
              .toList(),
          onChanged: (v) async {
            setState(() {
              _selectedTeacherId = v;
              _assignments = [];
              _logs = [];
              _formAssignmentId = null;
              _editingLog = null;
              _hourlyController.text = '2';
              _remarkController.text = '';
              _formStatus = 'ຂຶ້ນສອນ';
            });
            if (v != null) await _loadAssignmentsAndLogs(v);
          },
        ),
        if (selectedTeacher != null) ...[
          const SizedBox(height: 12),
          AdminTeacherSummaryCard(teacher: selectedTeacher),
        ],
        if (_selectedTeacherId != null) ...[
          const SizedBox(height: 20),
          Divider(
            color: AppColors.accentForeground.withOpacity(0.5),
            height: 1,
          ),
          const SizedBox(height: 12),
          if (_editingLog == null) ...[
            _buildModeToggle(),
            const SizedBox(height: 16),
          ],
          if (!_isSubstituteMode || _editingLog != null)
            AppDropdown<String>(
              label: 'ເລືອກວິຊາ',
              required: true,
              value: _formAssignmentId,
              hint: 'ເລືອກວິຊາ...',
              items: _assignments
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.assignmentId,
                      child: Text(
                        '${a.subjectName} (${a.levelName}) - ${_formatNum(a.hourlyRate)} ກີບ/ຊມ',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _formAssignmentId = v),
            ),
          if (_isSubstituteMode && _editingLog == null) ...[
            const SizedBox(height: 16),
            _buildSubstituteTeacherPicker(excludeTeacherId: _selectedTeacherId),
          ],
          const SizedBox(height: 16),
          AppTextField(
            label: 'ຈຳນວນຊົ່ວໂມງທີ່ສອນ',
            required: true,
            controller: _hourlyController,
            hint: '2',
            digitOnly: DigitOnly.decimal,
            noLeadingZero: true,
            maxValue: 2,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          if (_editingLog != null)
            AppDropdown<String>(
              label: 'ສະຖານະ',
              required: true,
              value: _formStatus,
              items: [
                'ຂຶ້ນສອນ',
                'ຂາດສອນ',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _formStatus = v ?? 'ຂຶ້ນສອນ'),
            ),
          const SizedBox(height: 16),
          const SizedBox(height: 20),
          if (_editingLog != null) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'ຍົກເລີກ',
                    variant: AppButtonVariant.outline,
                    onPressed: _resetForm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'ບັນທຶກການແກ້ໄຂ',
                    onPressed: _handleSave,
                  ),
                ),
              ],
            ),
          ] else
            AppButton(
              label: _isSubstituteMode ? 'ບັນທຶກການສອນແທນ' : 'ບັນທຶກການສອນ',
              icon: _isSubstituteMode
                  ? Icons.swap_horiz_rounded
                  : Icons.add_rounded,
              isFullWidth: true,
              onPressed: _isSubstituteMode
                  ? (_substituteForAssignmentId != null ? _handleSave : null)
                  : (_formAssignmentId != null ? _handleSave : null),
            ),
        ],
      ],
    );
  }

  Widget _buildRightPanel(bool isTeacher, AuthState auth) {
    final academicYearState = ref.watch(academicYearProvider);
    final activeAcademicYear = _getActiveAcademicYear(academicYearState);
    final currentAcademicYear = activeAcademicYear ?? 'ບໍ່ມີສົກຮຽນດຳເນີນການ';
    final badgeColor = activeAcademicYear != null
        ? AppColors.primary
        : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ປະຫວັດການຂຶ້ນສອນຂອງອາຈານ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const Spacer(),
              if (!isTeacher && !_showAdminForm && activeAcademicYear != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AppButton(
                    label: '+ ບັນທຶກການສອນໃຫ້ອາຈານ',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    onPressed: () => setState(() => _showAdminForm = true),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activeAcademicYear != null
                          ? Icons.calendar_today_rounded
                          : Icons.event_busy_rounded,
                      size: 16,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentAcademicYear,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildTable(isTeacher)),
        ],
      ),
    );
  }

  /// ບໍ່ມີສົກຮຽນດຳເນີນການ — ບໍ່ແມ່ນ error, ຈຶ່ງໃຊ້ໂທນ warning ແທນສີແດງ.
  Widget _buildNoActiveYearState(bool isTeacher) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.foreground.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warningLight,
                      AppColors.warningLight.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 32,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                _noActiveYearTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                _noActiveYearSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              if (isTeacher)
                _buildHintBanner('ກະລຸນາຕິດຕໍ່ຜູ້ອຳນວຍການເພື່ອກຳນົດສົກຮຽນ')
              else
                AppButton(
                  label: 'ໄປກຳນົດສົກຮຽນ',
                  icon: Icons.calendar_month_rounded,
                  isFullWidth: true,
                  onPressed: () => context.goNamed('academic-years'),
                ),
              const SizedBox(height: 10),
              AppButton(
                label: 'ລອງໃໝ່',
                variant: AppButtonVariant.ghost,
                isFullWidth: true,
                onPressed: _init,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.destructiveLight,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.destructive,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'ລອງໃໝ່',
              variant: AppButtonVariant.outline,
              icon: Icons.refresh_rounded,
              onPressed: _init,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(bool isTeacher) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_noActiveYear) return _buildNoActiveYearState(isTeacher);
    if (_errorMessage != null) return _buildErrorState();
    if (!isTeacher && _logs.isEmpty && _selectedTeacherId == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: AppColors.mutedForeground,
            ),
            SizedBox(height: 12),
            Text(
              'ເລືອກອາຈານເພື່ອເບິ່ງບັນທຶກການສອນ ຫຼື ກົດບັນທຶກການສອນໃຫ້ອາຈານ',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final List<DataColumnDef<TeachingLogModel>> columns = [];

    if (!isTeacher) {
      columns.add(
        DataColumnDef(
          key: 'teacherFullName',
          label: 'ອາຈານ',
          render: (v, log) => Text(
            v as String,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      );
    }

    columns.addAll([
      DataColumnDef(
        key: 'subjectName',
        label: 'ວິຊາ',
        render: (v, log) => Text(
          log.isSubstitute && log.substituteForSubjectName != null
              ? log.substituteForSubjectName!
              : v as String,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      DataColumnDef(
        key: 'levelName',
        label: 'ລະດັບ',
        render: (v, log) => Text(
          log.isSubstitute && log.substituteForLevelName != null
              ? log.substituteForLevelName!
              : v as String,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      DataColumnDef(
        key: 'hourly',
        label: 'ຊ.ມ',
        render: (v, _) => Text(
          (double.tryParse(v?.toString() ?? '0') ?? 0).toStringAsFixed(0),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      // DataColumnDef(
      //   key: 'hourlyRate',
      //   label: 'ຄ່າສອນ/ຊມ',
      //   render: (v, _) => Text(
      //     '${_formatNum(double.tryParse(v?.toString() ?? '0') ?? 0)} ກີບ',
      //     style: const TextStyle(fontSize: 14),
      //   ),
      // ),

      // DataColumnDef(
      //   key: 'totalAmount',
      //   label: 'ຈຳນວນເງິນ',
      //   render: (v, _) => Text(
      //     '${_formatNum(double.tryParse(v?.toString() ?? '0') ?? 0)} ກີບ',
      //     style: const TextStyle(fontSize: 14),
      //   ),
      // ),
      DataColumnDef(
        key: 'status',
        label: 'ສະຖານະ',
        render: (v, _) => _buildStatusBadge(v as String?),
      ),
      DataColumnDef(
        key: 'teachingDate',
        label: 'ວັນທີ່',
        render: (v, _) =>
            Text((v as String?) ?? '-', style: const TextStyle(fontSize: 14)),
      ),
    ]);

    final bool showActions = !isTeacher && _selectedTeacherId != null;

    return AppDataTable<TeachingLogModel>(
      data: _filteredLogs,
      showActions: showActions,
      onEdit: showActions ? _loadFormFromLog : null,
      onDelete: showActions ? _handleDelete : null,
      columns: columns,
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (_isSubstituteMode) {
                  setState(() {
                    _isSubstituteMode = false;
                    _subTeacherId = null;
                    _subAssignments = [];
                    _substituteForAssignmentId = null;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isSubstituteMode
                      ? AppColors.primary
                      : AppColors.muted,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: !_isSubstituteMode
                          ? Colors.white
                          : AppColors.accentForeground,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ສອນເອງ',
                      style: TextStyle(
                        color: !_isSubstituteMode
                            ? Colors.white
                            : AppColors.accentForeground,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                if (!_isSubstituteMode) {
                  setState(() {
                    _isSubstituteMode = true;
                    _subTeacherId = null;
                    _subAssignments = [];
                    _substituteForAssignmentId = null;
                  });
                  await _loadTeachersIfNeeded();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isSubstituteMode ? AppColors.info : AppColors.muted,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: _isSubstituteMode
                          ? Colors.white
                          : AppColors.accentForeground,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ສອນແທນ',
                      style: TextStyle(
                        color: _isSubstituteMode
                            ? Colors.white
                            : AppColors.accentForeground,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubstituteTeacherPicker({String? excludeTeacherId}) {
    final uniqueTeachers = <String, TeacherModel>{};
    for (final t in _teachers) {
      uniqueTeachers[t.teacherId] = t;
    }
    final availableTeachers = excludeTeacherId != null
        ? uniqueTeachers.values
              .where((t) => t.teacherId != excludeTeacherId)
              .toList()
        : uniqueTeachers.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchableDropdown<String>(
          label: 'ເລືອກອາຈານທີ່ຈະສອນແທນ',
          required: true,
          value: availableTeachers.any((t) => t.teacherId == _subTeacherId)
              ? _subTeacherId
              : null,
          hint: 'ເລືອກອາຈານ...',
          searchHint: 'ຄົ້ນຫາຊື່ອາຈານ...',
          emptyText: 'ບໍ່ພົບອາຈານ',
          items: availableTeachers
              .map(
                (t) => AppSearchableItem(
                  value: t.teacherId,
                  label: '${t.teacherName} ${t.teacherLastname}',
                ),
              )
              .toList(),
          onChanged: (v) async {
            setState(() => _subTeacherId = v);
            if (v != null) await _loadSubAssignments(v);
          },
        ),
        if (_subTeacherId != null) ...[
          const SizedBox(height: 16),
          if (_subAssignmentsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            AppDropdown<String>(
              label: 'ວິຊາທີ່ສອນແທນ',
              required: true,
              value: _substituteForAssignmentId,
              hint: 'ເລືອກວິຊາ...',
              items: _subAssignments
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.assignmentId,
                      child: Text(
                        '${a.subjectName} (${a.levelName}) - ${_formatNum(a.hourlyRate)} ກີບ/ຊມ',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _substituteForAssignmentId = v),
            ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    final isAbsent = status == 'ຂາດສອນ';
    return Text(
      status ?? '-',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isAbsent ? AppColors.destructive : AppColors.success,
      ),
    );
  }

  String _formatNum(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
      result.write(parts[i]);
    }
    return result.toString();
  }
}

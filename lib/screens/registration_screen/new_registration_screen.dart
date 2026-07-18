import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palee_elite_training_center/core/utils/registration_receipt_printer.dart';
import 'package:palee_elite_training_center/models/discount_model.dart';
import 'package:palee_elite_training_center/models/province_model.dart';
import 'package:palee_elite_training_center/models/district_model.dart';
import 'package:palee_elite_training_center/providers/discount_provider.dart';
import 'package:palee_elite_training_center/providers/province_provider.dart';
import 'package:palee_elite_training_center/providers/district_provider.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/new_student_form.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/select_student_banner.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/select_subject_section.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/right_panel.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/student_selection_list.dart';
import 'package:palee_elite_training_center/widgets/app_toast.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_dialog.dart';
import 'package:palee_elite_training_center/widgets/app_confirm_dialog.dart';
import 'package:palee_elite_training_center/widgets/section_card.dart';
import '../../core/constants/app_colors.dart';
import '../../models/academic_year_model.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/fee_model.dart';
import '../../models/student_model.dart';
import '../../models/registration_model.dart';
import '../../providers/academic_year_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/registration_provider.dart';
import '../../core/utils/enum_localization.dart';
import '../../widgets/print_preparation_overlay.dart';
import '../../widgets/success_overlay.dart';

class Student {
  final String id;
  final String name;
  final String lastname;
  final String gender;
  final String phone;
  final String parentsContact;
  final String school;
  final String districtId;
  final String? districtName;
  final String? provinceName;
  final String academicYear;

  Student({
    required this.id,
    required this.name,
    required this.lastname,
    required this.gender,
    required this.phone,
    required this.parentsContact,
    required this.school,
    required this.districtId,
    this.districtName,
    this.provinceName,
    required this.academicYear,
  });

  String get fullName => '$name $lastname';
}

class NewRegistrationScreen extends ConsumerStatefulWidget {
  const NewRegistrationScreen({super.key});

  @override
  ConsumerState<NewRegistrationScreen> createState() =>
      _NewRegistrationScreenState();
}

class _NewRegistrationScreenState extends ConsumerState<NewRegistrationScreen> {
  int _currentStep = 1;
  bool _isPreparingPrint = false;
  final _steps = const [
    'ກວດສອບນັກຮຽນ',
    'ເລືອກວິຊາ',
    'ເລືອກສ່ວນຫຼຸດ',
    'ກຳນົດສ່ວນຫຼຸດ',
    'ພິມໃບລົງທະບຽນ',
  ];

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Student? _selectedStudent;

  final Set<String> _selectedFeeIds = {};

  String? _selectedDiscountId;
  // ສ່ວນຫຼຸດທີ່ລະບົບເລືອກໃຫ້ໂດຍອັດຕະໂນມັດ (ໃຊ້ກວດສອບວ່າຄວນຍ້າຍ/ລົບ ໂດຍບໍ່ທັບການເລືອກດ້ວຍມື).
  String? _autoAppliedDiscountId;
  Map<String, String> _scholarshipStatusByFee = {};
  bool _autoRenew = false;

  // ຜົນຄຳນວນສ່ວນຫຼຸດ/ຈຳນວນເງິນ ຈາກ backend (ແຫຼ່ງຄວາມຈິງ).
  RegistrationPreview? _preview;
  // token ກັນ race ເມື່ອມີຫຼາຍ request preview ຊ້ອນກັນ.
  int _previewToken = 0;

  // ມີການປ່ຽນແປງຂໍ້ມູນ (ເພີ່ມ/ລຶບ/ແກ້ໄຂ) ທີ່ຕ້ອງ refresh ໜ້າ list ບໍ.
  bool _registrationsDirty = false;

  // ການລົງທະບຽນທີ່ມີຢູ່ແລ້ວຂອງນັກຮຽນ (ສົກປັດຈຸບັນ). null = ຍັງບໍ່ມີ.
  StudentRegistration? _existingRegistration;
  // map: feeId -> regis_detail_id ສຳລັບວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ (ໃຊ້ກວດແກ້/ລຶບ).
  final Map<String, int> _existingDetailIdByFee = {};

  bool get _isLocked => _existingRegistration?.isLocked ?? false;
  bool _isExistingFee(String feeId) => _existingDetailIdByFee.containsKey(feeId);

  List<FeeModel> get _fees {
    final activeAcademicYear = _currentAcademicYear;
    if (activeAcademicYear.isEmpty) {
      return const <FeeModel>[];
    }

    return ref
        .watch(feeProvider)
        .fees
        .where((fee) => fee.academicYear == activeAcademicYear)
        .toList();
  }

  bool get _isLoadingFees => ref.watch(feeProvider).isLoading;
  List<DiscountModel> get _discounts {
    final activeAcademicYear = _currentAcademicYear;
    if (activeAcademicYear.isEmpty) {
      return const <DiscountModel>[];
    }

    return ref
        .watch(discountProvider)
        .discounts
        .where((discount) => discount.academicYear == activeAcademicYear)
        .toList();
  }

  List<DiscountModel> get _selectableDiscounts {
    if (_selectedFeeIds.length >= 3 && !_hasScholarshipFee) return _discounts;
    return _discounts
        .where((d) => d.discountDescription != _multiSubjectDiscountDescription)
        .toList();
  }

  bool get _hasScholarshipFee => _selectedFeeIds.any(
    (feeId) => _scholarshipStatusByFee[feeId] == 'ໄດ້ຮັບທຶນ',
  );

  List<StudentModel> get _apiStudents => ref.watch(studentProvider).students;
  List<Student> get _studentsFromApi {
    return _apiStudents
        .map(
          (s) => Student(
            id: s.studentId ?? '',
            name: s.studentName,
            lastname: s.studentLastname,
            gender: s.gender,
            phone: s.studentContact,
            parentsContact: s.parentsContact,
            school: s.school,
            districtId: s.districtName,
            districtName: s.districtName,
            provinceName: s.provinceName,
            academicYear: _currentAcademicYear,
          ),
        )
        .toList();
  }

  // ສະແດງນັກຮຽນທັງໝົດ (ລວມຄົນທີ່ລົງທະບຽນແລ້ວ) ເພື່ອໃຫ້ສາມາດເລືອກມາ
  // ເພີ່ມ/ແກ້ໄຂ ວິຊາໄດ້.
  List<Student> get _allStudents =>
      _studentsFromApi.where((s) => s.id.isNotEmpty).toList();

  List<Student> get _searchResults {
    if (_searchQuery.isEmpty) return _allStudents;
    final q = _searchQuery.toLowerCase();
    return _allStudents
        .where(
          (s) =>
              s.id.toLowerCase().contains(q) ||
              s.name.toLowerCase().contains(q) ||
              s.school.toLowerCase().contains(q),
        )
        .toList();
  }

  int get _tuitionFee => _selectedFeeIds.fold(0, (sum, feeId) {
    if (_scholarshipStatusByFee[feeId] == 'ໄດ້ຮັບທຶນ') return sum;
    final fee = _fees.firstWhere(
      (f) => f.feeId == feeId,
      orElse: () => const FeeModel(
        feeId: '',
        subjectName: '',
        levelName: '',
        subjectCategory: '',
        academicYear: '',
        fee: 0,
      ),
    );
    return sum + fee.fee.toInt();
  });

  int get _totalFee => _tuitionFee;

  // ຄ່າສະແດງຜົນ — ໃຫ້ຄ່າຈາກ backend preview ມາກ່ອນ, ບໍ່ດັ່ງນັ້ນຄ່ອຍ fallback ໃຊ້ການປະມານ.
  int get _displayTotalFee => _preview?.totalAmount.round() ?? _totalFee;

  int get _selectedDiscountAmount {
    final preview = _preview;
    if (preview != null) return preview.discountAmount.round();

    if (_selectedDiscountId == null) return 0;

    final discount = _discounts.firstWhere(
      (d) => d.discountId == _selectedDiscountId,
      orElse: () => const DiscountModel(
        discountId: '',
        discountAmount: 0,
        discountDescription: '',
        academicYear: '',
      ),
    );
    final discountPercentage = discount.discountAmount.toInt();
    return ((_tuitionFee * discountPercentage) / 100).round();
  }

  int get _netFee {
    final preview = _preview;
    if (preview != null) return preview.finalAmount.round();

    final amount = _totalFee - _selectedDiscountAmount;
    return amount < 0 ? 0 : amount;
  }

  String get _academicYearFromFees {
    if (_selectedFeeIds.isEmpty) return _currentAcademicYear;

    final selectedFees = _fees
        .where((f) => _selectedFeeIds.contains(f.feeId))
        .toList();
    if (selectedFees.isEmpty) return _currentAcademicYear;

    return selectedFees.first.academicYear;
  }

  String get _currentAcademicYear {
    return _activeAcademicYear?.academicYear ?? '';
  }

  String get _displayAcademicYear {
    return _currentAcademicYear.isNotEmpty
        ? _currentAcademicYear
        : 'ບໍ່ພົບສົກຮຽນດໍາເນີນການ';
  }

  AcademicYearModel? get _activeAcademicYear {
    final academicYears = ref.read(academicYearProvider).academicYears;
    for (final academicYear in academicYears) {
      if (isActiveAcademicStatus(academicYear.academicStatus)) {
        return academicYear;
      }
    }
    return null;
  }

  void _pickStudent(Student s) {
    setState(() {
      _selectedStudent = s;
      _currentStep = 2;
      // ລ້າງສະຖານະການເລືອກກ່ອນໂຫຼດຂໍ້ມູນຄົນໃໝ່.
      _selectedFeeIds.clear();
      _scholarshipStatusByFee = {};
      _existingDetailIdByFee.clear();
      _existingRegistration = null;
      _preview = null;
      _selectedDiscountId = null;
      _autoAppliedDiscountId = null;
    });
    _loadExistingRegistration(s.id);
  }

  /// ໂຫຼດການລົງທະບຽນທີ່ມີຢູ່ແລ້ວ ແລະ ນຳວິຊາເກົ່າມາສະແດງ.
  Future<void> _loadExistingRegistration(String studentId) async {
    try {
      final existing = await ref
          .read(registrationServiceProvider)
          .getRegistrationByStudent(studentId);

      if (!mounted || _selectedStudent?.id != studentId) return;

      setState(() {
        // ລົບວິຊາ "ເກົ່າ" ຊຸດກ່ອນອອກໝົດກ່ອນ (ກໍລະນີ reload ຫຼັງລຶບ/ແກ້)
        // ໂດຍຮັກສາວິຊາ "ໃໝ່" ທີ່ user ກຳລັງເລືອກຄ້າງໄວ້.
        for (final oldFeeId in _existingDetailIdByFee.keys) {
          _selectedFeeIds.remove(oldFeeId);
          _scholarshipStatusByFee.remove(oldFeeId);
        }
        _existingDetailIdByFee.clear();

        _existingRegistration = existing;
        if (existing != null) {
          for (final d in existing.details) {
            _selectedFeeIds.add(d.feeId);
            _existingDetailIdByFee[d.feeId] = d.regisDetailId;
            _scholarshipStatusByFee[d.feeId] =
                localizeScholarship(d.scholarship);
          }
          if (existing.details.isNotEmpty) _currentStep = 3;
        }
        if (_selectedFeeIds.isEmpty && _currentStep > 2) _currentStep = 2;
      });

      if (existing != null && existing.details.isNotEmpty) {
        _fetchPreview();
      }
    } catch (_) {
      if (!mounted || _selectedStudent?.id != studentId) return;
      setState(() => _existingRegistration = null);
    }
  }

  static const String _multiSubjectDiscountDescription = 'ຮຽນ 3 ວິຊາຂຶ້ນໄປ';
  static const String _lateRegistrationDiscountDescription = 'ລົງທະບຽນຮຽນຊ້າ';
  static const int _lateRegistrationThresholdDays = 14;

  bool get _isLateRegistration {
    final startDateRaw = _activeAcademicYear?.startDate ?? '';
    final startDate = _parseAcademicDate(startDateRaw);
    if (startDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lateThreshold = startDate.add(
      const Duration(days: _lateRegistrationThresholdDays),
    );
    return !today.isBefore(lateThreshold);
  }

  // ວັນທີຈາກ API ມາໃນຮູບແບບ dd-MM-yyyy.
  DateTime? _parseAcademicDate(String value) {
    if (value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(value);
  }

  void _toggleFee(String feeId) {
    if (_selectedStudent == null) return;

    // ວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ → ຕ້ອງຜ່ານ API (ກວດ lock + recompute).
    if (_isExistingFee(feeId)) {
      _removeExistingSubject(feeId);
      return;
    }

    setState(() {
      if (_selectedFeeIds.contains(feeId)) {
        _selectedFeeIds.remove(feeId);
        _scholarshipStatusByFee.remove(feeId);
      } else {
        if (_selectedFeeIds.length >= 3) {
          AppToast.warning(
            context,
            'ນັກຮຽນສາມາດລົງທະບຽນໄດ້ສູງສຸດ 3 ວິຊາເທົ່ານັ້ນ',
          );
          return;
        }
        _selectedFeeIds.add(feeId);
        _scholarshipStatusByFee[feeId] = 'ບໍ່ໄດ້ຮັບທຶນ';
      }
      if (_selectedFeeIds.isNotEmpty && _currentStep < 3) {
        _currentStep = 3;
      } else if (_selectedFeeIds.isEmpty && _currentStep > 2) {
        _currentStep = 2;
      }
      _applyAutoDiscount();
    });
    _fetchPreview();
  }

  /// ລຶບວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ (ຜ່ານ API). ບໍ່ໃຫ້ລຶບຖ້າຈ່າຍແລ້ວ.
  Future<void> _removeExistingSubject(String feeId) async {
    if (_isLocked) {
      AppToast.warning(context, 'ການລົງທະບຽນນີ້ຈ່າຍແລ້ວ ບໍ່ສາມາດລຶບວິຊາໄດ້');
      return;
    }
    final detailId = _existingDetailIdByFee[feeId];
    if (detailId == null) return;

    final confirmed = await AppConfirmDialog.showDelete(
      context: context,
      itemName: 'ວິຊານີ້',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(registrationServiceProvider)
          .deleteRegistrationDetail(detailId);
      if (!mounted) return;
      _registrationsDirty = true;
      AppToast.success(context, 'ລຶບວິຊາສຳເລັດ');
      await _loadExistingRegistration(_selectedStudent!.id);
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    }
  }

  DiscountModel? get _autoEligibleDiscount {
    if (_hasScholarshipFee) return null;

    if (_selectedFeeIds.length >= 3) {
      final multiSubjectDiscount = _discounts.where(
        (d) => d.discountDescription == _multiSubjectDiscountDescription,
      );
      if (multiSubjectDiscount.isNotEmpty) return multiSubjectDiscount.first;
    }

    if (_isLateRegistration) {
      final lateDiscount = _discounts.where(
        (d) => d.discountDescription == _lateRegistrationDiscountDescription,
      );
      if (lateDiscount.isNotEmpty) return lateDiscount.first;
    }

    return null;
  }

  void _applyAutoDiscount() {
    final eligible = _autoEligibleDiscount;

    if (eligible != null) {
      final isManualSelection =
          _selectedDiscountId != null &&
          _selectedDiscountId != _autoAppliedDiscountId;
      if (!isManualSelection) {
        _selectedDiscountId = eligible.discountId;
        _autoAppliedDiscountId = eligible.discountId;
      }
      return;
    }

    // ບໍ່ມີສ່ວນຫຼຸດທີ່ເຂົ້າເງື່ອນໄຂແລ້ວ — ລົບສະເພາະຄ່າທີ່ລະບົບເຄີຍເລືອກໃຫ້.
    if (_selectedDiscountId != null &&
        _selectedDiscountId == _autoAppliedDiscountId) {
      _selectedDiscountId = null;
    }
    _autoAppliedDiscountId = null;
  }

  void _setScholarshipStatus(String feeId, String status) {
    // ວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ → ປ່ຽນຜ່ານ API (ກວດ lock + recompute).
    if (_isExistingFee(feeId)) {
      _updateExistingScholarship(feeId, status);
      return;
    }
    _applyNewFeeScholarship(feeId, status);
  }

  Future<void> _applyNewFeeScholarship(String feeId, String status) async {
    // ນັກຮຽນຄົນໜຶ່ງໄດ້ຮັບທຶນໄດ້ພຽງ 1 ວິຊາເທົ່ານັ້ນ.
    if (status == 'ໄດ້ຮັບທຶນ') {
      await _clearOtherScholarships(feeId);
      if (!mounted) return;
    }
    setState(() {
      _scholarshipStatusByFee[feeId] = status;
      _applyAutoDiscount();
    });
    _fetchPreview();
  }

  /// ລ້າງສະຖານະ "ໄດ້ຮັບທຶນ" ຂອງວິຊາອື່ນທັງໝົດ (ນອກຈາກ [feeId]) —
  /// ນັກຮຽນຄົນໜຶ່ງໄດ້ຮັບທຶນໄດ້ພຽງ 1 ວິຊາເທົ່ານັ້ນ. ວິຊາທີ່ບັນທຶກໄວ້ແລ້ວຕ້ອງຜ່ານ API.
  Future<void> _clearOtherScholarships(String feeId) async {
    final othersWithScholarship = _selectedFeeIds
        .where(
          (id) => id != feeId && _scholarshipStatusByFee[id] == 'ໄດ້ຮັບທຶນ',
        )
        .toList();
    if (othersWithScholarship.isEmpty) return;

    for (final otherId in othersWithScholarship) {
      if (_isExistingFee(otherId)) {
        final detailId = _existingDetailIdByFee[otherId];
        if (detailId == null) continue;
        try {
          await ref
              .read(registrationServiceProvider)
              .updateRegistrationDetail(
                detailId,
                scholarship: apiScholarship('ບໍ່ໄດ້ຮັບທຶນ'),
              );
          _registrationsDirty = true;
        } catch (_) {
          // ຂ້າມຖ້າອັບເດດບໍ່ສຳເລັດ — ຄ່າຈະຖືກໂຫຼດຄືນຈາກ backend ພາຍຫຼັງ.
        }
      } else if (mounted) {
        setState(() => _scholarshipStatusByFee[otherId] = 'ບໍ່ໄດ້ຮັບທຶນ');
      }
    }
  }

  /// ປ່ຽນສະຖານະທຶນ ຂອງວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ (ຜ່ານ API).
  Future<void> _updateExistingScholarship(String feeId, String status) async {
    if (_isLocked) {
      AppToast.warning(context, 'ການລົງທະບຽນນີ້ຈ່າຍແລ້ວ ບໍ່ສາມາດແກ້ໄຂໄດ້');
      return;
    }
    final detailId = _existingDetailIdByFee[feeId];
    if (detailId == null) return;

    try {
      // ນັກຮຽນຄົນໜຶ່ງໄດ້ຮັບທຶນໄດ້ພຽງ 1 ວິຊາເທົ່ານັ້ນ.
      if (status == 'ໄດ້ຮັບທຶນ') {
        await _clearOtherScholarships(feeId);
        if (!mounted) return;
      }
      await ref
          .read(registrationServiceProvider)
          .updateRegistrationDetail(
            detailId,
            scholarship: apiScholarship(status),
          );
      if (!mounted) return;
      _registrationsDirty = true;
      await _loadExistingRegistration(_selectedStudent!.id);
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    }
  }

  /// ລາຍລະອຽດສະເພາະ "ວິຊາໃໝ່" (ບໍ່ນັບວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ) — ໃຊ້ສຳລັບ
  /// preview (backend ລວມວິຊາເກົ່າຈາກ DB ໃຫ້ເອງ) ແລະ ການບັນທຶກ (append).
  List<Map<String, dynamic>> _buildDetailsPayload() {
    return _selectedFeeIds.where((id) => !_isExistingFee(id)).map((feeId) {
      final scholarship = _scholarshipStatusByFee[feeId] ?? 'ບໍ່ໄດ້ຮັບທຶນ';
      return {'fee_id': feeId, 'scholarship': apiScholarship(scholarship)};
    }).toList();
  }

  /// ຖາມ backend ໃຫ້ຄຳນວນສ່ວນຫຼຸດ/ຈຳນວນເງິນ — backend ເປັນແຫຼ່ງຄວາມຈິງ.
  Future<void> _fetchPreview() async {
    final student = _selectedStudent;
    if (student == null || _selectedFeeIds.isEmpty) {
      setState(() => _preview = null);
      return;
    }

    final newDetails = _buildDetailsPayload();

    // ບໍ່ມີວິຊາໃໝ່ → ໃຊ້ຈຳນວນເງິນທີ່ບັນທຶກໄວ້ແລ້ວຂອງການລົງທະບຽນເກົ່າ.
    if (newDetails.isEmpty) {
      final existing = _existingRegistration;
      setState(() {
        _preview = existing == null
            ? null
            : RegistrationPreview(
                totalAmount: existing.totalAmount,
                discountAmount: existing.totalAmount - existing.finalAmount,
                finalAmount: existing.finalAmount,
                discountId: existing.discountId,
                discountDescription: existing.discountDescription,
              );
      });
      return;
    }

    final token = ++_previewToken;
    try {
      final preview = await ref
          .read(registrationServiceProvider)
          .previewRegistration(studentId: student.id, details: newDetails);
      // ຖ້າມີ request ໃໝ່ກວ່າແລ້ວ ໃຫ້ຖິ້ມຜົນເກົ່າ.
      if (!mounted || token != _previewToken) return;
      setState(() => _preview = preview);
    } catch (_) {
      if (!mounted || token != _previewToken) return;
      // ຄຳນວນບໍ່ສຳເລັດ — ກັບໄປໃຊ້ການປະມານຢູ່ frontend.
      setState(() => _preview = null);
    }
  }

  /// ກັບຄືນ — refresh ໜ້າ list ກ່ອນ ຖ້າມີການປ່ຽນແປງ.
  void _handleBack() {
    if (_registrationsDirty) {
      ref.read(registrationProvider.notifier).getRegistrations(allYears: true);
    }
    context.pop();
  }

  void _handleClear() {
    setState(() {
      _selectedStudent = null;
      _selectedFeeIds.clear();
      _searchQuery = '';
      _searchCtrl.clear();
      _autoRenew = false;
      _currentStep = 1;
      _selectedDiscountId = null;
      _autoAppliedDiscountId = null;
      _scholarshipStatusByFee = {};
      _preview = null;
      _previewToken++;
      _existingRegistration = null;
      _existingDetailIdByFee.clear();
    });
  }

  void _handleSave() async {
    if (_selectedStudent == null ||
        _selectedFeeIds.isEmpty ||
        _isPreparingPrint) {
      return;
    }

    final details = _buildDetailsPayload();

    // ບໍ່ມີວິຊາໃໝ່ໃຫ້ບັນທຶກ (ມີແຕ່ການແກ້ໄຂວິຊາເກົ່າ ເຊິ່ງບັນທຶກໄປແລ້ວ).
    if (details.isEmpty) {
      AppToast.warning(context, 'ບໍ່ມີວິຊາໃໝ່ໃຫ້ບັນທຶກ');
      return;
    }

    setState(() => _isPreparingPrint = true);

    // backend ຈະຄຳນວນສ່ວນຫຼຸດ/ຈຳນວນເງິນຄືນ — ຄ່າທີ່ສົ່ງໄປແມ່ນເພື່ອອ້າງອີງເທົ່ານັ້ນ.
    final request = RegistrationRequest(
      studentId: _selectedStudent!.id,
      discountId: _preview?.discountId ?? _selectedDiscountId,
      totalAmount: _displayTotalFee.toDouble(),
      finalAmount: _netFee.toDouble(),
      status: 'UNPAID',
      registrationDate: DateTime.now(),
    );

    final success = await ref
        .read(registrationProvider.notifier)
        .createRegistrationAndDetails(request, details);

    if (success && mounted) {
      final lastReg = ref.read(registrationProvider).registrations.last;
      if (mounted) {
        try {
          await showRegistrationPrintDialog(
            context: context,
            registrationId: lastReg.registrationId,
            onPreviewReady: () {
              if (mounted && _isPreparingPrint) {
                setState(() => _isPreparingPrint = false);
              }
            },
          );
        } catch (error) {
          if (mounted) {
            AppToast.error(context, error.toString());
          }
          return;
        } finally {
          if (mounted && _isPreparingPrint) {
            setState(() => _isPreparingPrint = false);
          }
        }
        _handleClear();
        ref.read(registrationProvider.notifier).getRegistrations(allYears: true);
      }
    } else if (mounted) {
      setState(() => _isPreparingPrint = false);
      final error =
          ref.read(registrationProvider).error ??
          'ບັນທຶກບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່';
      AppToast.error(context, error);
    }
  }

  Future<void> _openAddStudentDialog() async {
    if (_currentAcademicYear.isEmpty) {
      AppToast.warning(
        context,
        'ບໍ່ພົບສົກຮຽນທີ່ດໍາເນີນການ ຈຶ່ງບໍ່ສາມາດເພີ່ມການລົງທະບຽນໄດ້',
      );
      return;
    }

    final createdStudent = await showDialog<Student>(
      context: context,
      builder: (dialogContext) =>
          _AddStudentDialog(academicYear: _currentAcademicYear),
    );

    if (createdStudent != null && mounted) {
      _pickStudent(createdStudent);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(academicYearProvider.notifier).getAcademicYears();
      ref.read(studentProvider.notifier).getStudents();
      ref.read(feeProvider.notifier).getFees();
      ref.read(discountProvider.notifier).getDiscounts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(academicYearProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(
                steps: _steps,
                currentStep: _currentStep,
                onBack: _handleBack,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final wide = constraints.maxWidth >= Breakpoints.desktop;

                    final rightPanel = RightPanel(
                      step3num: 3,
                      step4num: 4,
                      step5num: 5,
                      selectedFees: _fees
                          .where((f) => _selectedFeeIds.contains(f.feeId))
                          .toList(),
                      onRemove: _toggleFee,
                      academicYear: _selectedFeeIds.isNotEmpty
                          ? _academicYearFromFees
                          : _displayAcademicYear,
                      registrationDate: _fmtDate(DateTime.now()),
                      studentName: _selectedStudent?.fullName,
                      tuitionFee: _tuitionFee,
                      totalFee: _displayTotalFee,
                      discount: _selectedDiscountAmount,
                      netFee: _netFee,
                      discounts: _selectableDiscounts,
                      selectedDiscountId: _selectedDiscountId,
                      onDiscountChanged: (v) => setState(() {
                        // ການເລືອກດ້ວຍມືຈະລົບລ້າງສະຖານະການເລືອກອັດຕະໂນມັດ.
                        _selectedDiscountId = v;
                        _autoAppliedDiscountId = null;
                      }),
                      scholarshipStatusByFee: _scholarshipStatusByFee,
                      onScholarshipChanged: (feeId, status) =>
                          _setScholarshipStatus(feeId, status),
                      autoRenew: _autoRenew,
                      onAutoRenewChanged: (v) => setState(() => _autoRenew = v),
                      canSave:
                          _currentAcademicYear.isNotEmpty &&
                          _selectedStudent != null &&
                          _selectedFeeIds.isNotEmpty,
                      discountEnabled:
                          _currentAcademicYear.isNotEmpty &&
                          _selectedStudent != null &&
                          _selectedFeeIds.isNotEmpty,
                      isLocked: _isLocked,
                      isExistingFee: _isExistingFee,
                      onSave: _handleSave,
                      onPrint: () {},
                      onCancel: _handleClear,
                    );

                    final mainContent = SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 20, wide ? 12 : 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Step1Section(
                            currentStep: _currentStep,
                            searchQuery: _searchQuery,
                            searchCtrl: _searchCtrl,
                            students: _searchResults,
                            selectedStudent: _selectedStudent,
                            onQueryChanged: (v) =>
                                setState(() => _searchQuery = v),
                            onPickStudent: _pickStudent,
                            onClearStudent: _handleClear,
                            onAddStudent: _openAddStudentDialog,
                          ),
                          const SizedBox(height: 16),
                          SelectSubjectSection(
                            allFees: _fees,
                            selectedFeeIds: _selectedFeeIds,
                            isLoading: _isLoadingFees,
                            enabled: _selectedStudent != null,
                            onToggleFee: _toggleFee,
                          ),
                          if (!wide) ...[
                            const SizedBox(height: 20),
                            rightPanel,
                          ],
                        ],
                      ),
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: mainContent),
                          Container(
                            width: 620,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEF2FF),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                              child: rightPanel,
                            ),
                          ),
                        ],
                      );
                    }
                    return mainContent;
                  },
                ),
              ),
            ],
          ),
          if (_isPreparingPrint)
            const PrintPreparationOverlay(
              icon: Icons.print_rounded,
              title: 'ກຳລັງໂຫຼດ....',
              message:
                  'ລະບົບກຳລັງດຶງຂໍ້ມູນການລົງທະບຽນ ແລະ ສ້າງ preview ໃຫ້ພ້ອມສຳລັບການພິມ',
              hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = [
      'ມັງກອນ',
      'ກຸມພາ',
      'ມີນາ',
      'ເມສາ',
      'ພຶດສະພາ',
      'ມິຖຸນາ',
      'ກໍລະກົດ',
      'ສິງຫາ',
      'ກັນຍາ',
      'ຕຸລາ',
      'ພະຈິກ',
      'ທັນວາ',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _TopBar extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final VoidCallback onBack;

  const _TopBar({
    required this.steps,
    required this.currentStep,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ກັບຄືນ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step1Section extends StatelessWidget {
  final int currentStep;
  final String searchQuery;
  final TextEditingController searchCtrl;
  final List<Student> students;
  final Student? selectedStudent;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Student> onPickStudent;
  final VoidCallback onClearStudent;
  final VoidCallback onAddStudent;

  const _Step1Section({
    required this.currentStep,
    required this.searchQuery,
    required this.searchCtrl,
    required this.students,
    required this.selectedStudent,
    required this.onQueryChanged,
    required this.onPickStudent,
    required this.onClearStudent,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      stepNum: 1,
      stepColor: AppColors.primary,
      title: 'ກວດສອບຂໍ້ມູນນັກຮຽນ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExistingStudentSearch(
            key: const ValueKey('existing'),
            searchQuery: searchQuery,
            searchCtrl: searchCtrl,
            students: students,
            selectedStudent: selectedStudent,
            onQueryChanged: onQueryChanged,
            onPickStudent: onPickStudent,
            onClearStudent: onClearStudent,
            onAddStudent: onAddStudent,
          ),
        ],
      ),
    );
  }
}

class _ExistingStudentSearch extends StatelessWidget {
  final String searchQuery;
  final TextEditingController searchCtrl;
  final List<Student> students;
  final Student? selectedStudent;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Student> onPickStudent;
  final VoidCallback onClearStudent;
  final VoidCallback onAddStudent;

  const _ExistingStudentSearch({
    super.key,
    required this.searchQuery,
    required this.searchCtrl,
    required this.students,
    required this.selectedStudent,
    required this.onQueryChanged,
    required this.onPickStudent,
    required this.onClearStudent,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    final selectionItems = students
        .map(
          (s) => StudentSelectionItem(
            id: s.id,
            fullName: s.fullName,
            school: s.school,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentSelectionList(
          students: selectionItems,
          selectedStudentId: selectedStudent?.id,
          searchQuery: searchQuery,
          searchController: searchCtrl,
          onSearchChanged: onQueryChanged,
          action: AppButton(
            label: 'ເພີ່ມນັກຮຽນ',
            icon: Icons.person_add_rounded,
            onPressed: onAddStudent,
          ),
          onSelect: (item) {
            final student = students.firstWhere((s) => s.id == item.id);
            onPickStudent(student);
          },
          onClearSearch: () {
            searchCtrl.clear();
            onQueryChanged('');
          },
        ),
        if (selectedStudent != null) ...[
          const SizedBox(height: 16),
          SelectedStudentBanner(
            student: selectedStudent!,
            onClear: onClearStudent,
          ),
        ],
      ],
    );
  }
}

class _AddStudentDialog extends ConsumerStatefulWidget {
  final String academicYear;

  const _AddStudentDialog({required this.academicYear});

  @override
  ConsumerState<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _parentPhoneFocusNode = FocusNode();
  final _schoolFocusNode = FocusNode();

  String _gender = 'ຊາຍ';
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  bool _autoValidate = false;
  bool _isSaving = false;

  List<ProvinceModel> get _provinces => ref.watch(provinceProvider).provinces;
  List<DistrictModel> get _districts =>
      ref.watch(districtProvider).filteredDistricts;
  bool get _isLoadingProvinces => ref.watch(provinceProvider).isLoading;
  bool get _isLoadingDistricts => ref.watch(districtProvider).isLoading;

  bool get _isFormValid {
    return _firstNameCtrl.text.trim().isNotEmpty &&
        _lastNameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _schoolCtrl.text.trim().isNotEmpty &&
        _selectedProvinceId != null &&
        _selectedDistrictId != null;
  }

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_onFormChanged);
    _lastNameCtrl.addListener(_onFormChanged);
    _phoneCtrl.addListener(_onFormChanged);
    _parentPhoneCtrl.addListener(_onFormChanged);
    _schoolCtrl.addListener(_onFormChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(provinceProvider.notifier).getProvinces();
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.removeListener(_onFormChanged);
    _lastNameCtrl.removeListener(_onFormChanged);
    _phoneCtrl.removeListener(_onFormChanged);
    _parentPhoneCtrl.removeListener(_onFormChanged);
    _schoolCtrl.removeListener(_onFormChanged);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _schoolCtrl.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _parentPhoneFocusNode.dispose();
    _schoolFocusNode.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() {
      _autoValidate = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedProvinceId == null || _selectedDistrictId == null) {
      AppToast.warning(context, 'ກະລຸນາເລືອກແຂວງ ແລະ ເມືອງ');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final request = StudentRequest(
      studentName: _firstNameCtrl.text.trim(),
      studentLastname: _lastNameCtrl.text.trim(),
      gender: _gender,
      studentContact: _phoneCtrl.text.trim(),
      parentsContact: _parentPhoneCtrl.text.trim(),
      school: _schoolCtrl.text.trim(),
      districtId: _selectedDistrictId!,
    );

    final success = await ref
        .read(studentProvider.notifier)
        .createStudent(request);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!success) {
      final error =
          ref.read(studentProvider).error ??
          'ບັນທຶກຂໍ້ມູນບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່';
      AppToast.error(context, error);
      return;
    }

    StudentModel? created = ref.read(studentProvider).selectedStudent;
    created ??= ref.read(studentProvider).students.lastOrNull;
    if (created == null) {
      await ref.read(studentProvider.notifier).getStudents();
      if (!mounted) return;
      created = ref.read(studentProvider).students.lastOrNull;
    }

    if (created == null || !mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດດຶງຂໍ້ມູນນັກຮຽນໃໝ່ໄດ້');
      return;
    }

    await SuccessOverlay.show(context, message: 'ບັນທຶກຂໍ້ມູນນັກຮຽນສຳເລັດ');
    if (!mounted) return;

    Navigator.of(context).pop(
      Student(
        id: created.studentId ?? '',
        name: created.studentName,
        lastname: created.studentLastname,
        gender: created.gender,
        phone: created.studentContact,
        parentsContact: created.parentsContact,
        school: created.school,
        districtId: _selectedDistrictId.toString(),
        districtName: created.districtName,
        provinceName: created.provinceName,
        academicYear: widget.academicYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'ເພີ່ມນັກຮຽນໃໝ່',
      size: AppDialogSize.large,
      onClose: () => Navigator.of(context).pop(),
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'ຍົກເລີກ',
            variant: AppButtonVariant.ghost,
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'ບັນທຶກ',
            icon: Icons.save_rounded,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: NewStudentForm(
          formKey: _formKey,
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          phoneCtrl: _phoneCtrl,
          parentPhoneCtrl: _parentPhoneCtrl,
          schoolCtrl: _schoolCtrl,
          firstNameFocusNode: _firstNameFocusNode,
          lastNameFocusNode: _lastNameFocusNode,
          phoneFocusNode: _phoneFocusNode,
          parentPhoneFocusNode: _parentPhoneFocusNode,
          schoolFocusNode: _schoolFocusNode,
          gender: _gender,
          onGenderChanged: (value) => setState(() => _gender = value ?? 'ຊາຍ'),
          onConfirm: _save,
          isFormValid: _isFormValid,
          selectedStudent: null,
          onClear: () {},
          provinces: _provinces,
          selectedProvinceId: _selectedProvinceId,
          selectedDistrictId: _selectedDistrictId,
          availableDistricts: _districts,
          onProvinceChanged: (value) async {
            setState(() {
              _selectedProvinceId = value;
              _selectedDistrictId = null;
            });
            if (value != null) {
              await ref
                  .read(districtProvider.notifier)
                  .getDistrictsByProvince(value);
            }
          },
          onDistrictChanged: (value) =>
              setState(() => _selectedDistrictId = value),
          isLoadingProvinces: _isLoadingProvinces,
          isLoadingDistricts: _isLoadingDistricts,
          showSubmitButton: false,
          wrapInForm: false,
        ),
      ),
    );
  }
}

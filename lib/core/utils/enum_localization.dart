const Map<String, String> _academicStatusLabels = {
  'ACTIVE': 'ດໍາເນີນການ',
  'ENDED': 'ສິ້ນສຸດ',
};

const Map<String, String> _genderLabels = {'MALE': 'ຊາຍ', 'FEMALE': 'ຍິງ'};

const Map<String, String> _scholarshipLabels = {
  'SCHOLARSHIP': 'ໄດ້ຮັບທຶນ',
  'NO_SCHOLARSHIP': 'ບໍ່ໄດ້ຮັບທຶນ',
};

const Map<String, String> _registrationStatusLabels = {
  'PAID': 'ຈ່າຍແລ້ວ',
  'UNPAID': 'ຍັງບໍ່ທັນຈ່າຍ',
  'PARTIAL': 'ຈ່າຍບາງສ່ວນ',
};

const Map<String, String> _paymentMethodLabels = {
  'CASH': 'ເງິນສົດ',
  'TRANSFER': 'ເງິນໂອນ',
};

const Map<String, String> _discountDescriptionLabels = {
  'MULTI_SUBJECT': 'ຮຽນ 3 ວິຊາຂຶ້ນໄປ',
  'LATE_REGISTRATION': 'ລົງທະບຽນຮຽນຊ້າ',
};

const Map<String, String> _semesterLabels = {
  'MIDTERM': 'ກາງພາກ',
  'FINAL': 'ທ້າຍພາກ',
};

const Map<String, String> _teachingStatusLabels = {
  'TEACHING': 'ຂຶ້ນສອນ',
  'ABSENT': 'ຂາດສອນ',
};

const Map<String, String> _userRoleLabels = {
  'DIRECTOR': 'ຜູ້ອຳນວຍການ',
  'TEACHER': 'ອາຈານ',
  'STAFF': 'ພະນັກງານ',
};

String _normalizeEnumValue(String value) {
  final normalized = value.trim();
  if (normalized.contains('.')) {
    return normalized.split('.').last.trim();
  }
  return normalized;
}

String _toDisplay(String? value, Map<String, String> mapping) {
  if (value == null) {
    return '';
  }
  final normalized = _normalizeEnumValue(value);
  return mapping[normalized] ?? normalized;
}

String _toApi(String? value, Map<String, String> mapping, {String? fallback}) {
  if (value == null) {
    return fallback ?? '';
  }
  final normalized = _normalizeEnumValue(value);
  for (final entry in mapping.entries) {
    if (entry.key == normalized || entry.value == normalized) {
      return entry.key;
    }
  }
  return fallback ?? normalized;
}

Map<String, int> _localizeMapKeys(
  Map<String, int> values,
  Map<String, String> mapping,
) {
  return {
    for (final entry in values.entries)
      _toDisplay(entry.key, mapping): entry.value,
  };
}

String localizeAcademicStatus(String? value) =>
    _toDisplay(value, _academicStatusLabels);

String apiAcademicStatus(String? value) =>
    _toApi(value, _academicStatusLabels, fallback: 'ACTIVE');

bool isActiveAcademicStatus(String? value) =>
    apiAcademicStatus(value) == 'ACTIVE';

String localizeGender(String? value) => _toDisplay(value, _genderLabels);

String apiGender(String? value) =>
    _toApi(value, _genderLabels, fallback: 'MALE');

String localizeScholarship(String? value) =>
    _toDisplay(value, _scholarshipLabels);

String apiScholarship(String? value) =>
    _toApi(value, _scholarshipLabels, fallback: 'NO_SCHOLARSHIP');

String localizeRegistrationStatus(String? value) =>
    _toDisplay(value, _registrationStatusLabels);

String apiRegistrationStatus(String? value) =>
    _toApi(value, _registrationStatusLabels, fallback: 'UNPAID');

String localizePaymentMethod(String? value) =>
    _toDisplay(value, _paymentMethodLabels);

String apiPaymentMethod(String? value) =>
    _toApi(value, _paymentMethodLabels, fallback: 'CASH');

String localizeDiscountDescription(String? value) =>
    _toDisplay(value, _discountDescriptionLabels);

String apiDiscountDescription(String? value) =>
    _toApi(value, _discountDescriptionLabels, fallback: 'MULTI_SUBJECT');

String localizeSemester(String? value) => _toDisplay(value, _semesterLabels);

String apiSemester(String? value) =>
    _toApi(value, _semesterLabels, fallback: 'MIDTERM');

String localizeTeachingStatus(String? value) =>
    _toDisplay(value, _teachingStatusLabels);

Map<String, int> localizeTeachingStatusStats(Map<String, int> values) =>
    _localizeMapKeys(values, _teachingStatusLabels);

String apiTeachingStatus(String? value) =>
    _toApi(value, _teachingStatusLabels, fallback: 'TEACHING');

String localizeUserRole(String? value) => _toDisplay(
  value == null
      ? null
      : switch (_normalizeEnumValue(value).toUpperCase()) {
          'ADMIN' => 'DIRECTOR',
          final normalized => normalized,
        },
  _userRoleLabels,
);

String apiUserRole(String? value) {
  final normalized = _toApi(value, _userRoleLabels, fallback: 'DIRECTOR');
  if (normalized == 'ADMIN') {
    return 'DIRECTOR';
  }
  return normalized;
}

bool isTeacherRole(String? value) => apiUserRole(value) == 'TEACHER';

Map<String, int> localizeGenderStats(Map<String, int> values) =>
    _localizeMapKeys(values, _genderLabels);

Map<String, int> localizeScholarshipStats(Map<String, int> values) =>
    _localizeMapKeys(values, _scholarshipLabels);

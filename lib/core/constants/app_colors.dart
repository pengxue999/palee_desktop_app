import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryDark = Color(0xFF1E40AF);

  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryForeground = Color(0xFFFFFFFF);
  static const Color secondaryLight = Color(0xFFE0E7FF);

  static const Color background = Color(0xFFF8FAFC);
  static const Color foreground = Color(0xFF0F172A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F172A);

  static const Color muted = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);

  static const Color accent = Color(0xFFF1F5F9);
  static const Color accentForeground = Color(0xFF0F172A);

  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color destructiveLight = Color(0xFFFEE2E2);

  static const Color success = Color(0xFF16A34A);
  static const Color successForeground = Color(0xFFFFFFFF);
  static const Color successLight = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFD97706);
  static const Color warningForeground = Color(0xFFFFFFFF);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color border = Color(0xFFE2E8F0);
  static const Color input = Color(0xFFE2E8F0);
  static const Color ring = Color(0xFF3B82F6);

  static const List<Color> chartColors = [
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  static const Map<String, (Color, Color)> gradeColors = {
    'A': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'B': (Color(0xFFDBEAFE), Color(0xFF2563EB)),
    'C': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'D': (Color(0xFFFFEDD5), Color(0xFFEA580C)),
    'F': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
  };

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoForeground = Color(0xFFFFFFFF);

  static const Map<String, (Color, Color)> statusBackgroundColors = {
    'active': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'inactive': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'pending': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'completed': (Color(0xFFDBEAFE), Color(0xFF2563EB)),
    'paid': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'unpaid': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'partial': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'ໂສດ': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'ສົມລົດ': (Color(0xFFDBEAFE), Color(0xFF2563EB)),
    'ຢ່າຮ້າງ': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'ລົງທະບຽນແລ້ວ': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'ຢຸດຮຽນ': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'ຈົບແລ້ວ': (Color(0xFFDBEAFE), Color(0xFF2563EB)),
    'ອາຈານສອນປັດຈຸບັນ': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'ອອກ': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'ລາພັກ': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'ຈ່າຍແລ້ວ': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'ຍັງບໍ່ທັນຈ່າຍ': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'ຍັງບໍ່ຈ່າຍ': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'ຈ່າຍບາງສ່ວນ': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'ສຳເລັດ': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'ໃຊ້ງານ': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'ປິດ': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'ລໍຖ້າ': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'ເງິນສົດ': (Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'ເງິນໂອນ': (Color(0xFFDBEAFE), Color(0xFF2563EB)),
    'ໄດ້ຮັບທຶນ': (Color(0xFFDBEAFE), Color(0xFF2563EB)),
  };

  static const Map<String, Color> statusColors = {
    'active': Color(0xFF16A34A),
    'inactive': Color(0xFFDC2626),
    'pending': Color(0xFFD97706),
    'completed': Color(0xFF2563EB),
    'paid': Color(0xFF16A34A),
    'unpaid': Color(0xFFDC2626),
    'partial': Color(0xFFD97706),
    'ໂສດ': Color(0xFF16A34A),
    'ສົມລົດ': Color(0xFF2563EB),
    'ຢ່າຮ້າງ': Color(0xFFDC2626),
    'ລົງທະບຽນແລ້ວ': Color(0xFF16A34A),
    'ຢຸດຮຽນ': Color(0xFFDC2626),
    'ຈົບແລ້ວ': Color(0xFF2563EB),
    'ອາຈານສອນປັດຈຸບັນ': Color(0xFF16A34A),
    'ອອກ': Color(0xFFDC2626),
    'ລາພັກ': Color(0xFFD97706),
    'ຈ່າຍແລ້ວ': Color(0xFF16A34A),
    'ຍັງບໍ່ທັນຈ່າຍ': Color(0xFFDC2626),
    'ຍັງບໍ່ຈ່າຍ': Color(0xFFDC2626),
    'ຈ່າຍບາງສ່ວນ': Color(0xFFD97706),
    'ສຳເລັດ': Color(0xFF16A34A),
    'ໃຊ້ງານ': Color(0xFF16A34A),
    'ປິດ': Color(0xFFDC2626),
    'ລໍຖ້າ': Color(0xFFD97706),
    'ໄດ້ຮັບທຶນ': Color(0xFF2563EB),
  };
}

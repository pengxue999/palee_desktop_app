class FormatUtils {
  FormatUtils._();

  static String formatKip(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₭';
  }

  static String formatCurrency(double value) {
    final intValue = value.toInt();
    return '${intValue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₭';
  }

  static String formatKipM(int value) {
    return '${(value / 1000000).toStringAsFixed(1)}M ₭';
  }

  static String formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  static String getCurrentDateLao() {
    final now = DateTime.now();
    final dayNames = [
      '',
      'ຈັນ',
      'ອັງຄານ',
      'ພຸດ',
      'ພະຫັດ',
      'ສຸກ',
      'ເສົາ',
      'ອາທິດ',
    ];
    final monthNames = [
      '',
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

    final dayName = dayNames[now.weekday];
    final day = now.day;
    final month = monthNames[now.month];
    final year = now.year;

    return 'ວັນ$dayName, ວັນທີ $day $month $year';
  }

  static String getDayNameLao(int weekday) {
    final dayNames = [
      '',
      'ຈັນ',
      'ອັງຄານ',
      'ພຸດ',
      'ພະຫັດ',
      'ສຸກ',
      'ເສົາ',
      'ອາທິດ',
    ];
    return dayNames[weekday];
  }

  static String getMonthNameLao(int month) {
    final monthNames = [
      '',
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
    return monthNames[month];
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

class ModernDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const ModernDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<ModernDatePicker> createState() => ModernDatePickerState();
}

class ModernDatePickerState extends State<ModernDatePicker> {
  late DateTime _focusedMonth;
  late DateTime _selected;

  static const _monthsLao = [
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
  static const _daysLao = [
    'ຈັນ',
    'ອັງຄານ',
    'ພຸດ',
    'ພະຫັດ',
    'ສຸກ',
    'ເສົາ',
    'ອາທິດ',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _focusedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _prevMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
  });

  List<DateTime?> _buildDays() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startOffset = (first.weekday - 1) % 7;
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final cells = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    return cells;
  }

  bool _isSelected(DateTime d) =>
      d.year == _selected.year &&
      d.month == _selected.month &&
      d.day == _selected.day;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isDisabled(DateTime d) =>
      d.isBefore(widget.firstDate) || d.isAfter(widget.lastDate);

  @override
  Widget build(BuildContext context) {
    final days = _buildDays();
    final canPrev = DateTime(
      _focusedMonth.year,
      _focusedMonth.month - 1,
    ).isAfter(DateTime(widget.firstDate.year, widget.firstDate.month - 1));
    final canNext = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
    ).isBefore(DateTime(widget.lastDate.year, widget.lastDate.month + 1));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ເລືອກວັນທີ, ເດືອນ ແລະ ປີ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selected.day.toString().padLeft(2, '0')} '
                    '${_monthsLao[_selected.month - 1]} '
                    '${_selected.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  _NavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: canPrev ? _prevMonth : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_monthsLao[_focusedMonth.month - 1]}  ${_focusedMonth.year}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ),
                  _NavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: canNext ? _nextMonth : null,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _daysLao
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: days.map((d) {
                  if (d == null) return const SizedBox();
                  return _DayCell(
                    date: d,
                    isSelected: _isSelected(d),
                    isToday: _isToday(d),
                    isDisabled: _isDisabled(d),
                    onTap: () => setState(() => _selected = d),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TextBtn(
                    label: 'ຍົກເລີກ',
                    onTap: () => Navigator.of(context).pop(),
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  _TextBtn(
                    label: 'ຢືນຢັນ',
                    onTap: () => Navigator.of(context).pop(_selected),
                    color: AppColors.primary,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.isSelected;
    final t = widget.isToday;
    final dis = widget.isDisabled;

    Color bgColor;
    if (s) {
      bgColor = AppColors.primary;
    } else if (_hovered && !dis) {
      bgColor = AppColors.primary.withValues(alpha: 0.15);
    } else if (t) {
      bgColor = AppColors.primaryLight;
    } else {
      bgColor = Colors.transparent;
    }

    Color textColor;
    if (s) {
      textColor = Colors.white;
    } else if (dis) {
      textColor = AppColors.border;
    } else if (_hovered) {
      textColor = AppColors.primary;
    } else if (t) {
      textColor = AppColors.primaryDark;
    } else {
      textColor = AppColors.foreground;
    }

    return MouseRegion(
      cursor: dis ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: dis ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: _hovered && !dis && !s
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '${widget.date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: s ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered && enabled
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: enabled ? AppColors.primary : AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _TextBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool bold;
  const _TextBtn({
    required this.label,
    required this.onTap,
    required this.color,
    this.bold = false,
  });

  @override
  State<_TextBtn> createState() => _TextBtnState();
}

class _TextBtnState extends State<_TextBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: widget.bold ? FontWeight.w700 : FontWeight.w500,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('-', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

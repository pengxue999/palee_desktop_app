import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/teacher_model.dart';

class TeacherDetailCard extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherDetailCard({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ຂໍ້ມູນອາຈານ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Divider(),
          const SizedBox(height: 12),
          _infoRow(label: 'ຊື່ ແລະ ນາມສະກຸນ', value: teacher.fullName),

          _infoRow(
            label: 'ເພດ',
            value: teacher.gender.isEmpty ? '-' : teacher.gender,
          ),
          _infoRow(
            label: 'ເບີ',
            value: teacher.teacherContact.isEmpty
                ? '-'
                : teacher.teacherContact,
          ),
          _infoRow(
            label: 'ເມືອງ',
            value: teacher.districtName.isEmpty ? '-' : teacher.districtName,
          ),
          _infoRow(
            label: 'ແຂວງ',
            value: teacher.provinceName.isEmpty ? '-' : teacher.provinceName,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

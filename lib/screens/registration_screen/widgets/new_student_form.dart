import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/models/district_model.dart';
import 'package:palee_elite_training_center/models/province_model.dart';
import 'package:palee_elite_training_center/screens/registration_screen/new_registration_screen.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/select_student_banner.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/app_text_field.dart';

class NewStudentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController parentPhoneCtrl;
  final TextEditingController schoolCtrl;
  final FocusNode? firstNameFocusNode;
  final FocusNode? lastNameFocusNode;
  final FocusNode? phoneFocusNode;
  final FocusNode? parentPhoneFocusNode;
  final FocusNode? schoolFocusNode;
  final String gender;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onConfirm;
  final bool isFormValid;
  final Student? selectedStudent;
  final VoidCallback onClear;
  final List<ProvinceModel> provinces;
  final int? selectedProvinceId;
  final int? selectedDistrictId;
  final List<DistrictModel> availableDistricts;
  final ValueChanged<int?> onProvinceChanged;
  final ValueChanged<int?> onDistrictChanged;
  final bool isLoadingProvinces;
  final bool isLoadingDistricts;
  final bool showSubmitButton;
  final bool wrapInForm;

  const NewStudentForm({
    super.key,
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.parentPhoneCtrl,
    required this.schoolCtrl,
    this.firstNameFocusNode,
    this.lastNameFocusNode,
    this.phoneFocusNode,
    this.parentPhoneFocusNode,
    this.schoolFocusNode,
    required this.gender,
    required this.onGenderChanged,
    required this.onConfirm,
    required this.isFormValid,
    required this.selectedStudent,
    required this.onClear,
    required this.provinces,
    required this.selectedProvinceId,
    required this.selectedDistrictId,
    required this.availableDistricts,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.isLoadingProvinces,
    required this.isLoadingDistricts,
    this.showSubmitButton = true,
    this.wrapInForm = true,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedStudent != null) {
      return SelectedStudentBanner(student: selectedStudent!, onClear: onClear);
    }

    provinces.firstWhere(
      (p) => p.provinceId == selectedProvinceId,
      orElse: () => const ProvinceModel(provinceId: 0, provinceName: ''),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'ຊື່',
                hint: 'ປ້ອນຊື່ນັກຮຽນ',
                controller: firstNameCtrl,
                focusNode: firstNameFocusNode,
                textInputAction: TextInputAction.next,
                required: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'ກະລຸນາປ້ອນຊື່' : null,
                onFieldSubmitted: (_) => lastNameFocusNode?.requestFocus(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'ນາມສະກຸນ',
                hint: 'ປ້ອນນາມສະກຸນ',
                controller: lastNameCtrl,
                focusNode: lastNameFocusNode,
                textInputAction: TextInputAction.next,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'ກະລຸນາປ້ອນນາມສະກຸນ'
                    : null,
                onFieldSubmitted: (_) => phoneFocusNode?.requestFocus(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        AppDropdown<String>(
          label: 'ເພດ',
          required: true,
          hint: 'ເລືອກເພດ',
          value: gender,
          items: ['ຊາຍ', 'ຍິງ']
              .map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
              .toList(),
          onChanged: onGenderChanged,
        ),

        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'ເບີໂທນັກຮຽນ',
                hint: '020XXXXXXXX',
                controller: phoneCtrl,
                focusNode: phoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                required: true,
                digitOnly: DigitOnly.integer,
                maxLength: phoneCtrl.text.startsWith('020') ? 11 : 10,
                onFieldSubmitted: (_) => parentPhoneFocusNode?.requestFocus(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'ເບີໂທຜູ້ປົກຄອງ',
                hint: '020XXXXXXXX ຫຼື 030XXXXXXX',
                controller: parentPhoneCtrl,
                focusNode: parentPhoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                digitOnly: DigitOnly.integer,
                maxLength: parentPhoneCtrl.text.startsWith('020') ? 11 : 10,
                onFieldSubmitted: (_) => schoolFocusNode?.requestFocus(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        AppTextField(
          label: 'ໂຮງຮຽນ',
          hint: 'ປ້ອນຊື່ໂຮງຮຽນ (ຕົວຢ່າງ: ມສ ວຽງຈັນ, ມສ ຈອມເພັດ)',
          controller: schoolCtrl,
          focusNode: schoolFocusNode,
          textInputAction: TextInputAction.next,
          required: true,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'ກະລຸນາປ້ອນໂຮງຮຽນ' : null,
        ),

        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: isLoadingProvinces
                  ? const Center(
                      child: SizedBox(
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : AppDropdown<int>(
                      label: 'ແຂວງ',
                      required: true,
                      hint: 'ເລືອກແຂວງ',
                      value: selectedProvinceId,
                      items: provinces
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.provinceId,
                              child: Text(p.provinceName),
                            ),
                          )
                          .toList(),
                      onChanged: onProvinceChanged,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLoadingDistricts
                  ? const Center(
                      child: SizedBox(
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : AppDropdown<int>(
                      label: 'ເມືອງ',
                      required: true,
                      hint: 'ເລືອກເມືອງ',
                      value: selectedDistrictId,
                      items: availableDistricts
                          .map(
                            (d) => DropdownMenuItem<int>(
                              value: d.districtId,
                              child: Text(d.districtName),
                            ),
                          )
                          .toList(),
                      onChanged: selectedProvinceId != null
                          ? onDistrictChanged
                          : null,
                      enabled:
                          selectedProvinceId != null &&
                          availableDistricts.isNotEmpty,
                    ),
            ),
          ],
        ),

        if (showSubmitButton) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: IntrinsicWidth(
              child: AppButton(
                label: 'ບັນທຶກ',
                icon: Icons.save,
                onPressed: isFormValid ? onConfirm : null,
              ),
            ),
          ),
        ],
      ],
    );

    if (!wrapInForm) {
      return content;
    }

    return Form(key: formKey, child: content);
  }
}

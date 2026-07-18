import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppEditableDropdown extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController controller;
  final List<String> options;
  final bool required;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AppEditableDropdown({
    super.key,
    this.label,
    this.hint,
    required this.controller,
    required this.options,
    this.required = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      required: required,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      suffixIcon: PopupMenuButton<String>(
        tooltip: 'ເລືອກຫົວໜ່ວຍ',
        enabled: enabled && options.isNotEmpty,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        onSelected: (value) {
          controller.text = value;
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
          onChanged?.call(value);
        },
        itemBuilder: (context) {
          return options
              .map(
                (option) =>
                    PopupMenuItem<String>(value: option, child: Text(option)),
              )
              .toList();
        },
      ),
    );
  }
}

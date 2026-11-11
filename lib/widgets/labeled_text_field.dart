import 'package:flutter/material.dart';
import 'package:food_pos/theme/app_themes.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final bool? isObsecure;
  final int? maxLine;

  final FormFieldValidator<String>? validator;
  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.controller,
    this.isObsecure,
    this.decoration,
    this.maxLine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(label, style: mediumTextStyle.copyWith(color: blackColor)),
        SizedBox(height: 5),
        TextFormField(
          obscureText: isObsecure ?? false,
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLine ?? 1,
          style: regularTextStyle.copyWith(color: blackColor),
          validator: validator,
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          decoration:
              decoration ??
              textFieldDecoration.copyWith(
                hintText: hint,
                hintStyle: hintTextStyle,
              ),
        ),
      ],
    );
  }
}

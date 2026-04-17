import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.validator,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

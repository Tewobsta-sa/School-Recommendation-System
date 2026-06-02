import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../core/theme.dart';

/// A password text field with visibility toggle (eye icon)
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final List<String>? autofillHints;
  final InputDecoration? decoration;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.validator,
    this.autofocus = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.decoration,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
        onPressed: _toggleVisibility,
      ),
    );

    final mergedDecoration = widget.decoration != null
        ? defaultDecoration.copyWith(
            contentPadding: widget.decoration!.contentPadding,
          )
        : defaultDecoration;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      decoration: mergedDecoration,
      validator: widget.validator,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/ThemeProvider.dart';
import 'constants/colors.dart';

/// Reusable TextField Widget with Dark & Light Mode Support
class ReusableTextField extends StatefulWidget {
  final String labelText;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const ReusableTextField({
    super.key,
    required this.labelText,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<ReusableTextField> createState() => _ReusableTextFieldState();
}

class _ReusableTextFieldState extends State<ReusableTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<DarkModeProvider>().isDarkMode;

    final Color textColor = isDarkMode ? Colors.white : carbonBlack;
    final Color labelColor = isDarkMode ? Colors.grey[300]! : carbonBlack;
    final Color borderColor = isDarkMode ? Colors.grey[600]! : lightGray;
    final Color fillColor = isDarkMode ? lightGrayBlack : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        cursorColor: brandGreen,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          labelText: widget.labelText,
          labelStyle: TextStyle(color: labelColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: brandGreen, width: 1.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: borderColor),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: isDarkMode ? Colors.grey[400] : mediumGray,
            ),
            onPressed: _toggleVisibility,
          )
              : null,
        ),
      ),
    );
  }
}

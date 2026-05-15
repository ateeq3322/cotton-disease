import 'package:flutter/material.dart';

import 'constants/colors.dart';
import 'constants/fonts.dart';

Widget reusableButton({
  required String text,
  required VoidCallback onPressed,
  Color color = brandGreen,
  Color textColor = white,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded as per image
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: buttonText(text: text, color: textColor, align: TextAlign.center),
      ),
    ),
  );
}
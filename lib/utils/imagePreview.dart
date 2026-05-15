// lib/utils/imagePreview.dart

import 'dart:io';
import 'package:cotton_disease/Provider/ThemeProvider.dart';
import 'package:cotton_disease/utils/constants/colors.dart';
import 'package:cotton_disease/utils/constants/fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeProvider>(context).isDarkMode;
    final Color scaffold = isDark ? darkBlack : screenBg;
    final Color appbar = isDark ? lightGrayBlack : white;
    final Color buttonTextColor = isDark ? white : grayBlack;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: scaffold,
      appBar: AppBar(
        backgroundColor: appbar,
        title: appBarTitle(text: 'Preview', color: buttonTextColor),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  // Retake → go back without returning any image
                  Navigator.pop(context, null);
                },
                child: buttonText(text: 'Retake', color: buttonTextColor),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  // Return the selected/captured image path
                  Navigator.pop(context, imagePath);
                },
                child: buttonText(
                    text: 'Use this Photo', color: buttonTextColor),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
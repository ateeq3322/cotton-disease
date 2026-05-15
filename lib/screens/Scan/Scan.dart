// lib/screens/scan.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ Detection Result Screen/detection_result_screen.dart';
import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';
import '../../utils/Camera.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  @override
  Widget build(BuildContext context) {
    final darkMode = Provider.of<DarkModeProvider>(context).isDarkMode;

    final backgroundColor = darkMode ? darkBlack : white;
    final appBarColor = darkMode ? lightGrayBlack : white;
    final textColor = darkMode ? white : carbonBlack;
    final subtitleColor = darkMode ? lightGray : mediumGray;
    final overlayColor =
    darkMode ? Colors.black.withOpacity(0.4) : Colors.black26;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: heading(
          text: 'AI Scan',
          color: textColor,
          align: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/green_leaf.jpg',
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: overlayColor,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.crop_free, size: 30, color: white),
                    bodyText(
                      text: 'Align cotton leaf within the frame',
                      color: white,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: green500),
                const SizedBox(width: 8),
                bodyText(
                  text:
                  'For best results, center a healthy cotton leaf clearly in the frame.',
                  color: subtitleColor,
                  maxWidth: 300,
                  align: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final imagePath = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraUIScreen(),
                  ),
                );

                if (imagePath != null && mounted) {
                  final file = File(imagePath);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetectionResultScreen(imageFile: file),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 120),
                backgroundColor: brandGreen,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              child: buttonText(text: 'Detect Now', color: white),
            ),
          ],
        ),
      ),
    );
  }
}
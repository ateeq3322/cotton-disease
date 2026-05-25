import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cotton_disease/MainPage.dart';
import 'package:cotton_disease/Provider/NotificationProvider.dart';
import 'package:cotton_disease/screens/onBoardingScreen/onBoardingScreen.dart';
import 'package:cotton_disease/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Provider/ThemeProvider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    initializeTheme();
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    // Scale animation: grows from 0.8 to 1.0
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Rotation animation: slight rotation effect
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Navigate to the next screen after 3 seconds
    Timer(Duration(seconds: 2), () async {
      final sharedPreference = await SharedPreferences.getInstance();
      final _isGetStarted = sharedPreference.getBool('isGetStarted') ?? false;
      if (_isGetStarted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GetStarted()),
        );
      }
    });
  }

  Future<void> initializeTheme() async {
    final preference = await SharedPreferences.getInstance();
    final themeProvider = Provider.of<DarkModeProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final isDarkTheme = preference.getBool('isDarkMode') ?? true;
    themeProvider.toggleMode(isDarkTheme);
    final isNotificationAllowed = preference.getBool('isNotificationOn') ?? false;
    notificationProvider.toggleNotification(isNotificationAllowed);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Asset Image
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Image.asset(
                      'assets/images/cotton.png',
                      // Replace with your image path
                      height: 150,
                      width: 150,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // Text Below Image
            Center(
              child: AnimatedTextKit(
                isRepeatingAnimation: false,
                animatedTexts: [
                  ColorizeAnimatedText(
                    "Crop Guard",
                    textAlign: TextAlign.center,
                    textStyle: GoogleFonts.exo2(fontSize: 28),
                    colors: [
                      white,
                      warningYellow,
                      errorRed,
                      darkPurple,
                      darkBlue,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

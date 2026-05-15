import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../BotttomNavBar/bottomNavBar.dart';
import '../../Provider/ThemeProvider.dart';
import '../../Services/EmailAuthService.dart';
import '../../Services/GoogleAuthenticationService.dart';
import '../../utils/button.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';
import '../../utils/textfield.dart';
import '../Signup/Signup.dart';

class LoginScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final auth = GoogleAuthService();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<DarkModeProvider>().isDarkMode;

    // 🎨 Theme-based Colors
    final background = isDarkMode ? darkBlack : screenBg;
    final cardColor = isDarkMode ? lightGrayBlack : cardBg;
    final textColor = isDarkMode ? white : grayBlack;
    final subTextColor = isDarkMode ? lightGray : mediumGray;
    final dividerColor = isDarkMode ? darkGray : lightGray;
    final buttonColor = isDarkMode ? pureGreen : brandGreen;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 60),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Column(
                  children: [
                    appBarTitle(
                      text: "Sign In",
                      color: textColor,
                      align: TextAlign.center,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    bodyText(
                      text: "Hi! Welcome back, you've been missed",
                      color: subTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ReusableTextField(
                  labelText: "Email",
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                ReusableTextField(
                  labelText: "Password",
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    alignment: AlignmentGeometry.topRight,
                    padding: EdgeInsets.zero,
                  ),
                  child: buttonText(text: "Forgot Password?",color: buttonColor),
                  onPressed: () async {
                    if (_emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: cardSubtitle(text: "Please enter your email to reset password.")),
                      );
                      return;
                    }
                    try {
                      await AuthService().sendPasswordReset(_emailController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: cardSubtitle(text: "Password reset link sent! Check your email.")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error sending reset email: $e")),
                      );
                    }
                  },
                ),
                reusableButton(
                  text: "Sign In",
                  color: buttonColor,
                  onPressed: () async{
                    if (_formKey.currentState!.validate()) {
                      final user = await AuthService().login(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );

                      if (user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => BottomNavBar()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: cardSubtitle(text: "Login Successful!")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: cardSubtitle(text: "Login Failed! Check Email/Password")),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: dividerColor,
                        thickness: 1,
                        height: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: bodyText(
                        text: "or sign in with",
                        color: subTextColor,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: dividerColor,
                        thickness: 1,
                        height: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? lightGrayBlack : carbonBlack,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final user = await auth.signInWithGoogle();
                    if (user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BottomNavBar()),
                        );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: cardSubtitle(text: 'Welcome, ${FirebaseAuth.instance.currentUser!.displayName}!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: cardSubtitle(text: "Login Failed")),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/google.png",
                        width: 35,
                        height: 35,
                      ),
                      buttonText(text: "Google", color:white),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    bodyText(
                      text: "Don't have an account?",
                      color: textColor,
                      weight: FontWeight.w500,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpScreen(),
                          ),
                        );
                      },
                      child: bodyText(
                        text: "Sign Up",
                        color: buttonColor,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

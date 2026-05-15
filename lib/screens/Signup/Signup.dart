import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../BotttomNavBar/bottomNavBar.dart';
import '../../Provider/ThemeProvider.dart';
import '../../Services/EmailAuthService.dart';
import '../../utils/button.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';
import '../../utils/textfield.dart';
import '../Login/Login.dart';

class SignUpScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _validatePasswords(BuildContext context) {
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Passwords do not match!")));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;

    final background = isDark ? darkBlack : screenBg;
    final textColor = isDark ? white : grayBlack;
    final subTextColor = isDark ? lightGray : mediumGray;
    final buttonColor = isDark ? brandGreen : brandGreen;

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
                      text: "Create Account",
                      color: textColor,
                      align: TextAlign.center,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    bodyText(
                      text:
                          "Fill in your info below or register with your social accounts",
                      color: subTextColor,
                      align: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 🧍 Name
                ReusableTextField(
                  labelText: "Name",
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                /// ✉️ Email
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

                /// 🔒 Password
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

                const SizedBox(height: 10),

                /// 🔒 Confirm Password
                ReusableTextField(
                  labelText: "Confirm Password",
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your confirm password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                /// ✅ Sign Up Button
                reusableButton(
                  text: "Sign Up",
                  color: buttonColor,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (!_validatePasswords(context)) return;

                      final user = await AuthService().signUp(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );

                      if (user != null) {
                        // inform user to verify email
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Account created! Please verify your email.",
                            ),
                          ),
                        );
                        // optionally navigate to login screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Signup failed! Try again.")),
                        );
                      }
                    }
                  },
                ),

                const SizedBox(height: 20),

                /// 👤 Already have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    bodyText(
                      text: "Already have an account?",
                      color: subTextColor,
                      weight: FontWeight.w500,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: bodyText(
                        text: "Sign In",
                        color: brandGreen,
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

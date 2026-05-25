import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cotton_disease/screens/Login/Login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants/colors.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {

  _images(String url, double width, double height) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            offset: Offset(20, 30),
            spreadRadius: 20,
            blurRadius: 20,
          ),
        ],
      ),
      child: Image.asset(
        "assets/images/$url.png", width: width, height: height,),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [splashBg, onboardingBg],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(top: 10, left: 20),
                      child: _images("verified_cotton", 100.0, 100.0)
                  ),
                  SizedBox(height: 20,),
                  Center(child: _images("cotton", 200.0, 200.0),),
                  SizedBox(height: 10,),
                  Center(
                    child: AnimatedTextKit(
                        isRepeatingAnimation: false,
                        animatedTexts: [
                          ColorizeAnimatedText(
                              "COTTON\nDISEASE AI",
                              textAlign: TextAlign.center,
                              textStyle: GoogleFonts.exo2(fontSize: 28),
                              colors: [
                                white,
                                warningYellow,
                                errorRed,
                                darkPurple,
                                darkBlue
                              ]
                          )
                        ]
                    ),
                  ),
                  SizedBox(height: 10,),
                  Center(child: _images("raw_cotton", 100.0, 100.0),),
                  SizedBox(height: 20,),
                  Center(
                    child: AnimatedTextKit(
                        isRepeatingAnimation: false,
                        animatedTexts: [
                          TyperAnimatedText(
                            textAlign: TextAlign.center,
                            "Scan Your Cotton Leaves Now\n AI Detects Diseases to Save Your Harvest",
                            textStyle: GoogleFonts.exo2(fontSize: 14,color: white),
                          ),
                        ]
                    ),
                  ),
                  SizedBox(height: 50,),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                            ),
                            backgroundColor: grayBlack,
                            padding: EdgeInsets.symmetric(
                                horizontal: 100, vertical: 14)
                        ),
                        onPressed: () async {
                          final sharedPreference = await SharedPreferences
                              .getInstance();
                          sharedPreference.setBool('isGetStarted', true);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                        },
                        child: AnimatedTextKit(
                            isRepeatingAnimation: false,
                            animatedTexts: [
                              ColorizeAnimatedText(
                                  speed: Duration(milliseconds: 200),
                                  "SignUp Now",
                                  textStyle: GoogleFonts.exo2(fontSize: 14),
                                  colors: [
                                    white,
                                    white,
                                    warningYellow,
                                    errorRed,
                                    darkPurple,
                                    darkBlue
                                  ]
                              ),
                              ColorizeAnimatedText(
                                  "Login Now",
                                  textStyle:  GoogleFonts.exo2(fontSize: 14),
                                  colors: [
                                    white,
                                    white,
                                    warningYellow,
                                    errorRed,
                                    darkPurple,
                                    darkBlue
                                  ]
                              ),
                              ColorizeAnimatedText(
                                  "Get Started",
                                  textStyle:  GoogleFonts.exo2(fontSize: 14),
                                  colors: [
                                    white,
                                    white,
                                    warningYellow,
                                    errorRed,
                                    darkPurple,
                                    darkBlue
                                  ]
                              ),
                            ]
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
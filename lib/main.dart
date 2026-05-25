import 'package:cotton_disease/Provider/NotificationProvider.dart';
import 'package:cotton_disease/Provider/ThemeProvider.dart';
import 'package:cotton_disease/Provider/WeatherProvider.dart';
import 'package:cotton_disease/Provider/detection_provider.dart';
import 'package:cotton_disease/screens/SplashScreen/SplashScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp
  ]);
  runApp(CropGuard());
}

class CropGuard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => DarkModeProvider()),
          ChangeNotifierProvider(create: (context) => NotificationProvider()),
          ChangeNotifierProvider(create: (context) => DetectionProvider()),
          ChangeNotifierProvider(create: (context) => WeatherProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        )
    );
  }
}


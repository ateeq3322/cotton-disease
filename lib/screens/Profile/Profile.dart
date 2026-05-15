import 'package:cotton_disease/Provider/ThemeProvider.dart';
import 'package:cotton_disease/screens/Login/Login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Services/EmailAuthService.dart';
import '../../utils/ProfileWidget.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';
import '../../utils/infoTile.dart';
import '../../utils/switchButton.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isNotificationOn = true;

  Future<void> savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<DarkModeProvider>();
    final isDark = themeProvider.isDarkMode;

    final Color bgColor = isDark ? darkBlack : screenBg;
    final Color textColor = isDark ? white : chocolateBlack;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDark ? lightGrayBlack : white,
        title: appBarTitle(
          text: "Profile & Settings",
          color: isDark ? white : grayBlack,
        ),
        iconTheme: IconThemeData(color: isDark ? white : grayBlack),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              ); // back to login page
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              /// 🧑‍🌾 Profile Card
              const ProfileCard(),

              const SizedBox(height: 30),

              /// ⚙️ App Settings
              heading(
                text: "App Settings",
                color: textColor,
                align: TextAlign.left,
              ),
              const SizedBox(height: 15),

              /// 🌙 Dark Mode
              SwitchTile(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                subtitle: "Toggle app’s visual theme",
                value: isDark,
                onChanged: (val) {
                  savePreference('isDarkMode', val);
                  context.read<DarkModeProvider>().toggleMode(val);
                },
              ),

              /// 🔔 Notifications
              SwitchTile(
                icon: Icons.notifications_active_outlined,
                title: "Notifications",
                subtitle: "Receive alerts for crop health",
                value: isNotificationOn,
                onChanged: (val) => setState(() => isNotificationOn = val),
              ),

              const SizedBox(height: 25),

              /// 🧾 App Information
              heading(
                text: "App Information",
                color: textColor,
                align: TextAlign.left,
              ),
              const SizedBox(height: 15),

              InfoTile(title: "About CottonSense", onTap: () {}),
              InfoTile(title: "Privacy Policy", onTap: () {}),
              InfoTile(title: "Terms of Service", onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

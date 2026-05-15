import 'package:cotton_disease/screens/HomeScreen/HomeScreen.dart';
import 'package:cotton_disease/screens/Knowledge/knowledge.dart';
import 'package:cotton_disease/screens/Profile/Profile.dart';
import 'package:cotton_disease/screens/Report/Reports.dart';
import 'package:cotton_disease/screens/Scan/Scan.dart';
import 'package:cotton_disease/screens/Weather/Weather.dart';
import 'package:cotton_disease/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Provider/ThemeProvider.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    Scan(),
    Reports(),
    KnowledgeHub(),
    WeatherScreen(),
    Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkModeProvider>(context).isDarkMode;

    final backgroundColor = isDarkMode ? lightGrayBlack : white;
    final activeColor = isDarkMode ? pureGreen : brandGreen;
    final inactiveColor = isDarkMode ? lightGray : mediumGray;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.exo2(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: activeColor,
        ),
        unselectedLabelStyle: GoogleFonts.exo2(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: inactiveColor,
        ),
        selectedIconTheme: IconThemeData(color: activeColor, size: 24),
        unselectedIconTheme: IconThemeData(color: inactiveColor, size: 20),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 20),
            activeIcon: Icon(Icons.home, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, size: 20),
            activeIcon: Icon(Icons.camera_alt, size: 24),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart, size: 20),
            activeIcon: Icon(Icons.insert_chart, size: 24),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, size: 20),
            activeIcon: Icon(Icons.book, size: 24),
            label: 'Knowledge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny, size: 20),
            activeIcon: Icon(Icons.wb_sunny, size: 24),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 20),
            activeIcon: Icon(Icons.person, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

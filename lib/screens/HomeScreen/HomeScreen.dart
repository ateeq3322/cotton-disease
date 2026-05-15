import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../Provider/ThemeProvider.dart';
import '../../utils/Camera.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _capturedImagePath; // store captured image path

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeProvider>(context).isDarkMode;

    // 🎨 Colors adapt automatically
    final Color bgColor = isDark ? darkBlack : screenBg;
    final Color textColor = isDark ? white : carbonBlack;
    final Color cardColor = isDark ? lightGrayBlack : cardBg;
    final Color secondaryText = isDark ? Colors.white70 : mediumGray;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧩 Header
            Container(
              width: MediaQuery.of(context).size.width,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      "assets/images/cotton_field.jpg",
                      colorBlendMode: BlendMode.color,
                      filterQuality: FilterQuality.high,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: appBarTitle(text: "Cotton Sense AI", color: white),
                        ),
                        SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _animation.value,
                              child: bodyText(
                                text:
                                    "Scan Your Cotton Leaves Now – AI Detects Diseases to Save Your Harvest",
                                color: white,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.9,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 🚀 Hero Section
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [green100, brandGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 120,
                    child: Image.asset(
                      'assets/images/verified_cotton.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: carbonBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      onPressed: () async {
                        final imagePath = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraUIScreen()),
                        );

                        // return image path from camera screen
                        if (imagePath != null && mounted) {
                          setState(() {
                            _capturedImagePath = imagePath;
                          });
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, color: white, size: 20),
                          SizedBox(width: 8),
                          buttonText(text: "Start Scan", color: white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 📊 Status Cards
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusCard("Healthy", successGreen, "95%"),
                  _buildStatusCard("Warning", warningYellow, "3%"),
                  _buildStatusCard("Disease", errorRed, "2%"),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 🌾 Tips
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading(text: "Tips", color: brandGreen),
                  SizedBox(height: 10),
                  bodyText(
                    text:
                        "1. Scan leaves early in the morning for best results.\n2. Use clean water to keep plants healthy.\n3. Apply recommended treatments promptly.",
                    color: textColor,
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: buttonText(
                      text: "View All",
                      color: brandGreen,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 📁 My Reports
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [green100, brandGreen.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading(text: "My Reports", color: white),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.report, color: white, size: 30),
                    title: bodyText(
                      text: "Healthy Cotton - Oct 20",
                      color: white,
                    ),
                    subtitle: bodyText(
                      text: "No issues detected",
                      color: Colors.white70,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: white,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.report_problem, color: white, size: 30),
                    title: bodyText(text: "Boll Rot - Oct 21", color: white),
                    subtitle: bodyText(
                      text: "Treatment needed",
                      color: Colors.white70,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: white,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: buttonText(
                      text: "View All Reports",
                      color: white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // ☀️ Weather Widget
            Container(
              padding: EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: lightOrange, size: 30),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bodyText(text: "Weather", color: textColor),
                          heading(text: "28°C", color: textColor),
                        ],
                      ),
                    ],
                  ),
                  bodyText(text: "11:01 AM, Oct 22", color: secondaryText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, Color color, String percentage) {
    return Expanded(
      child: Container(
        height: 100,
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == "Healthy"
                  ? Icons.check_circle
                  : title == "Warning"
                  ? Icons.warning
                  : Icons.error,
              color: white,
              size: 30,
            ),
            SizedBox(height: 8),
            buttonText(text: title, color: white),
            SizedBox(height: 4),
            cardSubtitle(text: percentage, color: white),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/ThemeProvider.dart';
import 'constants/colors.dart';
import 'constants/fonts.dart';

/// 📋 Info Tile Component
class InfoTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const InfoTile({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;

    return InkWell(
      onTap: onTap,
      splashColor: brandGreen.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? lightGray.withOpacity(0.2)
                  : lightGray.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            bodyText(
              text: title,
              color: isDark ? white : carbonBlack,
              weight: FontWeight.w500,
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? lightGray : mediumGray,
            ),
          ],
        ),
      ),
    );
  }
}

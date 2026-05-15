import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/ThemeProvider.dart';
import 'constants/colors.dart';
import 'constants/fonts.dart';

/// 🔘 Switch Tile Component
class SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
        children: [
          Icon(
            icon,
            color: brandGreen,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bodyText(
                  text: title,
                  color: isDark ? white : carbonBlack,
                  weight: FontWeight.w600,
                ),
                cardSubtitle(
                  text: subtitle,
                  color: isDark ? lightGray : mediumGray,
                ),
              ],
            ),
          ),
          Switch(
            activeThumbColor: white,
            activeTrackColor: brandGreen,
            inactiveThumbColor: isDark ? darkGray : mediumGray,
            inactiveTrackColor:
            isDark ? lightGrayBlack : Colors.grey.shade300,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

import 'package:cotton_disease/utils/button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

class Reports extends StatelessWidget {
  const Reports({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeProvider>(context).isDarkMode;

    final bgColor = isDark ? darkBlack : screenBg;
    final textColor = isDark ? white : carbonBlack;
    final subTextColor = isDark ? lightGray : mediumGray;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? lightGrayBlack : white,
        centerTitle: true,
        title: appBarTitle(
          text: "Knowledge Hub",
          color: isDark ? white : carbonBlack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading(
                    text: "Cotton Leaf Curl Virus",
                    align: TextAlign.left,
                    color: textColor,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      bodyText(
                        text: "Confidence Level ",
                        color: subTextColor,
                        weight: FontWeight.w500,
                      ),
                      bodyText(
                        text: "92%",
                        color: successGreen,
                        weight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🔹 Leaf Image
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage("assets/images/green_leaf.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Recommended Treatment
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: heading(
                text: "Recommended Treatment",
                align: TextAlign.left,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 Steps
            ...[
              {
                "title": "Step 1: Early Detection & Isolation",
                "desc":
                    "Regularly inspect cotton plants for early symptoms. Immediately remove and destroy infected plants to prevent spread.",
              },
              {
                "title": "Step 2: Vector Control",
                "desc":
                    "Manage whitefly populations, as they are the primary vectors. Use appropriate insecticides or biological controls.",
              },
              {
                "title": "Step 3: Crop Residue Management",
                "desc":
                    "Properly dispose of or incorporate crop residues after harvest to reduce host plants for the virus and vectors.",
              },
            ].map((step) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bodyText(
                      text: step["title"]!,
                      color: textColor,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 4),
                    bodyText(
                      text: step["desc"]!,
                      color: subTextColor,
                      weight: FontWeight.w400,
                    ),
                  ],
                ),
              );
            }),

            // 🔹 Pesticide Recommendation Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? darkGreen.withOpacity(0.3) : green50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? pureGreen : green300,
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: brandGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: cardSubtitle(
                        text: "Imidacloprid 20% SL",
                        color: white,
                        weight: FontWeight.w600,
                        align: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 8),
                    bodyText(
                      text:
                          "A systemic insecticide effective against whiteflies. Apply as foliar spray or soil drench.",
                      color: subTextColor,
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Bottom Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: reusableButton(
                text: 'View Knowledge Hub',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

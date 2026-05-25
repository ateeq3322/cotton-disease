import 'package:cotton_disease/Provider/ThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';
import 'LearnMoreScreen.dart';

class KnowledgeHub extends StatelessWidget {
  const KnowledgeHub({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeProvider>(context).isDarkMode;

    final List<Map<String, String>> diseases = [
      {
        "name": "Cotton Leaf Curl Virus",
        "desc":
        "Causes upward curling of leaves, vein swelling, and stunted growth. A major threat to cotton yields.",
        "icon": "🪴"
      },
      {
        "name": "Bollworm Infestation",
        "desc":
        "Larvae feed on cotton bolls, causing damage to lint and seeds. Early detection is crucial.",
        "icon": "🐛"
      },
      {
        "name": "Bacterial Blight",
        "desc":
        "Angular leaf spots, boll rot, and stem cankers are common symptoms. Worsens in humid conditions.",
        "icon": "🧫"
      },
      {
        "name": "Fusarium Wilt",
        "desc":
        "Vascular wilting, yellowing, and eventual plant death. Often observed in older plants.",
        "icon": "🛡️"
      },
      {
        "name": "Alternaria Leaf Spot",
        "desc":
        "Dark, concentric spots on leaves. Can lead to premature defoliation and yield loss.",
        "icon": "🌿"
      },
      {
        "name": "Root Rot Complex",
        "desc":
        "Caused by various fungi, leading to root decay, wilting, and reduced nutrient uptake.",
        "icon": "🌱"
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? darkBlack : screenBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? darkBlack : white,
        centerTitle: true,
        title: appBarTitle(
          text: "Knowledge Hub",
          color: isDark ? white : carbonBlack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: diseases.length,
          itemBuilder: (context, index) {
            final disease = diseases[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? lightGrayBlack : white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟢 Icon Circle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? darkGreen : green50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? green500 : green300, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          disease["icon"]!,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 📝 Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bodyText(
                              text: disease["name"]!,
                              color: isDark ? white : carbonBlack,
                              weight: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            bodyText(
                              text: disease["desc"]!,
                              color: isDark ? lightGray : mediumGray,
                              weight: FontWeight.w400,
                            ),
                            const SizedBox(height: 8),

                            // Learn More Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LearnMoreScreen(disease: allDiseases[index]),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                  isDark ? darkGreen : green50,
                                  foregroundColor:
                                  isDark ? white : brandGreen,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color:
                                      isDark ? green500 : brandGreen,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    buttonText(
                                      text: "Learn More",
                                      color:
                                      isDark ? white : brandGreen,
                                      weight: FontWeight.w600,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: isDark
                                          ? white
                                          : brandGreen,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

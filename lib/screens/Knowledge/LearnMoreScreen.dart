import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cotton_disease/Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

// ─────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────

class DiseaseDetail {
  final String name;
  final String icon;
  final String shortDesc;
  final String overview;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatments;
  final String severity; // "Low" | "Medium" | "High"

  const DiseaseDetail({
    required this.name,
    required this.icon,
    required this.shortDesc,
    required this.overview,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.severity,
  });
}

// ─────────────────────────────────────────
// FULL DATA (KnowledgeHub mein bhi yahi use karo)
// ─────────────────────────────────────────

final List<DiseaseDetail> allDiseases = [
  DiseaseDetail(
    name: "Cotton Leaf Curl Virus",
    icon: "🪴",
    shortDesc:
    "Causes upward curling of leaves, vein swelling, and stunted growth. A major threat to cotton yields.",
    overview:
    "Cotton Leaf Curl Virus (CLCuV) is one of the most destructive viral diseases affecting cotton in Pakistan and India. It is transmitted by whiteflies (Bemisia tabaci) and can cause up to 100% yield loss in severe cases.",
    symptoms: [
      "Upward or downward curling of leaves",
      "Thickening and darkening of leaf veins",
      "Enations (leaf-like outgrowths) on undersides",
      "Stunted plant growth",
      "Reduced boll formation",
    ],
    causes: [
      "Whitefly (Bemisia tabaci) infestation — primary vector",
      "Use of infected planting material",
      "High temperatures favoring whitefly reproduction",
      "Monoculture farming without crop rotation",
    ],
    treatments: [
      "Apply imidacloprid or thiamethoxam-based insecticides to control whiteflies",
      "Remove and destroy infected plants immediately",
      "Use CLCuV-resistant or tolerant cotton varieties",
      "Maintain field hygiene and remove weed hosts",
      "Introduce natural predators like Encarsia formosa",
    ],
    severity: "High",
  ),
  DiseaseDetail(
    name: "Bollworm Infestation",
    icon: "🐛",
    shortDesc:
    "Larvae feed on cotton bolls, causing damage to lint and seeds. Early detection is crucial.",
    overview:
    "Bollworm (Helicoverpa armigera) is a polyphagous pest that attacks cotton bolls directly. It can cause 30–80% yield loss if unmanaged. Bt cotton varieties have reduced but not eliminated the threat.",
    symptoms: [
      "Circular entry holes in cotton bolls",
      "Frass (caterpillar droppings) visible near holes",
      "Premature boll shedding",
      "Internal lint and seed damage",
      "Visible larvae inside opened bolls",
    ],
    causes: [
      "Helicoverpa armigera moth egg-laying on young bolls",
      "Pectinophora gossypiella (pink bollworm) secondary infestations",
      "Absence of natural predators due to pesticide overuse",
      "Resistance developed against Bt toxins in some regions",
    ],
    treatments: [
      "Apply spinosad or emamectin benzoate at early larval stage",
      "Use pheromone traps for adult moth monitoring",
      "Spray neem-based biopesticides as an early intervention",
      "Practice inter-cropping to reduce pest pressure",
      "Scout fields twice weekly during boll development",
    ],
    severity: "High",
  ),
  DiseaseDetail(
    name: "Bacterial Blight",
    icon: "🧫",
    shortDesc:
    "Angular leaf spots, boll rot, and stem cankers are common symptoms. Worsens in humid conditions.",
    overview:
    "Bacterial Blight, caused by Xanthomonas citri pv. malvacearum, can affect all above-ground plant parts. It spreads rapidly in warm, humid, and rainy conditions and can persist in crop debris for years.",
    symptoms: [
      "Angular, water-soaked leaf spots turning brown",
      "Black, sunken stem cankers (black arm)",
      "Boll rot with dark, greasy lesions",
      "Leaf yellowing and premature drop",
      "Infected seedlings collapse at soil level",
    ],
    causes: [
      "Xanthomonas citri pv. malvacearum bacteria",
      "Spread through rain splash and wind-driven rain",
      "Infected seeds from previous season",
      "High humidity and temperature above 28°C",
    ],
    treatments: [
      "Treat seeds with copper oxychloride before planting",
      "Apply copper-based bactericides as foliar spray",
      "Avoid overhead irrigation; use drip irrigation",
      "Use certified blight-resistant cotton varieties",
      "Remove and burn infected plant debris after harvest",
    ],
    severity: "Medium",
  ),
  DiseaseDetail(
    name: "Fusarium Wilt",
    icon: "🛡️",
    shortDesc:
    "Vascular wilting, yellowing, and eventual plant death. Often observed in older plants.",
    overview:
    "Fusarium oxysporum f. sp. vasinfectum causes vascular wilt in cotton. The fungus colonizes the water-conducting tissues, cutting off the plant's water supply. It survives in soil for many years.",
    symptoms: [
      "Yellowing of lower leaves progressing upward",
      "Brown or reddish discoloration of vascular tissue",
      "Wilting despite adequate soil moisture",
      "Stunted growth in young plants",
      "Dark streaks visible when stem is cut open",
    ],
    causes: [
      "Fusarium oxysporum fungus in infected soil",
      "Root-knot nematode co-infection (worsens severity)",
      "Poor drainage and waterlogged conditions",
      "Continuous cotton cultivation without rotation",
    ],
    treatments: [
      "Solarize soil before planting in severely infected fields",
      "Apply Trichoderma viride as a biocontrol agent",
      "Treat seeds with carbendazim or thiram",
      "Practice 3–4 year crop rotation with non-host crops",
      "Plant certified wilt-resistant cotton varieties",
    ],
    severity: "High",
  ),
  DiseaseDetail(
    name: "Alternaria Leaf Spot",
    icon: "🌿",
    shortDesc:
    "Dark, concentric spots on leaves. Can lead to premature defoliation and yield loss.",
    overview:
    "Alternaria macrospora and A. alternata cause this fungal disease. While it rarely kills plants outright, severe infections cause significant defoliation, weakening the plant and reducing photosynthesis.",
    symptoms: [
      "Circular to irregular dark brown spots with concentric rings",
      "Yellow halo around lesions on young leaves",
      "Lesions merge on heavily infected leaves",
      "Premature leaf fall (defoliation)",
      "Spots also appear on petioles and stems",
    ],
    causes: [
      "Alternaria macrospora / A. alternata fungal spores",
      "Spread by wind and rain splash",
      "High relative humidity (>80%) and moderate temperatures",
      "Stressed or nutrient-deficient plants are more susceptible",
    ],
    treatments: [
      "Spray mancozeb or iprodione at first sign of spots",
      "Ensure balanced potassium and calcium fertilization",
      "Avoid water stress — consistent irrigation schedule",
      "Remove and destroy heavily infected leaves",
      "Apply preventive fungicide sprays during humid periods",
    ],
    severity: "Medium",
  ),
  DiseaseDetail(
    name: "Root Rot Complex",
    icon: "🌱",
    shortDesc:
    "Caused by various fungi, leading to root decay, wilting, and reduced nutrient uptake.",
    overview:
    "Root Rot Complex involves multiple soilborne pathogens including Rhizoctonia solani, Pythium spp., and Thielaviopsis basicola. Early-season infections are most damaging, often causing seedling death before establishment.",
    symptoms: [
      "Dark, water-soaked lesions on roots and lower stem",
      "Reddish-brown discoloration of root cortex",
      "Wilting and poor stand establishment",
      "Stunted seedlings with sparse root systems",
      "Black root rot (Thielaviopsis): dark, brittle roots",
    ],
    causes: [
      "Multiple soilborne fungi (Rhizoctonia, Pythium, Thielaviopsis)",
      "Excessive soil moisture and poor drainage",
      "Cool soil temperatures at planting",
      "Compacted soils restricting root growth",
    ],
    treatments: [
      "Improve field drainage with raised beds or ridges",
      "Apply metalaxyl or azoxystrobin seed treatments",
      "Delay planting until soil temperature exceeds 20°C",
      "Use deep plowing to break compaction layers",
      "Apply Bacillus subtilis biocontrol products at planting",
    ],
    severity: "Medium",
  ),
];

// ─────────────────────────────────────────
// UPDATED KnowledgeHub (navigation added)
// ─────────────────────────────────────────

class KnowledgeHub extends StatelessWidget {
  const KnowledgeHub({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeProvider>(context).isDarkMode;

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
          itemCount: allDiseases.length,
          itemBuilder: (context, index) {
            final disease = allDiseases[index];
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
                      // Icon Circle
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
                          disease.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bodyText(
                              text: disease.name,
                              color: isDark ? white : carbonBlack,
                              weight: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            bodyText(
                              text: disease.shortDesc,
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
                                      builder: (_) =>
                                          LearnMoreScreen(disease: disease),
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
                                      color: isDark ? green500 : brandGreen,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    buttonText(
                                      text: "Learn More",
                                      color: isDark ? white : brandGreen,
                                      weight: FontWeight.w600,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: isDark ? white : brandGreen,
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

// ─────────────────────────────────────────
// LEARN MORE SCREEN
// ─────────────────────────────────────────

class LearnMoreScreen extends StatelessWidget {
  final DiseaseDetail disease;

  const LearnMoreScreen({super.key, required this.disease});

  Color _severityColor(String severity, bool isDark) {
    switch (severity) {
      case "High":
        return isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F);
      case "Medium":
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      default:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF388E3C);
    }
  }

  Color _severityBg(String severity, bool isDark) {
    switch (severity) {
      case "High":
        return isDark
            ? const Color(0xFFD32F2F).withOpacity(0.15)
            : const Color(0xFFFFEBEE);
      case "Medium":
        return isDark
            ? const Color(0xFFF57C00).withOpacity(0.15)
            : const Color(0xFFFFF3E0);
      default:
        return isDark
            ? const Color(0xFF388E3C).withOpacity(0.15)
            : const Color(0xFFE8F5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeProvider>(context).isDarkMode;
    final Color cardBg = isDark ? lightGrayBlack : white;
    final Color textPrimary = isDark ? white : carbonBlack;
    final Color textSecondary = isDark ? lightGray : mediumGray;
    final Color sectionHeaderColor = isDark ? Colors.green.shade400 : brandGreen;

    return Scaffold(
      backgroundColor: isDark ? darkBlack : screenBg,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? darkBlack : brandGreen,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      const Color(0xFF1B5E20),
                      const Color(0xFF0A0A0A),
                    ]
                        : [
                      const Color(0xFF2E7D32),
                      const Color(0xFF66BB6A),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Icon bubble
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(disease.icon,
                          style: const TextStyle(fontSize: 36)),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        disease.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _severityBg(disease.severity, isDark),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _severityColor(disease.severity, isDark)
                                .withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color:
                                _severityColor(disease.severity, isDark),
                                size: 15),
                            const SizedBox(width: 5),
                            Text(
                              "${disease.severity} Severity",
                              style: TextStyle(
                                color:
                                _severityColor(disease.severity, isDark),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Overview Card
                  _SectionCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    icon: Icons.info_outline_rounded,
                    iconColor: sectionHeaderColor,
                    title: "Overview",
                    child: Text(
                      disease.overview,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Symptoms Card
                  _SectionCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    icon: Icons.monitor_heart_outlined,
                    iconColor: const Color(0xFFE53935),
                    title: "Symptoms",
                    child: _BulletList(
                      items: disease.symptoms,
                      bulletColor: const Color(0xFFE53935),
                      textColor: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Causes Card
                  _SectionCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    icon: Icons.biotech_outlined,
                    iconColor: const Color(0xFFF57C00),
                    title: "Causes",
                    child: _BulletList(
                      items: disease.causes,
                      bulletColor: const Color(0xFFF57C00),
                      textColor: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Treatment Card
                  _SectionCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    icon: Icons.healing_outlined,
                    iconColor: sectionHeaderColor,
                    title: "Treatment & Prevention",
                    child: _NumberedList(
                      items: disease.treatments,
                      numberColor: sectionHeaderColor,
                      textColor: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.cardBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color bulletColor;
  final Color textColor;

  const _BulletList({
    required this.items,
    required this.bulletColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: bulletColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NumberedList extends StatelessWidget {
  final List<String> items;
  final Color numberColor;
  final Color textColor;

  const _NumberedList({
    required this.items,
    required this.numberColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final text = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: numberColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  "$idx",
                  style: TextStyle(
                    color: numberColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
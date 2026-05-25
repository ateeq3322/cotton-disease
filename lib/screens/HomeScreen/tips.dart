// lib/screens/Tips/tips_screen.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Tips Screen
// Local data, category filter, dark/light themed
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  TipCategory? _selectedCategory; // null = All
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  List<CropTip> get _filteredTips {
    if (_selectedCategory == null) return allTips;
    return allTips
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  void _selectCategory(TipCategory? cat) {
    if (_selectedCategory == cat) return;
    setState(() => _selectedCategory = cat);
    _fadeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;

    final Color bgColor = isDark ? darkBlack : screenBg;
    final Color cardColor = isDark ? lightGrayBlack : cardBg;
    final Color textColor = isDark ? white : carbonBlack;
    final Color subText = isDark ? Colors.white60 : mediumGray;
    final Color surfaceColor = isDark ? const Color(0xff1e2a24) : green50;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppBar ──────────────────────────────────────
            _buildAppBar(context, isDark, textColor, subText),

            // ── Category chips ───────────────────────────────
            _buildCategoryBar(isDark, cardColor),

            // ── Tips count label ─────────────────────────────
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                '${_filteredTips.length} tip${_filteredTips.length == 1 ? '' : 's'}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: subText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // ── Tips list ────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _filteredTips.length,
                  itemBuilder: (context, index) {
                    return _TipCard(
                      tip: _filteredTips[index],
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subText: subText,
                      surfaceColor: surfaceColor,
                      index: index,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, bool isDark, Color textColor, Color subText) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop Tips',
                style: GoogleFonts.saira(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Best practices for healthy cotton',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: subText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: brandGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: brandGreen.withOpacity(0.3)),
            ),
            child: Text(
              '${allTips.length} total',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: brandGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(bool isDark, Color cardColor) {
    final categories = [null, ...TipCategory.values];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final label = cat == null ? 'All' : cat.label;
          final icon = cat == null ? Icons.apps_rounded : cat.icon;

          return GestureDetector(
            onTap: () => _selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? brandGreen : cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? brandGreen
                      : (isDark
                      ? Colors.white12
                      : Colors.black.withOpacity(0.08)),
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: brandGreen.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? white
                        : (isDark ? Colors.white54 : mediumGray),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? white
                          : (isDark ? Colors.white70 : darkGray),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tip Card
// ─────────────────────────────────────────────────────────────
class _TipCard extends StatefulWidget {
  final CropTip tip;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subText;
  final Color surfaceColor;
  final int index;

  const _TipCard({
    required this.tip,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subText,
    required this.surfaceColor,
    required this.index,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  Color get _categoryAccent {
    switch (widget.tip.category) {
      case TipCategory.scanning:
        return primaryBlue;
      case TipCategory.watering:
        return const Color(0xff29B6F6);
      case TipCategory.treatment:
        return errorRed;
      case TipCategory.prevention:
        return brandGreen;
      case TipCategory.harvest:
        return warningYellow;
      case TipCategory.soil:
        return const Color(0xff8D6E63);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggle,
          splashColor: _categoryAccent.withOpacity(0.08),
          highlightColor: _categoryAccent.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _categoryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.tip.icon,
                        color: _categoryAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tip.title,
                            style: GoogleFonts.saira(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.textColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _categoryAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.tip.category.label,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: _categoryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Expand chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.subText,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                // ── Expandable description ──────────────────
                SizeTransition(
                  sizeFactor: _expandAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _categoryAccent.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.tip.description,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: widget.subText,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


enum TipCategory {
  scanning,
  watering,
  treatment,
  prevention,
  harvest,
  soil,
}

extension TipCategoryExt on TipCategory {
  String get label {
    switch (this) {
      case TipCategory.scanning:
        return 'Scanning';
      case TipCategory.watering:
        return 'Watering';
      case TipCategory.treatment:
        return 'Treatment';
      case TipCategory.prevention:
        return 'Prevention';
      case TipCategory.harvest:
        return 'Harvest';
      case TipCategory.soil:
        return 'Soil';
    }
  }

  IconData get icon {
    switch (this) {
      case TipCategory.scanning:
        return Icons.document_scanner_rounded;
      case TipCategory.watering:
        return Icons.water_drop_rounded;
      case TipCategory.treatment:
        return Icons.medical_services_rounded;
      case TipCategory.prevention:
        return Icons.shield_rounded;
      case TipCategory.harvest:
        return Icons.agriculture_rounded;
      case TipCategory.soil:
        return Icons.grass_rounded;
    }
  }
}

class CropTip {
  final String title;
  final String description;
  final TipCategory category;
  final IconData icon;

  const CropTip({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });
}

const List<CropTip> allTips = [
  // ── Scanning ──────────────────────────────────────────────
  CropTip(
    title: 'Scan in the Morning',
    description:
    'Scan leaves early in the morning (6–9 AM) when light is natural and diffused. Avoid harsh midday sun which causes glare and reduces detection accuracy.',
    category: TipCategory.scanning,
    icon: Icons.wb_twilight_rounded,
  ),
  CropTip(
    title: 'Clean the Lens First',
    description:
    'Wipe your camera lens before scanning. Dust or smudges can reduce image clarity and lead to misclassification of disease severity.',
    category: TipCategory.scanning,
    icon: Icons.camera_outlined,
  ),
  CropTip(
    title: 'Scan Multiple Leaves',
    description:
    'Never rely on a single scan. Scan at least 3–5 different leaves from various parts of the plant to get an accurate disease distribution picture.',
    category: TipCategory.scanning,
    icon: Icons.layers_rounded,
  ),
  CropTip(
    title: 'Keep the Leaf Flat',
    description:
    'Hold the leaf flat and close to the camera (10–15 cm). Curled or folded leaves reduce model accuracy significantly.',
    category: TipCategory.scanning,
    icon: Icons.crop_free_rounded,
  ),

  // ── Watering ──────────────────────────────────────────────
  CropTip(
    title: 'Water at the Base',
    description:
    'Always water at the base of the plant, not on the leaves. Wet leaves promote fungal diseases like Fusarium Wilt and Bacterial Blight.',
    category: TipCategory.watering,
    icon: Icons.water_drop_rounded,
  ),
  CropTip(
    title: 'Avoid Overwatering',
    description:
    'Cotton roots are susceptible to rot. Water only when the topsoil (5 cm) is dry. Overwatering weakens immunity and increases disease vulnerability.',
    category: TipCategory.watering,
    icon: Icons.opacity_rounded,
  ),
  CropTip(
    title: 'Use Clean Water',
    description:
    'Contaminated irrigation water can carry bacterial pathogens. Use clean, tested water sources whenever possible, especially for young plants.',
    category: TipCategory.watering,
    icon: Icons.water_rounded,
  ),

  // ── Treatment ─────────────────────────────────────────────
  CropTip(
    title: 'Act Within 48 Hours',
    description:
    'Once a disease is detected, apply the recommended treatment within 48 hours. Delays allow disease to spread to neighboring plants rapidly.',
    category: TipCategory.treatment,
    icon: Icons.timer_rounded,
  ),
  CropTip(
    title: 'Follow Dosage Exactly',
    description:
    'Over-applying pesticides or fungicides can burn the plant and create chemical resistance. Always follow the recommended dosage on the label.',
    category: TipCategory.treatment,
    icon: Icons.science_rounded,
  ),
  CropTip(
    title: 'Remove Infected Leaves',
    description:
    'For Bacterial Blight and Curl Virus, physically remove and burn heavily infected leaves. Do not compost them — this spreads disease.',
    category: TipCategory.treatment,
    icon: Icons.delete_sweep_rounded,
  ),
  CropTip(
    title: 'Spray in the Evening',
    description:
    'Apply foliar sprays in the evening to avoid evaporation and reduce risk of leaf burn. This improves chemical absorption effectiveness.',
    category: TipCategory.treatment,
    icon: Icons.nights_stay_rounded,
  ),

  // ── Prevention ────────────────────────────────────────────
  CropTip(
    title: 'Rotate Crops Annually',
    description:
    'Do not plant cotton in the same field for consecutive years. Crop rotation breaks the disease cycle for soil-borne pathogens like Fusarium Wilt.',
    category: TipCategory.prevention,
    icon: Icons.refresh_rounded,
  ),
  CropTip(
    title: 'Control Whitefly Populations',
    description:
    'Cotton Curl Virus is spread by whiteflies. Use yellow sticky traps and neem-based sprays to keep whitefly populations under control.',
    category: TipCategory.prevention,
    icon: Icons.bug_report_rounded,
  ),
  CropTip(
    title: 'Maintain Proper Spacing',
    description:
    'Crowded plants restrict airflow and create humidity pockets where fungal diseases thrive. Maintain recommended row spacing of 75–90 cm.',
    category: TipCategory.prevention,
    icon: Icons.space_bar_rounded,
  ),
  CropTip(
    title: 'Inspect Weekly',
    description:
    'Walk your field every week and scan random leaves. Early detection prevents minor infections from becoming field-wide outbreaks.',
    category: TipCategory.prevention,
    icon: Icons.search_rounded,
  ),

  // ── Harvest ───────────────────────────────────────────────
  CropTip(
    title: 'Harvest at Right Moisture',
    description:
    'Harvest cotton when bolls are fully open and moisture content is below 12%. Wet harvests lead to storage mold and quality loss.',
    category: TipCategory.harvest,
    icon: Icons.agriculture_rounded,
  ),
  CropTip(
    title: 'Clean Equipment Between Fields',
    description:
    'Disease pathogens cling to harvesting equipment. Clean and disinfect between field sections to prevent cross-contamination.',
    category: TipCategory.harvest,
    icon: Icons.construction_rounded,
  ),

  // ── Soil ──────────────────────────────────────────────────
  CropTip(
    title: 'Test Soil pH Before Planting',
    description:
    'Cotton thrives in soil with pH 6.0–7.5. Acidic or alkaline soils stress plants and make them more vulnerable to disease infection.',
    category: TipCategory.soil,
    icon: Icons.biotech_rounded,
  ),
  CropTip(
    title: 'Add Organic Matter',
    description:
    'Compost and organic matter improve soil drainage and microbial diversity, which naturally suppresses soil-borne pathogens.',
    category: TipCategory.soil,
    icon: Icons.eco_rounded,
  ),
];
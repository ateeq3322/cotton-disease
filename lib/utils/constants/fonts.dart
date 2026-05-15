import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

double getResponsiveFontSize(double baseSize) {
  final logicalWidth = WidgetsBinding
      .instance.platformDispatcher.views.first.physicalSize.width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  const referenceWidth = 411.0; // Standard width for mobile (e.g., iPhone 12)
  return baseSize * (logicalWidth / referenceWidth);
}

/// 1. APP BAR TITLE - Saira (Large & Bold)
Widget appBarTitle({
  required String text,
  Color color = white,
  FontWeight weight = FontWeight.w600,
  TextAlign align = TextAlign.center,
  double maxWidth = double.infinity,
  double size = 24,
  int? maxLines,
  TextOverflow overflow = TextOverflow.visible,
}) {
  final fontSize = getResponsiveFontSize(size);
  return Container(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      text,
      style: GoogleFonts.saira(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 0.5,
      ),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}

/// 2. MAIN HEADING - Saira (Medium Bold)
Widget heading({
  required String text,
  Color color = chocolateBlack,
  FontWeight weight = FontWeight.w600,
  TextAlign align = TextAlign.center,
  double maxWidth = double.infinity,
  int? maxLines,
  TextOverflow overflow = TextOverflow.ellipsis,
}) {
  final fontSize = getResponsiveFontSize(22);
  return Container(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      text,
      style: GoogleFonts.saira(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 0.3,
      ),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}

/// 3. BODY TEXT - Montserrat (Clean & Readable)
Widget bodyText({
  required String text,
  Color color = carbonBlack,
  FontWeight weight = FontWeight.w400,
  TextAlign align = TextAlign.left,
  double maxWidth = double.infinity,
  int? maxLines,
  TextOverflow overflow = TextOverflow.visible,
}) {
  final fontSize = getResponsiveFontSize(16);
  return Container(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      text,
      style: GoogleFonts.montserrat(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.4,
      ),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}

/// 4. BUTTON TEXT - Railway (Bold & Clear)
Widget buttonText({
  required String text,
  Color color = white,
  FontWeight weight = FontWeight.w700,
  TextAlign align = TextAlign.center,
  double maxWidth = double.infinity,
  int? maxLines,
  TextOverflow overflow = TextOverflow.visible,
}) {
  final fontSize = getResponsiveFontSize(18);
  return Container(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      text,
      style: GoogleFonts.raleway(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 1.0,
      ),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}

/// 5. CARD SUBTITLE - Quicksand (Soft & Friendly)
Widget cardSubtitle({
  required String text,
  Color color = green500,
  FontWeight weight = FontWeight.w500,
  TextAlign align = TextAlign.center,
  double maxWidth = double.infinity,
  int? maxLines,
  TextOverflow overflow = TextOverflow.visible,
}) {
  final fontSize = getResponsiveFontSize(14);
  return Container(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      text,
      style: GoogleFonts.quicksand(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 0.2,
      ),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Colori principali
  static const Color primary = Color(0xFF2E5BFF);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color secondary = Color(0xFF707888);
  
  // Colori di sfondo
  static const Color background = Color(0xFFF9FAFC);
  static const Color surface = Colors.white;
  
  // Colori di stato
  static const Color success = Color(0xFF17C67C);
  static const Color successLight = Color(0xFFE8F9F1);
  static const Color error = Color(0xFFFF3B49);
  static const Color errorLight = Color(0xFFFEEBEC);
  static const Color warning = Color(0xFFFFC532);
  static const Color warningLight = Color(0xFFFFF8E8);
  
  // Colori di testo
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF707888);
  static const Color textDisabled = Color(0xFFADB5BD);
}

class AppTypography {
  static final TextStyle headline = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static final TextStyle title = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static final TextStyle subtitle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
  );
  
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static final TextStyle small = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );
}
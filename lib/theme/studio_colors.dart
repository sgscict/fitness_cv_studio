import 'package:flutter/material.dart';

/// Studio design system for Fitness Computer Vision Studio.
/// High-contrast, dark athletic studio aesthetic with dopamine accents.
class StudioColors {
  // Backgrounds
  static const Color background = Color(0xFF090A10);
  static const Color surface = Color(0xFF13151F);
  static const Color surfaceElevated = Color(0xFF1C1E2D);
  static const Color border = Color(0xFF282B3E);

  // Gen Z High-Voltage Neon Accents
  static const Color volt = Color(0xFFCCFF00); // Electric Volt Lime
  static const Color voltMuted = Color(0x33CCFF00);
  static const Color hotPink = Color(0xFFFF2A85); // Cyber Magenta
  static const Color hotPinkMuted = Color(0x33FF2A85);
  static const Color electricBlue = Color(0xFF00E5FF); // Cyber Cyan

  // Signature Dopamine Accents
  static const Color coral = Color(0xFFFF5C38);
  static const Color coralLight = Color(0xFFFF7E5F);
  static const Color coralMuted = Color(0x33FF5C38);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF38BDF8);
  static const Color cyanMuted = Color(0x3306B6D4);

  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetMuted = Color(0x338B5CF6);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldMuted = Color(0x3310B981);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberMuted = Color(0x33F59E0B);

  static const Color crimson = Color(0xFFEF4444);
  static const Color crimsonMuted = Color(0x33EF4444);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Signature Gradients
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF5C38), Color(0xFFFF7E40), Color(0xFFFFAB53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF06B6D4), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161824), Color(0xFF0F111A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

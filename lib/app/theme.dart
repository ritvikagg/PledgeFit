import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/pledge_colors.dart';

ThemeData buildPledgeTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: PledgeColors.pageBg,
    colorScheme: ColorScheme.light(
      primary: PledgeColors.primaryGreen,
      onPrimary: Colors.white,
      secondary: PledgeColors.penaltyAmber,
      onSecondary: Colors.white,
      surface: PledgeColors.card,
      onSurface: PledgeColors.ink,
      error: PledgeColors.dangerRose,
      onError: Colors.white,
      outline: PledgeColors.border,
    ),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: PledgeColors.ink,
    displayColor: PledgeColors.ink,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: PledgeColors.ink,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: PledgeColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: PledgeColors.card,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PledgeColors.cardBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PledgeColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PledgeColors.ink,
        side: const BorderSide(color: PledgeColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: PledgeColors.card,
      indicatorColor: PledgeColors.successGreenBg,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? PledgeColors.primaryGreen : PledgeColors.inkMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? PledgeColors.primaryGreen : PledgeColors.inkMuted,
          size: 24,
        );
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: PledgeColors.border,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

final ThemeData appTheme = buildPledgeTheme();

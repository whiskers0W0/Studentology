import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Warm cream palette (used by all screens via these constants) ──────────

  static const Color primaryAccent    = Color(0xFFFFB347); // warm orange
  static const Color secondaryAccent  = Color(0xFF6C63FF); // soft purple

  // "dark" named constants — values updated to cream palette so existing
  // screen files that reference AppTheme.dark* get the new warm look.
  static const Color darkBackground   = Color(0xFFFFF8F0); // warm cream
  static const Color darkSurface      = Color(0xFFFFFFFF); // white
  static const Color darkCard         = Color(0xFFFFFFFF); // white
  static const Color darkBorder       = Color(0xFFE5E7EB); // light grey
  static const Color darkDivider      = Color(0xFFE5E7EB);
  static const Color darkTextPrimary  = Color(0xFF1A1A2E); // near black
  static const Color darkTextSecondary = Color(0xFF6B7280); // medium grey

  // Light palette — same cream palette for the light ThemeData
  static const Color lightBackground  = Color(0xFFFFF8F0);
  static const Color lightSurface     = Color(0xFFFFFFFF);
  static const Color lightCard        = Color(0xFFFFFFFF);
  static const Color lightBorder      = Color(0xFFE5E7EB);
  static const Color lightDivider     = Color(0xFFE5E7EB);
  static const Color lightTextPrimary   = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Semantic / extra
  static const Color chipBg          = Color(0xFFFFE4BA); // light peach
  static const Color featuredBadge   = Color(0xFFFF6B6B); // coral red
  static const Color successColor    = Color(0xFF4CAF50);
  static const Color warningColor    = Color(0xFFFFB74D);
  static const Color errorColor      = Color(0xFFEF5350);
  static const Color borderColor     = Color(0xFFE5E7EB);

  // ── Pastel palette — light mode card accents ─────────────────────────────
  static const Color pastelBlue      = Color(0xFFD0EAFF); // powder blue
  static const Color pastelRose      = Color(0xFFFFD6DE); // blush pink
  static const Color pastelMint      = Color(0xFFCAF5DC); // fresh mint
  static const Color pastelLavender  = Color(0xFFE4DCFF); // soft lavender
  static const Color pastelPeach     = Color(0xFFFFE4CC); // warm peach
  static const Color pastelSunshine  = Color(0xFFFFF5C0); // soft yellow

  // ── Cartoon design system ─────────────────────────────────────────────────
  /// True black outline for the "cartoon" card aesthetic in light mode.
  static const Color cartoonBorder = Color(0xFF000000);
  /// Flat offset shadow — pure black for a crisp cartoon depth effect.
  static const List<BoxShadow> cartoonShadow = [
    BoxShadow(color: Color(0xFF000000), blurRadius: 0, offset: Offset(3, 3)),
  ];
  /// In dark mode, swap the black border for a softer visible outline.
  static const Color cartoonBorderDark = Color(0xFF5A5A7C);

  // ── Actual dark palette — used only inside darkTheme getter ──────────────

  static const Color _dkBg   = Color(0xFF1A1A2E); // deep navy
  static const Color _dkSurf = Color(0xFF252540);
  static const Color _dkCard = Color(0xFF252540);
  static const Color _dkBord = Color(0xFF3A3A5C);
  static const Color _dkDiv  = Color(0xFF3A3A5C);
  static const Color _dkTxt1 = Colors.white;
  static const Color _dkTxt2 = Color(0xFFB0B0C8);
  static const Color _dkHint = Color(0xFF7A7A9A);

  // ── Shared card decoration ────────────────────────────────────────────────

  /// Cartoon-style rounded card with dark outline and flat offset shadow.
  /// Pass [isDark] = true to swap to the dark-mode-safe border colour.
  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    Color? border,
    double radius = 24,
    bool isDark = false,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border ?? (isDark ? cartoonBorderDark : cartoonBorder),
          width: 1.5,
        ),
        boxShadow: isDark ? const [] : cartoonShadow,
      );

  // ── Light (cream) theme ───────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBackground,
        primaryColor: primaryAccent,
        colorScheme: const ColorScheme.light(
          primary: primaryAccent,
          secondary: secondaryAccent,
          surface: lightSurface,
          error: errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: lightTextPrimary,
          onError: Colors.white,
          outline: lightBorder,
          outlineVariant: lightDivider,
        ),
        dividerColor: lightDivider,
        textTheme: _buildTextTheme(lightTextPrimary, lightTextSecondary),
        iconTheme: const IconThemeData(color: lightTextSecondary, size: 22),
        // ── AppBar ──────────────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: lightBackground,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          ),
          titleTextStyle: GoogleFonts.ultra(
            fontSize: 22,
            color: lightTextPrimary,
          ),
          iconTheme: const IconThemeData(color: lightTextPrimary, size: 22),
          actionsIconTheme:
              const IconThemeData(color: lightTextSecondary, size: 22),
        ),
        // ── NavigationBar ────────────────────────────────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: primaryAccent.withOpacity(0.14),
          height: 66,
          elevation: 0,
          shadowColor: const Color(0x14000000),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? primaryAccent : const Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return IconThemeData(
              color: active ? primaryAccent : const Color(0xFF9CA3AF),
              size: 22,
            );
          }),
        ),
        // ── Legacy BottomNavigationBar ────────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryAccent,
          unselectedItemColor: Color(0xFF9CA3AF),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.3,
          ),
        ),
        // ── Card ─────────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: lightSurface,
          elevation: 0,
          shadowColor: const Color(0x0F000000),
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: lightBorder, width: 1),
          ),
        ),
        // ── Input ────────────────────────────────────────────────────────────
        inputDecorationTheme: _buildInputTheme(
          fill: Colors.white,
          border: lightBorder,
          focusBorder: primaryAccent,
          label: lightTextSecondary,
          hint: lightTextSecondary,
        ),
        // ── Buttons ──────────────────────────────────────────────────────────
        elevatedButtonTheme: _elevatedButtonTheme(primaryAccent, Colors.white),
        outlinedButtonTheme: _outlinedButtonTheme(primaryAccent),
        textButtonTheme: _textButtonTheme(primaryAccent),
        // ── FAB ──────────────────────────────────────────────────────────────
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          elevation: 2,
          focusElevation: 4,
          hoverElevation: 6,
          // Stadium = full pill; side gives the cartoon dark outline
          shape: const StadiumBorder(
            side: BorderSide(color: cartoonBorder, width: 1.5),
          ),
          extendedTextStyle: GoogleFonts.roboto(
            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.4,
          ),
        ),
        // ── Chip ─────────────────────────────────────────────────────────────
        chipTheme: _buildChipTheme(chipBg, borderColor, lightTextSecondary),
        // ── TabBar ───────────────────────────────────────────────────────────
        tabBarTheme: TabBarThemeData(
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: primaryAccent, width: 2),
          ),
          labelColor: primaryAccent,
          unselectedLabelColor: lightTextSecondary,
          dividerColor: lightBorder,
          labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400,
          ),
        ),
        // ── Dialog ───────────────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: lightSurface,
          elevation: 4,
          surfaceTintColor: Colors.transparent,
          shadowColor: const Color(0x1A000000),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: lightTextPrimary,
          ),
          contentTextStyle: GoogleFonts.inter(
            color: lightTextSecondary, fontSize: 14, height: 1.6,
          ),
        ),
        // ── Bottom sheet ─────────────────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          dragHandleColor: borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
        ),
        // ── Divider ──────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: lightDivider, thickness: 1, space: 1,
        ),
        // ── Switch / Checkbox ────────────────────────────────────────────────
        switchTheme: _switchTheme(primaryAccent),
        checkboxTheme: _checkboxTheme(primaryAccent),
        // ── ListTile ─────────────────────────────────────────────────────────
        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          iconColor: lightTextSecondary,
          textColor: lightTextPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        // ── SnackBar ─────────────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkTextPrimary,
          contentTextStyle: GoogleFonts.inter(
            color: Colors.white, fontSize: 14, letterSpacing: 0.1,
          ),
          actionTextColor: primaryAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),
      );

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _dkBg,
        primaryColor: primaryAccent,
        colorScheme: const ColorScheme.dark(
          primary: primaryAccent,
          secondary: secondaryAccent,
          surface: _dkCard,
          error: errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: _dkTxt1,
          onSurfaceVariant: _dkTxt2,
          onError: Colors.white,
          outline: _dkBord,
          outlineVariant: _dkDiv,
          shadow: Colors.black,
        ),
        dividerColor: _dkDiv,
        textTheme: _buildTextTheme(_dkTxt1, _dkTxt2),
        iconTheme: const IconThemeData(color: _dkTxt2, size: 22),
        appBarTheme: AppBarTheme(
          backgroundColor: _dkBg,
          foregroundColor: _dkTxt1,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          titleTextStyle: GoogleFonts.ultra(fontSize: 22, color: _dkTxt1),
          iconTheme: const IconThemeData(color: _dkTxt1, size: 22),
          actionsIconTheme: const IconThemeData(color: _dkTxt2, size: 22),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _dkBg,
          indicatorColor: primaryAccent.withOpacity(0.14),
          height: 66,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? primaryAccent : _dkTxt2,
              letterSpacing: 0.3,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return IconThemeData(
              color: active ? primaryAccent : _dkTxt2,
              size: 22,
            );
          }),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: _dkBg,
          selectedItemColor: primaryAccent,
          unselectedItemColor: _dkTxt2,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: _dkCard,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.45),
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _dkBord, width: 1),
          ),
        ),
        inputDecorationTheme: _buildInputTheme(
          fill: _dkCard,
          border: _dkBord,
          focusBorder: primaryAccent,
          label: _dkTxt2,
          hint: _dkHint,
        ),
        elevatedButtonTheme: _elevatedButtonTheme(primaryAccent, Colors.white),
        outlinedButtonTheme: _outlinedButtonTheme(primaryAccent),
        textButtonTheme: _textButtonTheme(primaryAccent),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: StadiumBorder(
            side: BorderSide(color: cartoonBorderDark, width: 1.5),
          ),
        ),
        chipTheme: _buildChipTheme(_dkCard, _dkBord, _dkTxt2),
        dialogTheme: DialogThemeData(
          backgroundColor: _dkCard,
          elevation: 8,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 18, fontWeight: FontWeight.w700, color: _dkTxt1,
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: _dkSurf,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          dragHandleColor: _dkBord,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _dkDiv, thickness: 1, space: 1,
        ),
        switchTheme: _switchTheme(primaryAccent),
        checkboxTheme: _checkboxTheme(primaryAccent),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          iconColor: _dkTxt2,
          textColor: _dkTxt1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1E2540),
          contentTextStyle: GoogleFonts.inter(
            color: _dkTxt1, fontSize: 14, letterSpacing: 0.1,
          ),
          actionTextColor: primaryAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),
      );

  // ── Private builders ──────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(Color primary, Color secondary) =>
      TextTheme(
        // Display — hero numbers / splash text (Ultra)
        displayLarge: GoogleFonts.ultra(
          fontSize: 57, color: primary, height: 1.12,
        ),
        displayMedium: GoogleFonts.ultra(
          fontSize: 45, color: primary, height: 1.16,
        ),
        displaySmall: GoogleFonts.ultra(
          fontSize: 36, color: primary, height: 1.22,
        ),
        // Headline — screen titles (Ultra)
        headlineLarge: GoogleFonts.ultra(
          fontSize: 32, color: primary, height: 1.25,
        ),
        headlineMedium: GoogleFonts.ultra(
          fontSize: 26, color: primary, height: 1.3,
        ),
        headlineSmall: GoogleFonts.ultra(
          fontSize: 22, color: primary, height: 1.36,
        ),
        // Title — card headers, AppBar (Roboto Bold)
        titleLarge: GoogleFonts.roboto(
          fontSize: 18, fontWeight: FontWeight.w700, color: primary,
          letterSpacing: 0, height: 1.44,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 15, fontWeight: FontWeight.w600, color: primary,
          letterSpacing: 0.1, height: 1.5,
        ),
        titleSmall: GoogleFonts.roboto(
          fontSize: 13, fontWeight: FontWeight.w500, color: secondary,
          letterSpacing: 0.1, height: 1.5,
        ),
        // Body — content (Inter)
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: primary,
          letterSpacing: 0.15, height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: secondary,
          letterSpacing: 0.2, height: 1.57,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: secondary,
          letterSpacing: 0.3, height: 1.5,
        ),
        // Label — buttons, chips, nav labels (Inter)
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: primary,
          letterSpacing: 0.1, height: 1.43,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: secondary,
          letterSpacing: 0.5, height: 1.33,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, color: secondary,
          letterSpacing: 0.5, height: 1.45,
        ),
      );

  static InputDecorationTheme _buildInputTheme({
    required Color fill,
    required Color border,
    required Color focusBorder,
    required Color label,
    required Color hint,
  }) {
    final radius = BorderRadius.circular(16);
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: focusBorder, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border.withOpacity(0.5)),
      ),
      labelStyle: GoogleFonts.inter(
        color: label, fontSize: 14, fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: primaryAccent, fontSize: 12, fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(
        color: hint.withOpacity(0.55), fontSize: 14,
        fontWeight: FontWeight.w300, letterSpacing: 0.2,
      ),
      errorStyle: GoogleFonts.inter(
        color: errorColor, fontSize: 12, letterSpacing: 0.2,
      ),
      prefixIconColor: label,
      suffixIconColor: label,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withOpacity(0.4),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          // Pill shape with cartoon dark outline
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
            side: BorderSide(color: cartoonBorder, width: 1.5),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed) ? 2 : 0,
          ),
          overlayColor:
              WidgetStateProperty.all(Colors.white.withOpacity(0.15)),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(Color accent) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme(Color accent) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          ),
        ),
      );

  static ChipThemeData _buildChipTheme(
          Color bg, Color border, Color labelColor) =>
      ChipThemeData(
        backgroundColor: bg,
        selectedColor: primaryAccent.withOpacity(0.15),
        secondarySelectedColor: primaryAccent.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // Full pill chips with dark outline
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: cartoonBorder, width: 1.2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: labelColor, letterSpacing: 0.2,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: primaryAccent,
        ),
      );

  static SwitchThemeData _switchTheme(Color accent) => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : null,
        ),
        overlayColor:
            WidgetStateProperty.all(accent.withOpacity(0.1)),
      );

  static CheckboxThemeData _checkboxTheme(Color accent) =>
      CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4)),
        overlayColor:
            WidgetStateProperty.all(accent.withOpacity(0.1)),
      );
}

extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardBg => Theme.of(this).colorScheme.surface;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => isDark
      ? const Color(0xFFB0B0C8)
      : const Color(0xFF6B7280);
  Color get cardBorder => Theme.of(this).colorScheme.outline;
  Color get inputFill => Theme.of(this).colorScheme.surface;
}

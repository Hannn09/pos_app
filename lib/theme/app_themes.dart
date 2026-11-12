import 'package:flutter/material.dart';

const String _fontFamily = 'PlusJakartaSans';

ThemeData lightTheme = ThemeData(
  primaryColor: primaryColor,
  scaffoldBackgroundColor: scaffoldBackgroundColor,
  cardColor: cardColor,
  dividerColor: dividerColor,
  brightness: Brightness.light,
  fontFamily: _fontFamily,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: backgroundTextField,
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: primaryColor,
    selectionHandleColor: primaryColor,
    selectionColor: primaryColor.withAlpha(30),
  ),
);

ThemeData darkTheme = ThemeData(
  primaryColor: primaryColor,
  scaffoldBackgroundColor: blackColor,
  brightness: Brightness.dark,
  fontFamily: _fontFamily,
  cardColor: cardDarkColor,
  dialogTheme: DialogThemeData(backgroundColor: dialogDarkColor),
  dividerColor: dividerDarkColor,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: primaryColor,
    selectionHandleColor: primaryColor,
    selectionColor: primaryColor.withAlpha(50),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: backgroundDarkTextField,
  ),
);

Color primaryColor = const Color(0xFF087F5B);
Color primaryDarkColor = const Color(0xFF065F44);
Color primaryLightColor = const Color(0xFFE6F4EA);
Color whiteColor = const Color(0xFFFFFFFF);
Color scaffoldBackgroundColor = const Color(0xFFF8FAF9);
Color blackColor = const Color(0xFF202824);
Color greyColor = const Color(0xFF6B7280);
Color lightGreyColor = const Color(0xFF9CA3AF);
Color backgroundTextField = const Color(0xFFF8FAF9);
Color greyDarkColor = const Color(0xB3FFFFFF);
Color lightGreyDarkColor = const Color(0x66FFFFFF);
Color backgroundDarkTextField = const Color(0xFF2A2A2A);
Color redColor = const Color(0xFFE03131);
Color cardDarkColor = const Color(0xFF2A2A2A);
Color cardColor = const Color(0xFFFFFFFF);
Color greenColor = const Color(0xFF087F5B);
Color blueColor = const Color(0xFF2B8EFF);
Color orangeColor = const Color(0xFFF59F00);
Color backgroundDarkBottomNav = const Color(0xFF212121);
Color dividerColor = const Color(0xFFEEF2F0);
Color borderColor = const Color(0xFFE6ECE9);
Color pastelColor = const Color(0xFFC3E6D8);

Color scaffoldDarkColor = Color(0xFF1E1E1E);
Color dialogDarkColor = Color(0xFF2A2A2A);
Color dividerDarkColor = Color(0xFF2C2C2C);
Color borderDarkColor = Color(0xFF555555);
Color textPrimaryDarkColor = Color(0xFFFFFFFF);
Color textSecondaryDarkColor = Color(0xB3FFFFFF);
Color textHintDarkColor = Color(0x66FFFFFF);

TextStyle extraBoldTextStyle = const TextStyle(
  fontFamily: _fontFamily,
  fontWeight: FontWeight.w800,
);
TextStyle boldTextStyle = const TextStyle(
  fontFamily: _fontFamily,
  fontWeight: FontWeight.bold,
);
TextStyle semiBoldTextStyle = const TextStyle(
  fontFamily: _fontFamily,
  fontWeight: FontWeight.w600,
);
TextStyle regularTextStyle = const TextStyle(
  fontFamily: _fontFamily,
  fontWeight: FontWeight.w400,
);
TextStyle mediumTextStyle = const TextStyle(
  fontFamily: _fontFamily,
  fontWeight: FontWeight.w500,
);
TextStyle errorTextStyle = TextStyle(
  fontFamily: _fontFamily,
  color: redColor,
  fontWeight: FontWeight.w500,
);
TextStyle hintTextStyle = TextStyle(
  fontFamily: _fontFamily,
  color: lightGreyColor,
  fontWeight: FontWeight.w500,
);
TextStyle hintDarkTextStyle = TextStyle(
  fontFamily: _fontFamily,
  color: lightGreyDarkColor,
  fontWeight: FontWeight.w500,
);

final textFieldDecoration = InputDecoration(
  filled: true,
  errorStyle: errorTextStyle,
  fillColor: whiteColor,
  prefixIconConstraints: BoxConstraints.tight(const Size(15, 60)),
  prefixIcon: Container(width: 0),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: primaryColor),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: redColor),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: borderColor),
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: borderColor),
  ),
  contentPadding: EdgeInsets.zero,
);
final searchTextField = InputDecoration(
  filled: true,
  errorStyle: errorTextStyle,
  prefixIconConstraints: BoxConstraints.tight(const Size(65, 55)),
  prefixIcon: Container(
    padding: const EdgeInsets.all(15),
    child: Image.asset('assets/ic_search.png', fit: BoxFit.contain),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: greyColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: greyColor),
  ),
  hintText: "Search",
  hintStyle: hintTextStyle,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  contentPadding: EdgeInsets.zero,
);

final searchDarkTextField = InputDecoration(
  filled: true,
  fillColor: backgroundDarkTextField,
  errorStyle: errorTextStyle,
  prefixIconConstraints: BoxConstraints.tight(const Size(65, 55)),
  prefixIcon: Container(
    padding: const EdgeInsets.all(15),
    child: Image.asset(
      'assets/ic_search.png',
      fit: BoxFit.contain,
      color: textHintDarkColor,
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: borderDarkColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: primaryColor),
  ),
  hintText: "Search",
  hintStyle: hintDarkTextStyle,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  contentPadding: EdgeInsets.zero,
);

final dateTimeTextField = InputDecoration(
  filled: true,
  errorStyle: errorTextStyle,
  suffixIconConstraints: BoxConstraints.tight(const Size(65, 55)),
  suffixIcon: Container(
    padding: const EdgeInsets.all(15),
    child: Image.asset('assets/ic_calendar.png', fit: BoxFit.contain),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: greyColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: greyColor),
  ),
  hintText: "Search",
  hintStyle: hintTextStyle,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
);

final dateTimeModalTextField = InputDecoration(
  filled: true,
  errorStyle: errorTextStyle,
  prefixIconConstraints: BoxConstraints.tight(const Size(65, 55)),
  prefixIcon: Container(
    padding: const EdgeInsets.all(15),
    child: Image.asset(
      'assets/ic_calendar.png',
      fit: BoxFit.contain,
      color: primaryColor,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: backgroundTextField),
  ),
  hintStyle: hintTextStyle,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  contentPadding: EdgeInsets.zero,
);

final dropdownStrokeTextField = InputDecoration(
  filled: true,
  errorStyle: errorTextStyle,
  prefixIconConstraints: BoxConstraints.tight(const Size(15, 60)),
  prefixIcon: Container(width: 0),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: greyColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: greyColor),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: redColor),
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  contentPadding: EdgeInsets.zero,
);

final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryColor,
  elevation: 0,
  shadowColor: Colors.transparent,
  overlayColor: Colors.transparent,
  textStyle: boldTextStyle.copyWith(color: whiteColor),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  padding: const EdgeInsets.symmetric(vertical: 15.0),
);
final ButtonStyle buttonStrokeStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.transparent,
  elevation: 0,
  overlayColor: Colors.transparent,
  shadowColor: Colors.transparent,
  side: BorderSide(color: primaryColor),
  textStyle: boldTextStyle.copyWith(color: primaryColor),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  padding: const EdgeInsets.symmetric(vertical: 15.0),
);

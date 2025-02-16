import 'package:flutter/material.dart';
part 'app_icons.dart';
part 'color/colors.dart';
part 'text_styles.dart';
part 'extention.dart';

class AppTheme {
  /// LIGHT MODE
  static final ThemeData appTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: TwitterColor.white,
    brightness: Brightness.light,
    primaryColor: AppColor.primary,
    cardColor: AppColor.cardColor,
    unselectedWidgetColor: AppColor.unselectedWidgetColor,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColor.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TwitterColor.white,
      iconTheme: IconThemeData(
        color: TwitterColor.dodgeBlue,
      ),
      elevation: 0,
      // ignore: deprecated_member_use
    ),
    bottomAppBarTheme: ThemeData.light().bottomAppBarTheme.copyWith(
          color: Colors.white,
          elevation: 0,
        ),
    tabBarTheme: TabBarTheme(
      labelStyle: TextStyles.titleStyle.copyWith(color: TwitterColor.dodgeBlue),
      unselectedLabelColor: AppColor.darkGrey,
      unselectedLabelStyle:
          TextStyles.titleStyle.copyWith(color: AppColor.darkGrey),
      labelColor: TwitterColor.dodgeBlue,
      labelPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: TwitterColor.white,
    ),
    colorScheme: const ColorScheme(
      background: Colors.white,
      onPrimary: Colors.white,
      onBackground: Colors.black,
      onError: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      surfaceDim: AppColor.extraLightGrey,
      error: Colors.red,
      primary: Colors.blue,
      primaryContainer: Colors.blue,
      secondary: AppColor.secondary,
      secondaryContainer: AppColor.darkGrey,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    dividerColor: AppColor.extraLightGrey,
    dividerTheme: DividerThemeData(
      color: AppColor.extraLightGrey,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white.withOpacity(0.8),
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      prefixIconColor: Colors.black,
      suffixIconColor: Colors.black,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      bodySmall: TextStyle(color: const Color.fromARGB(255, 175, 175, 175)),
    ),
  );

  /// DARK MODE

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColor.dark,
    brightness: Brightness.dark,
    primaryColor: AppColor.darkPrimary,
    cardColor: AppColor.darkCardColor,
    unselectedWidgetColor: AppColor.darkUnselectedWidgetColor,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
      elevation: 0,
    ),
    bottomAppBarTheme: ThemeData.dark().bottomAppBarTheme.copyWith(
          color: Colors.black,
          elevation: 0,
        ),
    tabBarTheme: TabBarTheme(
      labelStyle: TextStyles.titleStyle.copyWith(color: Colors.black),
      unselectedLabelColor: Colors.grey[400],
      unselectedLabelStyle:
          TextStyles.titleStyle.copyWith(color: Colors.grey[400]),
      labelColor: Colors.black,
      labelPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
    ),
    colorScheme: ColorScheme(
      background: Colors.black,
      onPrimary: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      surfaceDim: AppColor.extraExtraLightGrey,
      error: Colors.red,
      primary: Colors.blue,
      primaryContainer: Colors.blue,
      secondary: AppColor.secondary,
      secondaryContainer: Colors.grey[700]!,
      surface: Colors.grey[900]!,
      brightness: Brightness.dark,
    ),
    dividerColor: Colors.grey[800],
    dividerTheme: DividerThemeData(
      color: Colors.grey[800],
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.grey.shade800,
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade300),
      prefixIconColor: Colors.white,
      suffixIconColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.grey[350]),
      bodyMedium: TextStyle(color: Colors.grey[350]),
      bodySmall: TextStyle(color: const Color.fromARGB(255, 120, 120, 120)),
    ),
  );

  static List<BoxShadow> shadow = <BoxShadow>[
    BoxShadow(
        blurRadius: 10,
        offset: const Offset(5, 5),
        color: AppTheme.appTheme.colorScheme.secondary,
        spreadRadius: 1)
  ];
  static BoxDecoration softDecoration =
      const BoxDecoration(boxShadow: <BoxShadow>[
    BoxShadow(
        blurRadius: 8,
        offset: Offset(5, 5),
        color: Color(0xffe2e5ed),
        spreadRadius: 5),
    BoxShadow(
        blurRadius: 8,
        offset: Offset(-5, -5),
        color: Color(0xffffffff),
        spreadRadius: 5)
  ], color: Color(0xfff1f3f6));
}

String get description {
  return '';
}

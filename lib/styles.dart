import 'package:flutter/material.dart';
import 'constants.dart';

final kBorderInput = OutlineInputBorder(
  borderRadius: BorderRadius.circular(150),
  borderSide: BorderSide(width: 2, color: colorSecondary),
);

final NewTheme = ThemeData(
  scaffoldBackgroundColor: const Color.fromARGB(255, 250, 252, 255),
  primaryColor: colorPrimary,
  hintColor: colorPrimary,
  focusColor: colorSecondary,
  indicatorColor: colorPrimary,
  textSelectionTheme: TextSelectionThemeData(cursorColor: colorPrimary),
  primarySwatch: Colors.blue,
  fontFamily: "Poppins, sans-serif",
  appBarTheme: AppBarTheme(
    backgroundColor: colorPrimary,
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: colorPrimary,
    selectedColor: colorPrimary,
    disabledColor: Colors.grey.shade400,
    secondarySelectedColor: colorSecondary,
    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide.none,
    ),
    labelStyle: TextStyle(
      color: TextLightColor,
      fontWeight: FontWeight.bold,
    ),
    secondaryLabelStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    brightness: Brightness.light,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: colorPrimary,
      minimumSize: const Size(double.infinity, 45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(25),
          bottomRight: Radius.circular(25),
          bottomLeft: Radius.circular(25),
        ),
      ),
    ),
  ),
  cardTheme: CardTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    elevation: 4,
    margin: EdgeInsets.all(5),
    color: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF6F5F6),
    hintStyle: TextStyle(fontWeight: FontWeight.w300, color: LabelColor),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    errorStyle: TextStyle(height: 0),
  ),
  popupMenuTheme: PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    color: Colors.white.withOpacity(0.9),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.all(colorPrimary),
    overlayColor: WidgetStateProperty.all(colorSecondary.withOpacity(0.1)),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      backgroundColor: WidgetStateProperty.all(
        Colors.white.withOpacity(0.9),
      ),
    ),
  ), dialogTheme: DialogThemeData(backgroundColor: Colors.white.withOpacity(0.9)),
);

final DarkTheme = ThemeData(
  scaffoldBackgroundColor: colorPrimary,
  useMaterial3: true,
  primaryColor: colorPrimary,
  hintColor: colorPrimary,
  focusColor: const Color(0xFF84B702),
  indicatorColor: colorPrimary,
  textSelectionTheme: TextSelectionThemeData(cursorColor: colorPrimary),
  primarySwatch: Colors.blue,
  fontFamily: "Poopins",
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    displayLarge: TextStyle(color: Colors.white),
    displayMedium: TextStyle(color: Colors.white),
    displaySmall: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.white),
    headlineSmall: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
    titleSmall: TextStyle(color: Colors.white),
    labelLarge: TextStyle(color: Colors.white),
    labelSmall: TextStyle(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
  ),
);

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);

final kTheme = ThemeData(
  scaffoldBackgroundColor: colorPrimary,
  primaryColor: colorPrimary,
  hintColor: colorPrimary,
  focusColor: colorSecondary,
  indicatorColor: colorPrimary,
  textSelectionTheme: TextSelectionThemeData(cursorColor: colorPrimary),
);

final kThemeHome = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  primaryColor: colorPrimary,
  hintColor: colorPrimary,
  focusColor: colorSecondary,
  indicatorColor: colorPrimary,
  textSelectionTheme: TextSelectionThemeData(cursorColor: colorPrimary),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: colorPrimary.withOpacity(0.9),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white,
  ),
);

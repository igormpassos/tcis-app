import 'package:flutter/material.dart';
import 'package:tcis_app/screens/home/home_screen.dart';
import 'package:tcis_app/screens/reports/create_report.dart';
import 'package:tcis_app/styles.dart';
//import 'app/views/login.dart';
import 'package:tcis_app/screens/login/login.dart';
import 'package:tcis_app/screens/entryPoint/entry_point.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//import 'package:tcis_app/screens/login/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: NewTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      initialRoute: '/',
      routes: {
        '/' : (context) => Login(),
        '/home': (context) => HomePage(),
        '/reports': (context) => ReportEntryScreen(),
      },
    );
  }
}



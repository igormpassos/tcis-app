import 'package:tcis_app/styles.dart';
import 'package:flutter/material.dart';
import 'app/views/home_page.dart';
import 'app/views/reports.dart';
import 'app/views/login.dart';

void main() {
  runApp(
    TCISApp()
  );
}

class TCISApp extends StatelessWidget {
  const TCISApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: kTheme,
      initialRoute: '/',
      routes: {
        '/' : (context) => Login(),
        '/home': (context) => HomePage(),
        '/reports': (context) => Reports(),
      },
    );
  }
}


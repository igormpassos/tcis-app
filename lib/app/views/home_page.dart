import 'package:flutter/material.dart';
import '../../styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('Index 0: Home')),
    Center(child: Text('Index 1: User')),
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int itemSelecionado = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: kThemeHome,
      home: Scaffold(
        body: HomePage._widgetOptions.elementAt(itemSelecionado),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: itemSelecionado,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home", activeIcon: Icon(Icons.home_filled)),
            BottomNavigationBarItem(
              icon: Icon(Icons.usb_outlined), label: "User")
          ],
          onTap: (valor) {
            setState(() {
              itemSelecionado = valor;
            });
          },
        ),
      ),
    );
  }
}

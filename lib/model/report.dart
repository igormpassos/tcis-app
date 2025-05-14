import 'package:flutter/material.dart' show Color;

class report {
  final String title, iconSrc, data, cliente, produto, terminal, status;
  final Color color;

  report({
    required this.title,
    required this.data,
    required this.cliente,
    required this.produto,
    required this.terminal,
    this.iconSrc = "assets/icons/ios.svg",
    this.color = const Color(0xFF003C92),
    this.status = "",
  });
}

final List<report> reports = [
  report(
    title: "NFL 8128",
    data: "14 nov 2024",
    cliente: "CSN",
    produto: "FSVT",
    terminal: "VSB",
    iconSrc: "assets/avaters/Avatar 1.jpg",
  ),
  report(
    title: "NCA 8110",
    data: "14 nov 2024",
    cliente: "ArcelorMittal",
    produto: "FSVT",
    terminal: "Serra Azul",
    iconSrc: "assets/avatar/Avatar 2.jpg",
  ),
];

final List<report> recentreports = [
  report(
    title: "NFL 8129",
    data: "14/11/2024",
    cliente: "CSN",
    iconSrc: "assets/avaters/Avatar 2.jpg",
    produto: "Produto 3",
    terminal: "Terminal 3",
    status: "Em Revisão",
  ),
  report(
    title: "NCA 8111",
    color: const Color(0xFF9CC5FF),
    iconSrc: "assets/avaters/Avatar 1.jpg",
    data: "14/11/2024",
    cliente: "ArcelorMittal",
    produto: "Produto 4",
    terminal: "Terminal 4",
    status: "Concluído",
  ),
  report(
    title: "NFL 8130",
    data: "14/11/2024",
    iconSrc: "assets/avaters/Avatar 2.jpg",
    cliente: "ArcelorMittal",
    produto: "Produto 5",
    terminal: "Terminal 5",
    status: "Em Revisão",
  ),
  report(
    title: "NCA 8112",
    color: const Color(0xFF9CC5FF),
    iconSrc: "assets/avaters/Avatar 1.jpg",
    data: "14/11/2024",
    cliente: "ArcelorMittal",
    produto: "Produto 6",
    terminal: "Terminal 6",
    status: "Concluído",
  ),
];

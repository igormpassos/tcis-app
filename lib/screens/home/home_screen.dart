import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';
import '../../model/full_report_model.dart';
import '../../components/report_card.dart';
import '../../components/secondary_report_card.dart';
import 'package:tcis_app/screens/reports/create_report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FullReportModel> fullReports = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('full_reports') ?? [];
    final reports =
        data.map((e) => FullReportModel.fromJson(jsonDecode(e))).toList();
    setState(() {
      fullReports = reports.reversed.toList();
    });
  }

  Widget _BuildBlankReport(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      height: 230,
      width: 230,
      decoration: BoxDecoration(
        color: Color(0xFFC3C3C3),
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Center(
        child: IconButton(
          icon: Icon(Icons.add, color: Colors.white, size: 50),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportEntryScreen(),
              ),
            ).then((_) => loadReports());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Relatórios em Andamento",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(
                              color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportEntryScreen(),
                          ),
                        ).then((_) => loadReports());
                      },
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    children: [
                      ...fullReports.where((report) => report.status == 0).map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: reportCard(
                                report: report,
                                onDeleted: () => setState(() => loadReports()),
                                onUpdated: () => loadReports(), // novo callback
                              ),
                            ),
                          ),
                      _BuildBlankReport(context),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Recentes",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              ...fullReports.where((report) => report.status == 1).map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 10),
                      child: SecondaryreportCard(
                        title: report.prefixo,
                        iconSrc: "assets/icons/ios.svg",
                        colorl: colorSecondary,
                        data: report.dataCriacao
                            .toIso8601String()
                            .split("T")
                            .first,
                        cliente: report.colaborador,
                        produto: report.produto,
                        terminal: report.terminal,
                        pathPdf: report.pathPdf,
                        status: "1",
                      ),
                    ),
                  ),
              if (fullReports.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "Nenhum relatório concluído",
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on DateTime {
  split(String s) {}
}

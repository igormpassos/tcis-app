import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';
import '../../model/report.dart';
import 'components/report_card.dart';
import 'components/secondary_report_card.dart';
import 'package:tcis_app/screens/reports/create_report.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _BuildBlankReport(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      height: 250,
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
            );
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
                      );
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
                      ...reports
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: reportCard(
                                title: report.title,
                                iconSrc: report.iconSrc,
                                color: reports.indexOf(report) % 2 == 0
                                    ? colorPrimary
                                    : colorSecondary,
                                data: report.data,
                                cliente: report.cliente,
                                produto: report.produto,
                                terminal: report.terminal,
                            
                              ),
                            ),
                          )
                          ,
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
              ...recentreports.map((report) => Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                    child: SecondaryreportCard(
                      title: report.title,
                      iconSrc: report.iconSrc,
                      colorl: recentreports.indexOf(report) % 2 == 0
                          ? colorPrimary
                          : colorSecondary,
                          //: Color(0xFF9CC5FF),
                      data: report.data,
                      cliente: report.cliente,
                      produto: report.produto,
                      terminal: report.terminal,
                      status: report.status,
                    ),
                  )),
          ] + (recentreports.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        "Nenhum relatório concluido",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 16),
                      ),
                    ),
                  ),
                ]
              : []),
        ),
      ),
    ),
    );
  }
}

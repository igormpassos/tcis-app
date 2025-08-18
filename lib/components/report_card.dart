import 'package:flutter/material.dart';
import 'package:tcis_app/components/delete_modal.dart';
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/screens/reports/edit_report.dart';
import 'package:intl/intl.dart';

class reportCard extends StatelessWidget {
  final FullReportModel report;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  const reportCard({
    super.key,
    required this.report,
    required this.onDeleted,
    required this.onUpdated,
  });

  // getters simplificados
  String get id => report.id;
  String get title => report.prefixo;
  String get data => DateFormat('dd/MM/yyyy').format(report.dataCriacao);
  String get cliente => report.colaborador;
  String get produto => report.produto;
  String get terminal => report.terminal;
  String get pathPdf => report.pathPdf;
  Color get color => const Color(0xFF003C92);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      height: 230,
      width: 230,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data,
                      style: TextStyle(
                          color: Colors.white38, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      cliente,
                      style: TextStyle(
                          color: Colors.white38, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      produto,
                      style: TextStyle(
                          color: Colors.white38, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      terminal,
                      style: TextStyle(
                          color: Colors.white38, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Spacer(),
                  // Row(
                  //   children: List.generate(
                  //     1,
                  //     (index) => Transform.translate(
                  //       offset: Offset((-10 * index).toDouble(), 0),
                  //       child: CircleAvatar(
                  //         radius: 20,
                  //         backgroundImage: AssetImage(
                  //           "assets/avaters/Avatar ${index + 1}.jpg",
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'editar',
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: 'deletar',
                  child: Text('Deletar'),
                ),
              ];
            },
            onSelected: (value) async {
              if (value == 'editar') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditReportScreen(report: report),
                  ),
                );
                // Só atualizar se houve mudança
                if (result == true) {
                  onUpdated(); // callback para atualizar Home
                }
              } else if (value == 'deletar') {
                showDeleteConfirmationDialog(context, id, onDeleted);
              }
            },
            icon: Icon(Icons.more_vert_outlined, color: Colors.white),
          )
        ],
      ),
    );
  }
}

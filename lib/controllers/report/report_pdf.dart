import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcis_app/model/full_report_model.dart'; // certifique-se que esse model está criado

// Reduzir resolução e qualidade da imagem
Future<Uint8List> compressImage(File imageFile) async {
  final imageBytes = await imageFile.readAsBytes();
  final originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) return imageBytes;

  final resized = img.copyResize(originalImage, width: 800); // Redimensionar
  final compressed = img.encodeJpg(resized, quality: 60); // Comprimir
  return Uint8List.fromList(compressed);
}

generatePdf({
  required TextEditingController prefixoController,
  required String? selectedTerminal,
  required String? selectedProduto,
  required String? selectedVagao,
  required String? colaborador,
  required String? fornecedor,
  required String? selectedValue,
  required TextEditingController dataInicioController,
  required TextEditingController horarioChegadaController,
  required TextEditingController horarioInicioController,
  required TextEditingController horarioTerminoController,
  required TextEditingController horarioSaidaController,
  required TextEditingController dataTerminoController,
  required bool? houveContaminacao,
  required String contaminacaoDescricao,
  required String? materialHomogeneo,
  required String? umidadeVisivel,
  required String? houveChuva,
  required String? fornecedorAcompanhou,
  required TextEditingController observacoesController,
  required List<Map<String, dynamic>> images,
}) async {
  final pdf = pw.Document();

  final ByteData logoImageData = await rootBundle.load(
    'assets/images/logo-tcis-lisa-branca.png',
  );
  final Uint8List logoImageBytes = logoImageData.buffer.asUint8List();

  // --- Carregar imagens como bytes ---
  List<Map<String, dynamic>> imagesBytes = [];

  for (var imageData in images) {
    final file = imageData['file'] as File?;
    if (file != null && await file.exists()) {
      //final bytes = await file.readAsBytes();
      final bytes = await compressImage(file);
      imagesBytes.add({'bytes': bytes, 'timestamp': imageData['timestamp']});
      // Após carregar todas as imagens com bytes
      imagesBytes.sort(
        (a, b) =>
            (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime),
      );

      print('Image loaded: ${imageData['timestamp']}');
    } else {
      print('Image not found or invalid: ${imageData['timestamp']}');
    }
  }

  // Função para o cabeçalho
  pw.Widget buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#003C92'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(pw.MemoryImage(logoImageBytes), height: 25),
          pw.Expanded(
            child: pw.Text(
              'RELATÓRIO ANALÍTICO DE CARGA',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Text(
            prefixoController.text,
            style: pw.TextStyle(color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  // Função para o rodapé
  pw.Widget buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#003C92'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'TCIS DO BRASIL INSPEÇÃO E CERTIFICAÇÃO LTDA',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Rua Almeida de Moraes, 164 - Conj.51 Santos, SP/ Brazil',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Função para o conteúdo principal
  pw.Widget buildContent() {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          // Sessão Cliente e Terminal
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F4F4'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(selectedTerminal ?? ''),
                pw.Row(
                  children: [
                    pw.Text(
                      'Inspetor:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(colaborador ?? ''),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F4F4'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'Dados do Carregamento',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text(
                      'Data:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(dataInicioController.text),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start, 
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'Hora Início:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(horarioInicioController.text),
                      ],
                    ),
                    pw.SizedBox(width: 15),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Hora Término:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(horarioTerminoController.text),
                      ],
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Fornecedor:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(fornecedor ?? ''),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Produto:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(selectedProduto ?? ''),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Material Homogêneo:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(materialHomogeneo ?? ''),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Houve Chuva:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(houveChuva ?? ''),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Umidade Visível:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(umidadeVisivel ?? ''),
                  ],
                ),
                houveContaminacao != true
                    ? pw.Row(
                      children: [
                        pw.Text(
                          'Houve Contaminação:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text('Não'),
                      ],
                    )
                    : pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Houve Contaminação:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Sim. $contaminacaoDescricao'),
                      ],
                    ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Houve Acompanhamento do Fornecedor:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(fornecedorAcompanhou ?? ''),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F4F4'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Wrap(
              spacing: 5,
              direction: pw.Axis.vertical,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'Dados da Locomotiva',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  mainAxisSize: pw.MainAxisSize.max,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'Hora Chegada:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(horarioChegadaController.text),
                      ],
                    ),
                    pw.SizedBox(width: 15),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Hora Saída:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(horarioSaidaController.text),
                      ],
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Tipo Vagão:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(selectedVagao ?? ''),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          // Sessão Observações
          if (observacoesController.text.isNotEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F4F4F4'),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Observações',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(observacoesController.text),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Função para o relatório fotográfico
  pw.Widget buildPhotoReport(List<Map<String, dynamic>> imagesBytes) {
    return pw.Wrap(
      spacing: 5,
      runSpacing: 5,
      children:
          imagesBytes.where((imageData) => imageData['bytes'] != null).map((
            imageData,
          ) {
            return pw.Container(
              width: (PdfPageFormat.a4.width - 120) / 2,
              height: 192,
              padding: const pw.EdgeInsets.all(0),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F4F4F4'),
                //borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Stack(
                children: [
                  pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(imageData['bytes']),
                      fit: pw.BoxFit.fitHeight,
                    ),
                  ),
                  //     pw.Positioned(
                  // bottom: 0,
                  // left: 0,
                  // right: 0,
                  // child: pw.Container(
                  //   padding: const pw.EdgeInsets.all(5),
                  //   decoration: pw.BoxDecoration(
                  //     color: PdfColor.fromHex('#E0E0E0'),// Fundo cinza claro
                  //     borderRadius: pw.BorderRadius.only(
                  //       bottomLeft: pw.Radius.circular(0),
                  //       bottomRight: pw.Radius.circular(0),
                  //     ),
                  //   ),
                  //   child: pw.Text(
                  //     'Registrado em: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(imageData['timestamp'])}',
                  //     style: pw.TextStyle(
                  //       fontSize: 9,
                  //       color: PdfColors.black,
                  //     ),
                  //     textAlign: pw.TextAlign.center,
                  //   ),
                  // ),
                  //     ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // --- Página 1 - Dados do carregamento ---
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (pw.Context context) => buildHeader(),
      footer: (pw.Context context) => buildFooter(),
      build:
          (pw.Context context) => [
            pw.SizedBox(height: 10),
            buildContent(),
            pw.SizedBox(height: 10),
          ],
    ),
  );

  // Função para gerar blocos de 4 imagens por página
  List<List<Map<String, dynamic>>> chunkImages(
    List<Map<String, dynamic>> list,
    int chunkSize,
  ) {
    List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  // --- Páginas com fotos (6 imagens por página) ---
  if (imagesBytes.isNotEmpty) {
    final imageChunks = chunkImages(imagesBytes, 6); // Dividir em blocos de 6

    for (var chunk in imageChunks) {
      pdf.addPage(
        pw.MultiPage(
          header: (pw.Context context) => buildHeader(),
          footer: (pw.Context context) => buildFooter(),
          pageFormat: PdfPageFormat.a4,
          build:
              (pw.Context context) => [
                pw.SizedBox(height: 15),
                pw.Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children:
                      chunk.map((imageData) {
                        return pw.Container(
                          width: (PdfPageFormat.a4.width - 120) / 2,
                          height: 192,
                          padding: const pw.EdgeInsets.all(0),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F4F4F4'),
                            //borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Stack(
                            children: [
                              pw.Center(
                                child: pw.Image(
                                  pw.MemoryImage(imageData['bytes']),
                                  fit: pw.BoxFit.fitHeight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
                pw.SizedBox(height: 15),
              ],
        ),
      );
    }
  }

  // --- Página 2 - Relatório fotográfico ---
  /*  if (imagesBytes.isNotEmpty) {
    pdf.addPage(
      pw.MultiPage(
        header: (pw.Context context) => buildHeader(),
        footer: (pw.Context context) => buildFooter(),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.SizedBox(height: 15),
          buildPhotoReport(imagesBytes),
          pw.SizedBox(height: 15),
        ],
      ),
    );
  }*/

  // --- Salvar e abrir PDF ---
  // final Directory tempDir = await getTemporaryDirectory();
  // final String tempPath = tempDir.path;
  // final String filePath = '$tempPath/${prefixoController.text}-2025.pdf';
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  final Directory reportsDir = Directory('${appDocDir.path}/relatorios');

  if (!(await reportsDir.exists())) {
    await reportsDir.create(recursive: true);
  }

  final String filePath =
      '${reportsDir.path}/${prefixoController.text}-${DateTime.now()}.pdf';
  final File file = File(filePath);
  file.writeAsBytesSync(await pdf.save());

  await OpenFile.open(filePath);

  final uuid = const Uuid();
  final prefs = await SharedPreferences.getInstance();

  final reportData = FullReportModel(
    id: uuid.v4(),
    status: 1, // status 1 para "Concluido"
    prefixo: prefixoController.text,
    terminal: selectedTerminal ?? '',
    produto: selectedProduto ?? '',
    colaborador: colaborador ?? '',
    fornecedor: fornecedor ?? '',
    tipoVagao: selectedValue ?? '',
    dataInicio: dataInicioController.text,
    horarioInicio: horarioInicioController.text,
    dataTermino: dataTerminoController.text,
    horarioTermino: horarioTerminoController.text,
    horarioChegada: horarioChegadaController.text,
    horarioSaida: horarioSaidaController.text,
    houveContaminacao: houveContaminacao ?? false,
    contaminacaoDescricao: contaminacaoDescricao,
    materialHomogeneo: materialHomogeneo ?? '',
    umidadeVisivel: umidadeVisivel ?? '',
    houveChuva: houveChuva ?? '',
    fornecedorAcompanhou: fornecedorAcompanhou ?? '',
    observacoes: observacoesController.text,
    imagens: images.map((img) => img['file'].path.toString()).toList(),
    pathPdf: filePath,
    dataCriacao: DateTime.now(),
  );

  // Salva no SharedPreferences
  final savedReports = prefs.getStringList('full_reports') ?? [];
  savedReports.add(jsonEncode(reportData.toJson()));
  await prefs.setStringList('full_reports', savedReports);
}

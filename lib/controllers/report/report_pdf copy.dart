import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PdfReport {
  static Future<void> generatePdf(String htmlContent) async {
    final Directory tempDir = await getTemporaryDirectory();
    
    final String tempPath = tempDir.path;
    final String filePath = '$tempPath/relatorio_carga.pdf';

    await FlutterHtmlToPdf.convertFromHtmlContent(
      htmlContent,
      tempPath,
      "relatorio_carga",
    );

    print("Relatório PDF gerado em: $filePath");
     
    // Abra o PDF automaticamente (opcional)
    //await OpenFile.open(filePath);

    // Compartilhe o PDF (opcional)
    Share.shareXFiles(<XFile>[XFile(filePath)]);
  }
}

class GerarPdf {
  static Future<void> criaPDF(
    TextEditingController prefixoController,
    String? selectedTerminal,
    String? selectedProduto,
    String? colaborador,
    String? selectedValue,
    TextEditingController dataInicioController,
    TextEditingController horarioChegadaController,
    TextEditingController horarioInicioController,
    TextEditingController horarioTerminoController,
    TextEditingController horarioSaidaController,
    TextEditingController dataTerminoController,
    bool? houveContaminacao,
    String contaminacaoDescricao,
    String? materialHomogeneo,
    String? umidadeVisivel,
    String? houveChuva,
    String? fornecedorAcompanhou,
    TextEditingController observacoesController,
    List<Map<String, dynamic>> images,
  ) async {

    String imagensHtml = images.map((imagem) {
      return '''
      <div class="section-img" style="width: 49%;">
          <img src="file://${imagem['file'].path}" width="100%" height="250px" style="border-radius: 12px 12px 0 0; object-fit: contain;">
          <div style="padding: 5px 10px;"><small><strong>Criado: </strong>${imagem['timestamp']}</small></div>
      </div>
      ''';
    }).join();

    String html = '''
    <!DOCTYPE html>
    <html lang="pt-BR">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Relatório de Carga</title>
        <style>
            body { font-family: Poppins, sans-serif; margin: 0; padding: 10px; font-size: 0.9em; }
            .header { background-color: #003C92; color: white; padding: 20px; display: flex; align-items: center; border-radius: 12px; }
            .header img { height: 30px; margin-right: 20px; }
            .header h1 { width: 80%; font-size: 1.4em; margin: 0; font-weight: 600; }
            .container { max-width: 900px; margin: auto; padding: 20px; }
            .section { background-color: #F4F4F4; padding: 5px 15px; border-radius: 12px; margin-bottom: 20px; }
            .data-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
            .footer { background-color: #84B702; color: white; text-align: center; padding: 10px; font-size: 0.9em; border-radius: 12px; }
        </style>
    </head>

    <body>
        <div class="header" style="background-color: #F4F4F4;">
            <img src="https://image.makewebeasy.net/makeweb/m_1920x0/q38JPjB7j/DefaultData/TCIS.png" alt="TCIS Logo" style="filter: brightness(0) invert(1);">
            <h1 style="text-align: center;">RELATÓRIO ANALÍTICO DE CARGA</h1>
            <small>${prefixoController.text}</small>
        </div>

        <div class="container">
            <div class="section">
                <div style="display: flex; justify-content: space-between;">
                    <div style="flex: 1; margin-right: 10px;">
                        <p><strong>Cliente:</strong> CSN MINERAÇÃO</p>
                        <p><strong>Terminal:</strong> ${selectedTerminal ?? ''}</p>
                        <p><strong>Inspetor:</strong> ${colaborador ?? ''}</p>
                    </div>
                    <div style="flex: 1; margin-left: 10px;">
                        <p><strong>Prefixo:</strong> ${prefixoController.text}</p>
                        <p><strong>Produto:</strong> ${selectedProduto ?? ''}</p>
                        <p><strong>Gerência:</strong> ${selectedValue ?? ''}</p>
                    </div>
                </div>
            </div>

            <div class="section">
                <h3>Dados do Carregamento</h3>
                <table class="data-table">
                    <tr><td><strong>Data:</strong> ${dataInicioController.text}</td></tr>
                    <tr><td><strong>Hora Início:</strong> ${horarioInicioController.text}</td>
                    <td><strong>Hora Término:</strong> ${horarioTerminoController.text}</td></tr>
                    <tr><td><strong>Hora Chegada:</strong> ${horarioChegadaController.text}</td>
                    <td><strong>Hora Saída:</strong> ${horarioSaidaController.text}</td></tr>
                    <tr><td><strong>Tipo Vagão:</strong> GDT</td></tr>
                    <tr><td><strong>Houve Acompanhamento do Fornecedor?</strong> ${fornecedorAcompanhou ?? ''}</td></tr>
                </table>
            </div>

            <div class="section">
                <h3>Observações</h3>
                <p>${observacoesController.text}</p>
            </div>

            <div>
                <h3>Relatório Fotográfico</h3>
                <div style="display: flex; justify-content: space-between; flex-wrap: wrap; flex-direction: row; gap: 5px">
                    $imagensHtml
                </div>
            </div>
        </div>

        <div class="footer">
            <p>TCIS DO BRASIL INSPEÇÃO E CERTIFICAÇÃO LTDA</p>
            <p style="font-size: 0.8em;">Rua Almeida de Moraes, 164 - Conj.51 Santos, SP/ Brazil</p>
        </div>
    </body>
    </html>''';

    await PdfReport.generatePdf(html);
  }
}

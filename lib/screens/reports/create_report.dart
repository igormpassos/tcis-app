import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tcis_app/constants.dart';
import 'package:tcis_app/utils/utils.dart';
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:tcis_app/components/custom_loading_dialog.dart';
import 'package:tcis_app/widgets/reports/dados_relatorio_card.dart';
import 'package:tcis_app/widgets/reports/dados_locomotiva_card.dart';
import 'package:tcis_app/widgets/reports/dados_carregamento_card.dart';

class ReportEntryScreen extends StatefulWidget {
  const ReportEntryScreen({super.key});

  @override
  State<ReportEntryScreen> createState() => _ReportEntryScreenState();
}

class _ReportEntryScreenState extends State<ReportEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _images =
      []; // Lista para armazenar as imagens e metadados

  // Função para selecionar várias imagens da galeria
  Future<void> _addImage() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const CustomLoadingDialog(message: "Carregando imagens..."),
    );

    try {
      final newImages = await ImageUtils.pickImagesWithMetadata();
      if (newImages.isNotEmpty) {
        setState(() => _images.addAll(newImages));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar imagens: $e')));
    } finally {
      Navigator.of(context).pop();
    }
  }

  // Função para remover uma imagem
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // Controllers and variables to store form data
  final TextEditingController prefixoController = TextEditingController();
  String? selectedTerminal;
  String? selectedProduto;
  String? selectedVagao;
  String? colaborador;
  String? selectedValue;
  final TextEditingController dataInicioController = TextEditingController();
  final TextEditingController horarioChegadaController =
      TextEditingController();
  final TextEditingController horarioInicioController = TextEditingController();
  final TextEditingController horarioTerminoController =
      TextEditingController();
  final TextEditingController horarioSaidaController = TextEditingController();
  final TextEditingController dataTerminoController = TextEditingController();
  bool? houveContaminacao;
  String contaminacaoDescricao = '';
  String? materialHomogeneo;
  String? umidadeVisivel;
  String? houveChuva;
  String? fornecedorAcompanhou;
  final TextEditingController observacoesController = TextEditingController();

  Future<void> onSubmitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Mostrar loading usando componente
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const CustomLoadingDialog(message: "Gerando relatório..."),
      );

      try {
        await generatePdf(
          prefixoController: prefixoController,
          selectedTerminal: selectedTerminal,
          selectedProduto: selectedProduto,
          selectedVagao: selectedVagao,
          colaborador: colaborador,
          selectedValue: selectedValue,
          dataInicioController: dataInicioController,
          horarioChegadaController: horarioChegadaController,
          horarioInicioController: horarioInicioController,
          horarioTerminoController: horarioTerminoController,
          horarioSaidaController: horarioSaidaController,
          dataTerminoController: dataTerminoController,
          houveContaminacao: houveContaminacao,
          contaminacaoDescricao: contaminacaoDescricao,
          materialHomogeneo: materialHomogeneo,
          umidadeVisivel: umidadeVisivel,
          houveChuva: houveChuva,
          fornecedorAcompanhou: fornecedorAcompanhou,
          observacoesController: observacoesController,
          images: _images,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao gerar relatório: $e")));
      } finally {
        Navigator.of(context).pop(); // Fecha o loading
      }
    }
  }

  Future<void> saveDraft() async {
    final uuid = const Uuid();
    final prefs = await SharedPreferences.getInstance();

    final reportData = FullReportModel(
      id: uuid.v4(),
      prefixo: prefixoController.text,
      terminal: selectedTerminal ?? '',
      produto: selectedProduto ?? '',
      colaborador: colaborador ?? '',
      tipoVagao: selectedValue ?? '',
      dataInicio: dataInicioController.text,
      horarioInicio: horarioInicioController.text,
      dataTermino: dataTerminoController.text,
      horarioTermino: horarioTerminoController.text,
      horarioChegada: horarioChegadaController.text,
      horarioSaida: horarioSaidaController.text,
      houveContaminacao: houveContaminacao,
      contaminacaoDescricao: contaminacaoDescricao,
      materialHomogeneo: materialHomogeneo ?? '',
      umidadeVisivel: umidadeVisivel ?? '',
      houveChuva: houveChuva ?? '',
      fornecedorAcompanhou: fornecedorAcompanhou ?? '',
      observacoes: observacoesController.text,
      imagens: _images.map((img) => img['file'].path.toString()).toList(),
      pathPdf: '', // ainda não foi gerado
      dataCriacao: DateTime.now(),
      status: 0, // Rascunho
    );

    final savedReports = prefs.getStringList('full_reports') ?? [];
    savedReports.add(jsonEncode(reportData.toJson()));
    await prefs.setStringList('full_reports', savedReports);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Rascunho salvo com sucesso.')));

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Criar Relatório'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Salvar',
              onPressed: saveDraft,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DadosRelatorioCard(
                    prefixoController: prefixoController,
                    selectedTerminal: selectedTerminal,
                    onTerminalChanged:
                        (value) => setState(() => selectedTerminal = value),
                    colaborador: colaborador,
                    onColaboradorChanged:
                        (value) => setState(() => colaborador = value),
                    selectedProduto: selectedProduto,
                    onProdutoChanged:
                        (value) => setState(() => selectedProduto = value),
                  ),

                  const SizedBox(height: 16),
                  DadosLocomotivaCard(
                    horarioChegadaController: horarioChegadaController,
                    horarioSaidaController: horarioSaidaController,
                    selectedVagao: selectedVagao,
                    onVagaoChanged:
                        (value) => setState(() => selectedVagao = value),
                    onSelectTime:
                        (controller) => selectTime(
                          context: context,
                          controller: horarioInicioController,
                          primaryColor: colorPrimary,
                        ),
                  ),

                  const SizedBox(height: 16),
                  DadosCarregamentoCard(
                    dataInicioController: dataInicioController,
                    horarioInicioController: horarioInicioController,
                    dataTerminoController: dataTerminoController,
                    horarioTerminoController: horarioTerminoController,
                    houveContaminacao: houveContaminacao,
                    onContaminacaoChanged:
                        (val) => setState(() => houveContaminacao = val),
                    contaminacaoDescricao: contaminacaoDescricao,
                    onDescricaoChanged:
                        (val) => setState(() => contaminacaoDescricao = val),
                    materialHomogeneo: materialHomogeneo,
                    onMaterialChanged:
                        (val) => setState(() => materialHomogeneo = val),
                    umidadeVisivel: umidadeVisivel,
                    onUmidadeChanged:
                        (val) => setState(() => umidadeVisivel = val),
                    houveChuva: houveChuva,
                    onChuvaChanged: (val) => setState(() => houveChuva = val),
                    fornecedorAcompanhou: fornecedorAcompanhou,
                    onFornecedorChanged:
                        (val) => setState(() => fornecedorAcompanhou = val),
                    observacoesController: observacoesController,
                    images: _images,
                    onAddImage: _addImage,
                    onRemoveImage: _removeImage,
                    onSelectDate:
                        (controller) => selectDate(
                          context: context,
                          controller: controller,
                          primaryColor: colorPrimary,
                        ),

                    onSelectTime:
                        (controller) => selectTime(
                          context: context,
                          controller: horarioInicioController,
                          primaryColor: colorPrimary,
                        ),
                  ),

                  const SizedBox(height: 16),

                  Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Finalizar e Gerar PDF'),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            await onSubmitForm();
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Relatório enviado com sucesso!'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar em Rascunho'),
                        onPressed: saveDraft,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tcis_app/constants.dart';
import 'package:tcis_app/utils/utils.dart';
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:tcis_app/components/custom_loading_dialog.dart';
import 'package:tcis_app/controllers/report/report_mananger.dart';
import 'package:tcis_app/widgets/reports/dados_relatorio_card.dart';
import 'package:tcis_app/widgets/reports/dados_locomotiva_card.dart';
import 'package:tcis_app/widgets/reports/dados_carregamento_card.dart';

class EditReportScreen extends StatefulWidget {
  final FullReportModel report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _images = [];

  final TextEditingController prefixoController = TextEditingController();
  final TextEditingController dataInicioController = TextEditingController();
  final TextEditingController horarioChegadaController =
      TextEditingController();
  final TextEditingController horarioInicioController = TextEditingController();
  final TextEditingController horarioTerminoController =
      TextEditingController();
  final TextEditingController horarioSaidaController = TextEditingController();
  final TextEditingController dataTerminoController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();

  String? selectedTerminal;
  String? selectedProduto;
  String? selectedVagao;
  String? colaborador;
  String? fornecedor;
  String? selectedValue;
  bool? houveContaminacao;
  String contaminacaoDescricao = '';
  String? materialHomogeneo;
  String? umidadeVisivel;
  String? houveChuva;
  String? fornecedorAcompanhou;

  void limparDropdownsVazios() {
    if (selectedTerminal?.isEmpty ?? false) selectedTerminal = null;
    if (selectedProduto?.isEmpty ?? false) selectedProduto = null;
    if (selectedValue?.isEmpty ?? false) selectedValue = null;
    if (selectedVagao?.isEmpty ?? false) selectedVagao = null;
    if (colaborador?.isEmpty ?? false) colaborador = null;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.report;
    prefixoController.text = r.prefixo;
    selectedTerminal = r.terminal;
    selectedProduto = r.produto;
    colaborador = r.colaborador;
    fornecedor = r.fornecedor;
    selectedValue = r.tipoVagao;
    dataInicioController.text = r.dataInicio;
    horarioInicioController.text = r.horarioInicio;
    dataTerminoController.text = r.dataTermino;
    horarioTerminoController.text = r.horarioTermino;
    horarioChegadaController.text = r.horarioChegada;
    horarioSaidaController.text = r.horarioSaida;
    houveContaminacao = r.houveContaminacao;
    contaminacaoDescricao = r.contaminacaoDescricao;
    materialHomogeneo = r.materialHomogeneo;
    umidadeVisivel = r.umidadeVisivel;
    houveChuva = r.houveChuva;
    fornecedorAcompanhou = r.fornecedorAcompanhou;
    observacoesController.text = r.observacoes;

    limparDropdownsVazios();

    for (var path in r.imagens) {
      final file = File(path);
      if (file.existsSync()) {
        _images.add({'file': file, 'timestamp': file.lastModifiedSync()});
      }
    }
  }

  Future<void> saveAsDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedReport = widget.report.copyWith(
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
      imagens: _images.map((img) => img['file'].path.toString()).toList(),
      status: 0,
    );

    final existing = prefs.getStringList('full_reports') ?? [];
    final updated =
        existing.where((e) => !e.contains(widget.report.id)).toList();
    updated.add(jsonEncode(updatedReport.toJson()));
    await prefs.setStringList('full_reports', updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rascunho atualizado com sucesso!')),
    );
    Navigator.pop(context);
  }

  Future<void> generateFinalReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const CustomLoadingDialog(message: "Gerando relatório..."),
    );

    try {
      final updatedBase = widget.report.copyWith(
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
        imagens: _images.map((img) => img['file'].path.toString()).toList(),
        status: 1,
        dataCriacao: DateTime.now(),
      );

      final pdfPath = await generatePdf(
        prefixoController: prefixoController,
        selectedTerminal: selectedTerminal,
        selectedProduto: selectedProduto,
        selectedVagao: selectedVagao,
        colaborador: colaborador,
        fornecedor: fornecedor,
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

      // Salva o relatório final com o path atualizado
      final updatedFinal = updatedBase.copyWith(pathPdf: pdfPath);
      await saveOrUpdateReport(updatedFinal);

      if (mounted) {
        Navigator.of(context).pop(); // fecha loading
        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        ); // volta para a home
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // fecha loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao gerar relatório: $e")));
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(prefixoController.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Salvar Rascunho',
            onPressed: saveAsDraft,
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
                      (val) => setState(() => selectedTerminal = val),
                  colaborador: colaborador,
                  onColaboradorChanged:
                      (val) => setState(() => colaborador = val),
                  selectedProduto: selectedProduto,
                  onProdutoChanged:
                      (val) => setState(() => selectedProduto = val),
                  fornecedor: fornecedor,
                  onFornecedorChanged:
                      (val) => setState(() => fornecedor = val),
                ),
                const SizedBox(height: 16),
                DadosLocomotivaCard(
                  horarioChegadaController: horarioChegadaController,
                  horarioSaidaController: horarioSaidaController,
                  selectedVagao: selectedVagao,
                  onVagaoChanged: (val) => setState(() => selectedVagao = val),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Gerar PDF'),
                        onPressed: generateFinalReport,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar Rascunho'),
                        onPressed: saveAsDraft,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

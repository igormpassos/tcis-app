
import 'package:intl/intl.dart';

class FullReportModel {
  final String id;
  final String prefixo;
  final String terminal;
  final String produto;
  final String colaborador;
  final String? fornecedor;
  final String? tipoVagao;
  final String dataInicio;
  final String horarioInicio;
  final String dataTermino;
  final String horarioTermino;
  final String horarioChegada;
  final String horarioSaida;
  final bool? houveContaminacao;
  final String contaminacaoDescricao;
  final String materialHomogeneo;
  final String umidadeVisivel;
  final String houveChuva;
  final String fornecedorAcompanhou;
  final String observacoes;
  final List<String> imagens; // caminhos locais, se quiser salvar
  final String pathPdf;
  final DateTime dataCriacao;
  final int status; // 0: rascunho (local), 1: finalizado, 2: revisão, 3: enviado

  FullReportModel({
    required this.id,
    required this.prefixo,
    required this.terminal,
    required this.produto,
    required this.colaborador,
    this.fornecedor,
    this.tipoVagao,
    required this.dataInicio,
    required this.horarioInicio,
    required this.dataTermino,
    required this.horarioTermino,
    required this.horarioChegada,
    required this.horarioSaida,
    this.houveContaminacao,
    required this.contaminacaoDescricao,
    required this.materialHomogeneo,
    required this.umidadeVisivel,
    required this.houveChuva,
    required this.fornecedorAcompanhou,
    required this.observacoes,
    required this.imagens,
    required this.pathPdf,
    required this.dataCriacao,
    required this.status, // 0: rascunho (local), 1: finalizado, 2: revisão, 3: enviado
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prefixo': prefixo,
      'terminal': terminal,
      'produto': produto,
      'colaborador': colaborador,
      'fornecedor': fornecedor,
      'tipoVagao': tipoVagao,
      'dataInicio': dataInicio,
      'horarioInicio': horarioInicio,
      'dataTermino': dataTermino,
      'horarioTermino': horarioTermino,
      'horarioChegada': horarioChegada,
      'horarioSaida': horarioSaida,
      'houveContaminacao': houveContaminacao,
      'contaminacaoDescricao': contaminacaoDescricao,
      'materialHomogeneo': materialHomogeneo,
      'umidadeVisivel': umidadeVisivel,
      'houveChuva': houveChuva,
      'fornecedorAcompanhou': fornecedorAcompanhou,
      'observacoes': observacoes,
      'imagens': imagens,
      'pathPdf': pathPdf,
      'dataCriacao': dataCriacao.toIso8601String(),
      'status': status,
    };
  }

  factory FullReportModel.fromJson(Map<String, dynamic> json) {
    return FullReportModel(
      id: json['id'],
      prefixo: json['prefixo'],
      terminal: json['terminal'],
      produto: json['produto'],
      colaborador: json['colaborador'],
      fornecedor: json['fornecedor'],
      tipoVagao: json['tipoVagao'],
      dataInicio: json['dataInicio'],
      horarioInicio: json['horarioInicio'],
      dataTermino: json['dataTermino'],
      horarioTermino: json['horarioTermino'],
      horarioChegada: json['horarioChegada'],
      horarioSaida: json['horarioSaida'],
      houveContaminacao: json['houveContaminacao'],
      contaminacaoDescricao: json['contaminacaoDescricao'],
      materialHomogeneo: json['materialHomogeneo'],
      umidadeVisivel: json['umidadeVisivel'],
      houveChuva: json['houveChuva'],
      fornecedorAcompanhou: json['fornecedorAcompanhou'],
      observacoes: json['observacoes'],
      imagens: List<String>.from(json['imagens']),
      pathPdf: json['pathPdf'],
      dataCriacao: DateTime.parse(json['dataCriacao']),
      status: json['status'] ?? 0, // ou qualquer valor padrão como -1
    );
  }

    // Factory para criar a partir de dados do servidor
  factory FullReportModel.fromServerData(Map<String, dynamic> serverData) {
    // Converter datas do servidor (vêm em UTC, precisa converter para horário local)
    DateTime? startDateTime = serverData['startDateTime'] != null 
        ? DateTime.parse(serverData['startDateTime']).toLocal()
        : DateTime.now();
    DateTime? endDateTime = serverData['endDateTime'] != null 
        ? DateTime.parse(serverData['endDateTime']).toLocal()
        : DateTime.now();
    DateTime? arrivalDateTime = serverData['arrivalDateTime'] != null 
        ? DateTime.parse(serverData['arrivalDateTime']).toLocal()
        : DateTime.now();
    DateTime? departureDateTime = serverData['departureDateTime'] != null 
        ? DateTime.parse(serverData['departureDateTime']).toLocal()
        : DateTime.now();
    DateTime createdAt = serverData['createdAt'] != null 
        ? DateTime.parse(serverData['createdAt']).toLocal()
        : DateTime.now();

    return FullReportModel(
      id: serverData['id'] ?? '',
      prefixo: serverData['prefix'] ?? '',
      terminal: serverData['terminal'] != null 
          ? '${serverData['terminal']['code']} - ${serverData['terminal']['name']}'
          : '',
      produto: serverData['product']?['name'] ?? '',
      colaborador: serverData['user']?['name'] ?? '',
      fornecedor: serverData['supplier']?['name'],
      tipoVagao: serverData['wagonType'] ?? '',
      dataInicio: DateFormat('dd/MM/yyyy').format(startDateTime),
      horarioInicio: startDateTime.toIso8601String().split('T').last.substring(0, 5),
      dataTermino: DateFormat('dd/MM/yyyy').format(endDateTime),
      horarioTermino: endDateTime.toIso8601String().split('T').last.substring(0, 5),
      horarioChegada: arrivalDateTime.toIso8601String().split('T').last.substring(0, 5),
      horarioSaida: departureDateTime.toIso8601String().split('T').last.substring(0, 5),
      houveContaminacao: serverData['hasContamination'],
      contaminacaoDescricao: serverData['contaminationDescription'] ?? '',
      materialHomogeneo: serverData['homogeneousMaterial'] ?? '',
      umidadeVisivel: serverData['visibleMoisture'] ?? '',
      houveChuva: serverData['rainOccurred'] ?? '',
      fornecedorAcompanhou: serverData['supplierAccompanied'] ?? '',
      observacoes: serverData['observations'] ?? '',
      imagens: List<String>.from(serverData['imageUrls'] ?? []),
      pathPdf: serverData['pdfUrl'] ?? '',
      dataCriacao: createdAt,
      status: serverData['status'] ?? 1,
    );
  }

  FullReportModel copyWith({
    String? id,
    String? prefixo,
    String? terminal,
    String? produto,
    String? colaborador,
    String? fornecedor,
    String? tipoVagao,
    String? dataInicio,
    String? horarioInicio,
    String? dataTermino,
    String? horarioTermino,
    String? horarioChegada,
    String? horarioSaida,
    bool? houveContaminacao,
    String? contaminacaoDescricao,
    String? materialHomogeneo,
    String? umidadeVisivel,
    String? houveChuva,
    String? fornecedorAcompanhou,
    String? observacoes,
    List<String>? imagens,
    String? pathPdf,
    DateTime? dataCriacao,
    int? status,
  }) {
    return FullReportModel(
      id: id ?? this.id,
      prefixo: prefixo ?? this.prefixo,
      terminal: terminal ?? this.terminal,
      produto: produto ?? this.produto,
      colaborador: colaborador ?? this.colaborador,
      fornecedor: fornecedor ?? this.fornecedor,
      tipoVagao: tipoVagao ?? this.tipoVagao,
      dataInicio: dataInicio ?? this.dataInicio,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      dataTermino: dataTermino ?? this.dataTermino,
      horarioTermino: horarioTermino ?? this.horarioTermino,
      horarioChegada: horarioChegada ?? this.horarioChegada,
      horarioSaida: horarioSaida ?? this.horarioSaida,
      houveContaminacao: houveContaminacao ?? this.houveContaminacao,
      contaminacaoDescricao:
          contaminacaoDescricao ?? this.contaminacaoDescricao,
      materialHomogeneo: materialHomogeneo ?? this.materialHomogeneo,
      umidadeVisivel: umidadeVisivel ?? this.umidadeVisivel,
      houveChuva: houveChuva ?? this.houveChuva,
      fornecedorAcompanhou: fornecedorAcompanhou ?? this.fornecedorAcompanhou,
      observacoes: observacoes ?? this.observacoes,
      imagens: imagens ?? this.imagens,
      pathPdf: pathPdf ?? this.pathPdf,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      status: status ?? this.status,
    );
  }
}

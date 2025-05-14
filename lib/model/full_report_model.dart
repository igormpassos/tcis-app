import 'dart:convert';

class FullReportModel {
  final String id;
  final String prefixo;
  final String terminal;
  final String produto;
  final String colaborador;
  final String? tipoVagao;
  final String dataInicio;
  final String horarioInicio;
  final String dataTermino;
  final String horarioTermino;
  final String horarioChegada;
  final String horarioSaida;
  final bool houveContaminacao;
  final String contaminacaoDescricao;
  final String materialHomogeneo;
  final String umidadeVisivel;
  final String houveChuva;
  final String fornecedorAcompanhou;
  final String observacoes;
  final List<String> imagens; // caminhos locais, se quiser salvar
  final String pathPdf;
  final DateTime dataCriacao;
  final int status; // novo campo

  FullReportModel({
    required this.id,
    required this.prefixo,
    required this.terminal,
    required this.produto,
    required this.colaborador,
    this.tipoVagao,
    required this.dataInicio,
    required this.horarioInicio,
    required this.dataTermino,
    required this.horarioTermino,
    required this.horarioChegada,
    required this.horarioSaida,
    required this.houveContaminacao,
    required this.contaminacaoDescricao,
    required this.materialHomogeneo,
    required this.umidadeVisivel,
    required this.houveChuva,
    required this.fornecedorAcompanhou,
    required this.observacoes,
    required this.imagens,
    required this.pathPdf,
    required this.dataCriacao,
    required this.status, // novo campo
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prefixo': prefixo,
      'terminal': terminal,
      'produto': produto,
      'colaborador': colaborador,
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

  FullReportModel copyWith({
    String? id,
    String? prefixo,
    String? terminal,
    String? produto,
    String? colaborador,
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

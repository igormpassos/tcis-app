class DropdownDataService {
  // Simulando dados de um banco ou API

  Future<List<String>> getTerminais() async {
    // No futuro: SELECT nome FROM terminais;
    await Future.delayed(const Duration(milliseconds: 100)); // simula delay
    return [
      'TSA - Terminal Serra Azul',
      'SZD - Sarzedo Velho (Itaminas)',
      'TCS - Terminal Sarzedo Novo',
      'TCM - Terminal Multitudo',
      'TCI - Terminal de Itutinga',
      'Outro',
    ];
  }

  Future<List<String>> getColaboradores() async {
    return [
      'Colaborador 1',
      'Colaborador 2',
      'Colaborador 3',
    ];
  }

  Future<List<String>> getProdutos() async {
    return [
      'Produto 1',
      'Produto 2',
      'Produto 3',
    ];
  }

  Future<List<String>> getVagoes() async {
    return [
      'Vagão 1',
      'Vagão 2',
      'Vagão 3',
      'Vagão 4',
    ];
  }
}

//ImpementarDB
/*
Future<List<String>> getTerminais() async {
  final db = await AppDatabase.instance.database;
  final result = await db.query('terminais');
  return result.map((row) => row['nome'] as String).toList();
}*/

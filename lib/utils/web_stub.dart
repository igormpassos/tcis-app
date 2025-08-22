// Stub file para funcionalidades não suportadas na web
import 'dart:typed_data';

// Mock File para web
class File {
  final String path;
  File(this.path);
  
  // Métodos que não fazem nada na web
  Future<bool> exists() async => false;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<void> writeAsBytes(List<int> bytes) async {}
}

// Mock Directory para web  
class Directory {
  final String path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
  Future<void> create({bool recursive = false}) async {}
}

// Mock path_provider functions
Future<Directory> getApplicationDocumentsDirectory() async {
  return Directory('/web-storage');
}

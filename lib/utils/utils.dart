import 'dart:io';
import 'package:rive/rive.dart';
import 'package:intl/intl.dart';
import 'package:exif/exif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class RiveUtils {
  static SMIBool getRiveInput(
    Artboard artboard, {
    required String stateMachineName,
  }) {
    StateMachineController? controller = StateMachineController.fromArtboard(
      artboard,
      stateMachineName,
    );

    artboard.addController(controller!);

    return controller.findInput<bool>("active") as SMIBool;
  }

  static void chnageSMIBoolState(SMIBool input) {
    input.change(true);
    Future.delayed(const Duration(seconds: 1), () {
      input.change(false);
    });
  }
}

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDateTime(DateTime dateTime) {
  return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
}

class ImageUtils {
  /// Converte imagens HEIC para JPEG se necessário
  static Future<File> convertHeicToJpegIfNeeded(File originalFile) async {
    if (!originalFile.path.toLowerCase().endsWith('.heic')) {
      return originalFile; // Não é HEIC, retorna o arquivo original
    }

    try {
      // Ler os bytes da imagem HEIC
      final imageBytes = await originalFile.readAsBytes();
      
      // Decodificar usando a biblioteca image (suporta HEIC no iOS/macOS nativamente)
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('Não foi possível decodificar imagem HEIC: ${originalFile.path}');
        return originalFile; // Retorna original se não conseguir converter
      }
      
      // Codificar como JPEG com qualidade 85
      final jpegBytes = img.encodeJpg(image, quality: 85);
      
      // Criar arquivo temporário com extensão .jpg
      final tempDir = await getTemporaryDirectory();
      final fileName = originalFile.path.split('/').last.replaceAll('.heic', '.jpg');
      final jpegFile = File('${tempDir.path}/$fileName');
      
      // Escrever bytes JPEG no arquivo
      await jpegFile.writeAsBytes(jpegBytes);
      
      print('Imagem HEIC convertida para JPEG: ${jpegFile.path}');
      return jpegFile;
      
    } catch (e) {
      print('Erro ao converter HEIC para JPEG: $e');
      return originalFile; // Retorna original em caso de erro
    }
  }
  
  static Future<DateTime?> getCreationDate(dynamic file) async {
    try {
      // Para web, não podemos acessar EXIF ou propriedades de arquivo
      if (kIsWeb) {
        return DateTime.now();
      }
      
      // Para plataformas nativas
      if (file is File) {
        final bytes = await file.readAsBytes();
        final tags = await readExifFromBytes(bytes);

        if (tags.containsKey('Image DateTime')) {
          final dateTimeString = tags['Image DateTime']!.printable;
          final parts = dateTimeString.split(' ');
          if (parts.length == 2) {
            final date = parts[0].replaceAll(':', '-');
            final time = parts[1];
            return DateTime.tryParse('$date $time');
          }
        }
      }
    } catch (e) {
      // Se houver erro ao ler EXIF, use a data de modificação do arquivo
      print('Erro ao ler EXIF: $e');
      try {
        if (!kIsWeb && file is File) {
          return file.lastModifiedSync();
        }
      } catch (e2) {
        print('Erro ao obter data de modificação: $e2');
      }
    }
    return DateTime.now();
  }

  static Future<List<Map<String, dynamic>>> pickImagesWithMetadata() async {
    try {
      // Para macOS, usar file_selector para uma experiência melhor
      if (Platform.isMacOS) {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'Imagens',
          extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'heic'], // Incluir HEIC novamente
        );
        
        final files = await openFiles(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
        if (files.isEmpty) return [];

        final List<Map<String, dynamic>> images = [];

        for (final file in files) {
          try {
            final xFile = XFile(file.path);
            File ioFile = File(file.path);
            
            // Converter HEIC para JPEG se necessário
            ioFile = await convertHeicToJpegIfNeeded(ioFile);
            
            if (await ioFile.exists()) {
              final creationDate = await ImageUtils.getCreationDate(ioFile) ?? DateTime.now();
              images.add({
                'file': ioFile, 
                'timestamp': creationDate,
                'path': ioFile.path,
                'xfile': xFile, // Manter referência XFile para compatibilidade
                'wasConverted': ioFile.path != file.path, // Flag para indicar se foi convertida
              });
            }
          } catch (e) {
            print('Erro ao processar imagem ${file.path}: $e');
            // Em caso de erro, ainda adicionar o arquivo original
            images.add({
              'file': File(file.path),
              'timestamp': DateTime.now(),
              'path': file.path,
            });
          }
        }

        return images;
      }
      
      // Para outras plataformas (iOS, Android), usar image_picker
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isEmpty) return [];

      final List<Map<String, dynamic>> images = [];

      for (final pickedFile in pickedFiles) {
        try {
          // Para web, criar um objeto pseudo-File
          if (kIsWeb) {
            images.add({
              'file': pickedFile, // XFile para web
              'timestamp': DateTime.now(),
              'path': pickedFile.name,
            });
          } else {
            File file = File(pickedFile.path);
            
            // Converter HEIC para JPEG se necessário
            file = await convertHeicToJpegIfNeeded(file);
            
            if (await file.exists()) {
              final creationDate =
                  await ImageUtils.getCreationDate(file) ?? DateTime.now();
              images.add({
                'file': file, 
                'timestamp': creationDate,
                'path': file.path,
                'wasConverted': file.path != pickedFile.path, // Flag para indicar se foi convertida
              });
            }
          }
        } catch (e) {
          print('Erro ao processar imagem ${pickedFile.path}: $e');
          // Em caso de erro, ainda adicionar o arquivo original
          images.add({
            'file': kIsWeb ? pickedFile : File(pickedFile.path),
            'timestamp': DateTime.now(),
            'path': pickedFile.path,
          });
        }
      }

      return images;
    } catch (e) {
      print('Erro ao selecionar imagens: $e');
      rethrow;
    }
  }
}

Future<void> selectDate({
  required BuildContext context,
  required TextEditingController controller,
  required Color primaryColor,
}) async {
  // Tentar parsear a data atual do controller
  DateTime initialDate = DateTime.now();
  
  if (controller.text.isNotEmpty) {
    try {
      // Tentar parsear formato brasileiro dd/MM/yyyy
      if (controller.text.contains('/')) {
        final parts = controller.text.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final parsedDate = DateTime(year, month, day);
          
          // Verificar se a data está dentro dos limites permitidos
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          if (parsedDate.isBefore(tomorrow.add(const Duration(days: 1))) && 
              parsedDate.isAfter(DateTime(2000))) {
            initialDate = parsedDate;
          }
        }
      }
      // Tentar parsear formato ISO yyyy-MM-dd
      else if (controller.text.contains('-')) {
        final parsedDate = DateTime.parse(controller.text);
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        if (parsedDate.isBefore(tomorrow.add(const Duration(days: 1))) && 
            parsedDate.isAfter(DateTime(2000))) {
          initialDate = parsedDate;
        }
      }
    } catch (e) {
      // Se falhar ao parsear, usar data atual
      initialDate = DateTime.now();
    }
  }
  
  // Limitar até um dia após a data atual
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: tomorrow, // Limitar até amanhã
    builder: (context, child) => Theme(
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          onSurface: Colors.black,
        ),
      ),
      child: child!,
    ),
  );

  if (pickedDate != null) {
    controller.text = formatDate(pickedDate);
  }
}

Future<void> selectTime({
  required BuildContext context,
  required TextEditingController controller,
  required Color primaryColor,
}) async {
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    initialEntryMode: TimePickerEntryMode.inputOnly,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    ),
  );

  if (pickedTime != null) {
    controller.text =
        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
  }
}

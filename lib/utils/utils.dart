import 'dart:io';
import 'package:rive/rive.dart';
import 'package:intl/intl.dart';
import 'package:exif/exif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

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
  static Future<DateTime?> getCreationDate(File file) async {
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
    return null;
  }

  static Future<List<Map<String, dynamic>>> pickImagesWithMetadata() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isEmpty) return [];

    final List<Map<String, dynamic>> images = [];

    for (final pickedFile in pickedFiles) {
      final file = File(pickedFile.path);
      final creationDate =
          await ImageUtils.getCreationDate(file) ?? DateTime.now();
      images.add({'file': file, 'timestamp': creationDate});
    }

    return images;
  }
}

Future<void> selectDate({
  required BuildContext context,
  required TextEditingController controller,
  required Color primaryColor,
}) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
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

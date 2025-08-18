import 'package:intl/intl.dart';

/// Utilitários para formatação e validação de data/hora
class DateTimeUtils {
  // Formatadores
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  
  /// Combina campos de data e horário separados em um DateTime
  static DateTime? combineDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty || timeStr == null || timeStr.isEmpty) {
      return null;
    }
    
    try {
      DateTime date;
      
      // Suporta tanto formato brasileiro (dd/MM/yyyy) quanto ISO (yyyy-MM-dd)
      if (dateStr.contains('/')) {
        date = _dateFormat.parse(dateStr);
      } else if (dateStr.contains('-')) {
        // Para formato ISO, criar DateTime como horário local, não UTC
        final parts = dateStr.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        date = DateTime(year, month, day);
      } else {
        throw FormatException('Formato de data inválido: $dateStr');
      }
      
      final timeComponents = timeStr.split(':');
      
      if (timeComponents.length != 2) {
        throw FormatException('Formato de hora inválido: $timeStr');
      }
      
      final hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);
      
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      print('Erro ao combinar data/hora: $dateStr $timeStr - $e');
      return null;
    }
  }
  
  /// Converte DateTime para string no formato ISO para envio à API
  static String? toIsoString(DateTime? dateTime) {
    if (dateTime == null) return null;
    return dateTime.toIso8601String();
  }
  
  /// Converte DateTime para formato de data para exibição (dd/MM/yyyy)
  static String? formatDate(DateTime? dateTime) {
    if (dateTime == null) return null;
    return _dateFormat.format(dateTime);
  }
  
  /// Converte DateTime para formato de hora para exibição (HH:mm)
  static String? formatTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return _timeFormat.format(dateTime);
  }
  
  /// Parse de string ISO para DateTime
  static DateTime? fromIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      print('Erro ao fazer parse de ISO string: $isoString - $e');
      return null;
    }
  }
  
  /// Separa um DateTime em data e hora separadas para preenchimento dos campos
  static Map<String, String> separateDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return {'date': '', 'time': ''};
    }
    
    return {
      'date': formatDate(dateTime) ?? '',
      'time': formatTime(dateTime) ?? '',
    };
  }
  
  /// Valida se data/hora de término é posterior à de início
  static bool validateEndAfterStart({
    required String? startDateStr,
    required String? startTimeStr,
    required String? endDateStr,
    required String? endTimeStr,
  }) {
    final startDateTime = combineDateTime(startDateStr, startTimeStr);
    final endDateTime = combineDateTime(endDateStr, endTimeStr);
    
    if (startDateTime == null || endDateTime == null) {
      return true; // Se não há dados suficientes, não valida
    }
    
    return endDateTime.isAfter(startDateTime);
  }
  
  /// Valida se data/hora de término é posterior à de início (usando DateTime)
  static bool validateEndAfterStartDateTime(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return true; // Se não há dados suficientes, não valida
    }
    
    return end.isAfter(start);
  }
  
  /// Mensagem de erro para validação de data/hora
  static String getValidationError({
    required String? startDateStr,
    required String? startTimeStr,
    required String? endDateStr,
    required String? endTimeStr,
  }) {
    final startDateTime = combineDateTime(startDateStr, startTimeStr);
    final endDateTime = combineDateTime(endDateStr, endTimeStr);
    
    if (startDateTime == null) {
      return 'Data/hora de início é obrigatória';
    }
    
    if (endDateTime == null) {
      return 'Data/hora de término é obrigatória';
    }
    
    if (!endDateTime.isAfter(startDateTime)) {
      return 'Data/hora de término deve ser posterior à de início';
    }
    
    return '';
  }
  
  /// Converte dados do formulário para payload da API
  static Map<String, dynamic> formatForApi({
    required String? startDateStr,
    required String? startTimeStr,
    required String? endDateStr,
    required String? endTimeStr,
  }) {
    final startDateTime = combineDateTime(startDateStr, startTimeStr);
    final endDateTime = combineDateTime(endDateStr, endTimeStr);
    
    return {
      'start_datetime': toIsoString(startDateTime),
      'end_datetime': toIsoString(endDateTime),
    };
  }
  
  /// Converte dados da API para preenchimento do formulário
  static Map<String, String> formatFromApi({
    String? startDateTimeStr,
    String? endDateTimeStr,
  }) {
    final startDateTime = fromIsoString(startDateTimeStr);
    final endDateTime = fromIsoString(endDateTimeStr);
    
    final startData = separateDateTime(startDateTime);
    final endData = separateDateTime(endDateTime);
    
    return {
      'start_date': startData['date']!,
      'start_time': startData['time']!,
      'end_date': endData['date']!,
      'end_time': endData['time']!,
    };
  }
}

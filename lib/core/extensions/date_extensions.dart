import 'package:intl/intl.dart';

/// DateTime extensions for common date operations
extension DateExtensions on DateTime {
  /// Format as "dd/MM/yyyy"
  String get formatDate => DateFormat('dd/MM/yyyy').format(this);
  
  /// Format as "HH:mm"
  String get formatTime => DateFormat('HH:mm').format(this);
  
  /// Format as "dd/MM/yyyy HH:mm"
  String get formatDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);
  
  /// Format as "dd MMM yyyy" (e.g., "15 Ene 2024")
  String get formatMedium => DateFormat('dd MMM yyyy', 'es_ES').format(this);
  
  /// Format as "EEEE, d MMMM" (e.g., "Lunes, 15 Enero")
  String get formatLong => DateFormat('EEEE, d MMMM', 'es_ES').format(this);
  
  /// Get relative time string (e.g., "Hace 5 minutos")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes}m';
    if (difference.inDays < 1) return 'Hace ${difference.inHours}h';
    if (difference.inDays < 7) return 'Hace ${difference.inDays}d';
    if (difference.inDays < 30) return 'Hace ${difference.inDays ~/ 7} sem';
    if (difference.inDays < 365) return 'Hace ${difference.inDays ~/ 30} mes';
    return 'Hace ${difference.inDays ~/ 365} año';
  }
  
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  /// Check if date is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
           isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  /// Get start of day (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get end of day (23:59:59)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  
  /// Get start of week (Monday)
  DateTime get startOfWeek {
    final diff = weekday - DateTime.monday;
    return subtract(Duration(days: diff)).startOfDay;
  }
  
  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    final diff = DateTime.sunday - weekday;
    return add(Duration(days: diff)).endOfDay;
  }
}

/// Duration extensions
extension DurationExtensions on Duration {
  /// Format as "mm:ss"
  String get formatMinSec {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  /// Format as "HH:mm:ss"
  String get formatHourMinSec {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
  
  /// Human readable format (e.g., "5 min 30 seg")
  String get humanReadable {
    if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds.remainder(60)}s';
    } else {
      return '${inSeconds}s';
    }
  }
}

import 'dart:convert';

class ShiftEntry {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int breakTimeMinutes;
  final bool isHoliday;
  final double hourlyWage;
  final double totalPay;

  ShiftEntry({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.breakTimeMinutes,
    required this.isHoliday,
    required this.hourlyWage,
    required this.totalPay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'breakTimeMinutes': breakTimeMinutes,
      'isHoliday': isHoliday,
      'hourlyWage': hourlyWage,
      'totalPay': totalPay,
    };
  }

  factory ShiftEntry.fromMap(Map<String, dynamic> map) {
    return ShiftEntry(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date']),
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      breakTimeMinutes: map['breakTimeMinutes']?.toInt() ?? 0,
      isHoliday: map['isHoliday'] ?? false,
      hourlyWage: map['hourlyWage']?.toDouble() ?? 0.0,
      totalPay: map['totalPay']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ShiftEntry.fromJson(String source) => ShiftEntry.fromMap(json.decode(source));
  
  // Helper to get total duration in hours (for display)
  double get totalDurationHours {
     final duration = endTime.difference(startTime);
     return duration.inMinutes / 60.0;
  }
}

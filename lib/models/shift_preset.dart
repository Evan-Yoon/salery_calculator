import 'dart:convert';

class ShiftPreset {
  final String id;
  final String name;
  final String startTime; // "HH:mm" format
  final String endTime; // "HH:mm" format
  final int breakTimeMinutes;
  final double multiplier;
  final String iconType; // 'day', 'night', 'star', 'heart', etc.

  ShiftPreset({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.breakTimeMinutes,
    required this.multiplier,
    required this.iconType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'breakTimeMinutes': breakTimeMinutes,
      'multiplier': multiplier,
      'iconType': iconType,
    };
  }

  factory ShiftPreset.fromMap(Map<String, dynamic> map) {
    return ShiftPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '18:00',
      breakTimeMinutes: map['breakTimeMinutes']?.toInt() ?? 0,
      multiplier: map['multiplier']?.toDouble() ?? 1.0,
      iconType: map['iconType'] ?? 'day',
    );
  }

  String toJson() => json.encode(toMap());

  factory ShiftPreset.fromJson(String source) =>
      ShiftPreset.fromMap(json.decode(source));
}

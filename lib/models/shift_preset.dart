import 'dart:convert';
import 'package:flutter/material.dart';

// [STUDY NOTE]: 근무 프리셋(교대 근무 조)을 저장하기 위한 모델 클래스입니다.
class ShiftPreset {
  final String id;
  final String name; // 예: 데이, 이브닝, 나이트
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int breakTimeMinutes;
  final double
      payMultiplier; // [STUDY NOTE]: 기본 시급 대비 수당 배율 (예: 1.0, 1.25, 1.5)

  ShiftPreset({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.breakTimeMinutes,
    this.payMultiplier = 1.0, // 기본값은 1배수(수당 없음)
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'breakTimeMinutes': breakTimeMinutes,
      'payMultiplier': payMultiplier,
    };
  }

  factory ShiftPreset.fromMap(Map<String, dynamic> map) {
    return ShiftPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      startTime: TimeOfDay(
        hour: map['startHour']?.toInt() ?? 0,
        minute: map['startMinute']?.toInt() ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endHour']?.toInt() ?? 0,
        minute: map['endMinute']?.toInt() ?? 0,
      ),
      breakTimeMinutes: map['breakTimeMinutes']?.toInt() ?? 0,
      payMultiplier: map['payMultiplier']?.toDouble() ?? 1.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ShiftPreset.fromJson(String source) =>
      ShiftPreset.fromMap(json.decode(source));
}

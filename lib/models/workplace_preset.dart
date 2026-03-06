import 'dart:convert';

// [STUDY NOTE]: 근무지별 급여 규정을 저장하는 프리셋 모델입니다.
// 여러 직장(본업, 알바1, 알바2 등)의 설정을 각각 저장하고 빠르게 전환할 수 있습니다.
class WorkplacePreset {
  final String id;
  final String name; // 예: "본업", "알바1", "편의점 알바"

  final double hourlyWage; // 시급
  final bool isFiveOrMoreEmployees; // 5인 이상 사업장 여부 (연장/야간/휴일 수당 적용)
  final double taxRate; // 세율 (0.0, 0.033, 0.094)
  final bool assumeFullAttendance; // 주휴수당 개근 가정 여부
  final double nightShiftMultiplier; // 야간 수당 추가 배율 (기본 0.5 → 1.5배)
  final double holidayMultiplier; // 공휴일 수당 추가 배율 (기본 0.5 → 1.5배)

  WorkplacePreset({
    required this.id,
    required this.name,
    required this.hourlyWage,
    required this.isFiveOrMoreEmployees,
    required this.taxRate,
    required this.assumeFullAttendance,
    required this.nightShiftMultiplier,
    required this.holidayMultiplier,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'hourlyWage': hourlyWage,
        'isFiveOrMoreEmployees': isFiveOrMoreEmployees,
        'taxRate': taxRate,
        'assumeFullAttendance': assumeFullAttendance,
        'nightShiftMultiplier': nightShiftMultiplier,
        'holidayMultiplier': holidayMultiplier,
      };

  factory WorkplacePreset.fromMap(Map<String, dynamic> map) => WorkplacePreset(
        id: map['id'] ?? '',
        name: map['name'] ?? '근무지',
        hourlyWage: (map['hourlyWage'] as num?)?.toDouble() ?? 10320.0,
        isFiveOrMoreEmployees: map['isFiveOrMoreEmployees'] ?? false,
        taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
        assumeFullAttendance: map['assumeFullAttendance'] ?? false,
        nightShiftMultiplier:
            (map['nightShiftMultiplier'] as num?)?.toDouble() ?? 0.5,
        holidayMultiplier:
            (map['holidayMultiplier'] as num?)?.toDouble() ?? 0.5,
      );

  String toJson() => json.encode(toMap());
  factory WorkplacePreset.fromJson(String source) =>
      WorkplacePreset.fromMap(json.decode(source));

  WorkplacePreset copyWith({
    String? id,
    String? name,
    double? hourlyWage,
    bool? isFiveOrMoreEmployees,
    double? taxRate,
    bool? assumeFullAttendance,
    double? nightShiftMultiplier,
    double? holidayMultiplier,
  }) =>
      WorkplacePreset(
        id: id ?? this.id,
        name: name ?? this.name,
        hourlyWage: hourlyWage ?? this.hourlyWage,
        isFiveOrMoreEmployees:
            isFiveOrMoreEmployees ?? this.isFiveOrMoreEmployees,
        taxRate: taxRate ?? this.taxRate,
        assumeFullAttendance: assumeFullAttendance ?? this.assumeFullAttendance,
        nightShiftMultiplier: nightShiftMultiplier ?? this.nightShiftMultiplier,
        holidayMultiplier: holidayMultiplier ?? this.holidayMultiplier,
      );
}

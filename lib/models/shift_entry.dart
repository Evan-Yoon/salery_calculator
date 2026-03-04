// [STUDY NOTE]: 이 파일은 데이터베이스나 앱 내부에서 사용할 '근무 기록(데이터 모델)'을 정의합니다.
import 'dart:convert';

// [STUDY NOTE]: ShiftEntry 클래스는 하나의 근무 기록에 필요한 모든 정보를 담는 상자 역할을 합니다.
class ShiftEntry {
  final String id; // [STUDY NOTE]: 각 근무 기록을 구별하기 위한 고유 식별자입니다.
  final DateTime date; // [STUDY NOTE]: 근무 날짜입니다.
  final DateTime startTime; // [STUDY NOTE]: 근무 시작 시간입니다.
  final DateTime endTime; // [STUDY NOTE]: 근무 종료 시간입니다.
  final int breakTimeMinutes; // [STUDY NOTE]: 휴게 시간(분 단위)입니다. 급여 계산에서 제외됩니다.
  final bool isHoliday; // [STUDY NOTE]: 휴일 근무 여부입니다. (휴일 수당 1.5배 적용을 위함)
  final double hourlyWage; // [STUDY NOTE]: 이 근무를 했을 당시의 시급입니다.
  final double payMultiplier; // [STUDY NOTE]: 이 근무에 적용된 배율 (기본 1.0)
  final double totalPay; // [STUDY NOTE]: 계산된 최종 급여(수당 포함)입니다.

  // [STUDY NOTE]: 생성자(Constructor)입니다. 객체를 만들 때 필수(required)로 값을 받도록 설정했습니다.
  ShiftEntry({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.breakTimeMinutes,
    required this.isHoliday,
    required this.hourlyWage,
    required this.payMultiplier,
    required this.totalPay,
  });

  // [STUDY NOTE]: 객체의 데이터를 Map 형태(키-값 쌍, JSON과 유사)로 변환해주는 함수입니다.
  // 데이터를 휴대폰 저장소(SharedPreferences 등)에 문자열로 저장하기 전 단계로 사용됩니다.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(), // [STUDY NOTE]: 날짜를 문자열로 변환하여 저장합니다.
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'breakTimeMinutes': breakTimeMinutes,
      'isHoliday': isHoliday,
      'hourlyWage': hourlyWage,
      'payMultiplier': payMultiplier,
      'totalPay': totalPay,
    };
  }

  // [STUDY NOTE]: Map 형태의 데이터를 다시 ShiftEntry 객체로 복원해주는 팩토리(Factory) 생성자입니다.
  // 저장소에서 데이터를 불러올 때 사용합니다.
  factory ShiftEntry.fromMap(Map<String, dynamic> map) {
    return ShiftEntry(
      id: map['id'] ?? '',
      date: DateTime.parse(
          map['date']), // [STUDY NOTE]: 문자열 날짜를 다시 DateTime 객체로 변환합니다.
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      breakTimeMinutes: map['breakTimeMinutes']?.toInt() ?? 0,
      isHoliday: map['isHoliday'] ?? false,
      hourlyWage: map['hourlyWage']?.toDouble() ?? 0.0,
      payMultiplier: map['payMultiplier']?.toDouble() ?? 1.0,
      totalPay: map['totalPay']?.toDouble() ?? 0.0,
    );
  }

  // [STUDY NOTE]: Map 데이터를 JSON 형태의 텍스트로 변환합니다.
  String toJson() => json.encode(toMap());

  // [STUDY NOTE]: JSON 텍스트를 Map으로 바꾼 뒤, 다시 ShiftEntry 객체로 변환합니다.
  factory ShiftEntry.fromJson(String source) =>
      ShiftEntry.fromMap(json.decode(source));

  // [STUDY NOTE]: Helper 함수 - 시작 시간과 종료 시간을 비교하여 총 근무 시간을 시간 단위로 계산해 반환합니다. (예: 1시간 30분 -> 1.5)
  // [STUDY NOTE]: 이 값은 단순 화면 표시용이며, 급여 계산 시에는 휴게시간이 제외된 값을 별도로 계산합니다.
  double get totalDurationHours {
    final duration = endTime.difference(startTime);
    return duration.inMinutes / 60.0;
  }
}

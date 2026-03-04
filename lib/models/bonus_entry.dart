// [STUDY NOTE]: 이 파일은 비정기적인 급여(예: 상여금, 성과금, 팁 등)를 기록하기 위한 모델입니다.
import 'dart:convert';

class BonusEntry {
  final String id; // [STUDY NOTE]: 각 상여금 기록을 구분하는 고유 ID입니다.
  final DateTime date; // [STUDY NOTE]: 상여금을 받은 날짜입니다.
  final double amount; // [STUDY NOTE]: 받은 금액입니다.
  final String description; // [STUDY NOTE]: 내역(예: "명절 보너스")에 대한 설명입니다.

  // [STUDY NOTE]: 클래스를 만들 때 꼭 필요한(required) 값들을 받아오도록 설정합니다.
  BonusEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
  });

  // [STUDY NOTE]: 기기에 저장하기 전, 객체를 Map(키와 값 형태)으로 변환하는 함수입니다.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(), // 날짜를 텍스트로 저장합니다.
      'amount': amount,
      'description': description,
    };
  }

  // [STUDY NOTE]: 기기에서 불러온 Map 데이터를 다시 객체로 변환해주는 팩토리(Factory) 생성자입니다.
  factory BonusEntry.fromMap(Map<String, dynamic> map) {
    return BonusEntry(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date']), // 텍스트로 저장된 날짜를 다시 날짜형으로 바꿉니다.
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
    );
  }

  // [STUDY NOTE]: Map 데이터를 JSON 문자열로 변환합니다. SharedPreferences 같은 저장소에 저장할 때 쓰입니다.
  String toJson() => json.encode(toMap());

  // [STUDY NOTE]: JSON 문자열을 받아서 다시 보너스 객체로 만듭니다.
  factory BonusEntry.fromJson(String source) =>
      BonusEntry.fromMap(json.decode(source));
}

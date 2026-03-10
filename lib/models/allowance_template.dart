import 'dart:convert';

// [STUDY NOTE]: 수당 템플릿 모델입니다.
// 사용자가 자주 사용하는 수당 항목(야간수당, 콜수당 등)을 저장해두고 빠르게 재사용할 수 있습니다.
class AllowanceTemplate {
  final String id;
  final String name; // 템플릿 이름 (예: 야간수당, 콜수당)
  final double amount; // 기본 금액
  final bool isFixedAmount; // 고정 금액 여부 (false이면 isPerHour 참조)
  final bool isPerHour; // 시간당 수당 여부 (true: amount × 근무시간)
  final String? note; // 부가 설명
  final bool isActive; // 목록에 표시·사용 여부
  final DateTime createdAt;
  final DateTime updatedAt;

  AllowanceTemplate({
    required this.id,
    required this.name,
    required this.amount,
    required this.isFixedAmount,
    required this.isPerHour,
    this.note,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // 시간당 수당 적용 시 실제 지급액 계산 헬퍼
  double calculateAmount(double workHours) {
    if (isPerHour) return amount * workHours;
    return amount;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'isFixedAmount': isFixedAmount,
        'isPerHour': isPerHour,
        'note': note,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AllowanceTemplate.fromMap(Map<String, dynamic> map) =>
      AllowanceTemplate(
        id: map['id'] ?? '',
        name: map['name'] ?? '수당',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        isFixedAmount: map['isFixedAmount'] ?? true,
        isPerHour: map['isPerHour'] ?? false,
        note: map['note'],
        isActive: map['isActive'] ?? true,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'])
            : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory AllowanceTemplate.fromJson(String source) =>
      AllowanceTemplate.fromMap(json.decode(source));

  AllowanceTemplate copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isFixedAmount,
    bool? isPerHour,
    String? note,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AllowanceTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        isFixedAmount: isFixedAmount ?? this.isFixedAmount,
        isPerHour: isPerHour ?? this.isPerHour,
        note: note ?? this.note,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// 앱 최초 실행 시 제공할 기본 템플릿
List<AllowanceTemplate> get defaultAllowanceTemplates {
  final now = DateTime.now();
  return [
    AllowanceTemplate(
      id: 'default_night_allowance',
      name: '야간수당',
      amount: 5000,
      isFixedAmount: false,
      isPerHour: true,
      note: '22:00~06:00 야간 근무 시 시간당 추가',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AllowanceTemplate(
      id: 'default_special_work',
      name: '특근수당',
      amount: 20000,
      isFixedAmount: true,
      isPerHour: false,
      note: '주말·공휴일 특별 근무 고정 수당',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AllowanceTemplate(
      id: 'default_call_allowance',
      name: '콜수당',
      amount: 3000,
      isFixedAmount: true,
      isPerHour: false,
      note: '호출 1건당 지급 (예시 금액)',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    AllowanceTemplate(
      id: 'default_education_allowance',
      name: '교육수당',
      amount: 10000,
      isFixedAmount: true,
      isPerHour: false,
      note: '사내 교육 참여 시 지급 (예시 금액)',
      isActive: false,
      createdAt: now,
      updatedAt: now,
    ),
    AllowanceTemplate(
      id: 'default_risk_allowance',
      name: '위험수당',
      amount: 2000,
      isFixedAmount: false,
      isPerHour: true,
      note: '위험 업무 종사 시 시간당 추가 (예시)',
      isActive: false,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

class SalaryConstants {
  // [STUDY NOTE]: 앱 전체에서 쓰이는 법정 기준 수치(매직넘버)를 한 곳에 모아둡니다.
  static const double legalWorkHoursPerDay = 8.0;
  static const int nightStartHour = 22;
  static const int nightEndHour = 6;
  static const double overtimeAdditionRate = 0.5; // 기초 연장 근로 가산율
  static const double nightAdditionRate = 0.5; // 기초 야간 근로 가산율
  static const double holidayAdditionRate =
      0.5; // 휴일 근로 가산율 (기본 1.5배에 추가되는 0.5배)
  static const double holidayBaseRate = 1.5; // 휴일 근로 기본 가산율 (8시간 이내)
}

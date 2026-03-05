class SalaryConstants {
  // [STUDY NOTE]: 앱 전체에서 쓰이는 법정 기준 수치(매직넘버)를 한 곳에 모아둡니다.
  static const double legalWorkHoursPerDay = 8.0;
  static const int nightStartHour = 22;
  static const int nightEndHour = 6;
  static const double overtimeRate = 1.5;
  static const double nightRate = 0.5; // 기본급 1.0에 0.5를 가산하는 방식
  static const double holidayOvertimeRate = 2.0; // 8시간 초과 휴일 근로 (1.5 + 0.5)
}

// [STUDY NOTE]: 앱 전체에서 급여를 계산하는 '수학 공식'만 모아둔 유틸리티 클래스입니다.
// UI와 관련이 없는 순수 로직만 들어있어 단위 테스트(Unit Test)를 하기에 좋습니다.
class ShiftCalculator {
  // [STUDY NOTE]: 시작 시간, 종료 시간, 휴게 시간, 휴일 여부, 시급을 입력받아 최종 급여를 계산하는 핵심 공식입니다.
  static double calculateTotalPay({
    required DateTime startTime,
    required DateTime endTime,
    required int breakTimeMinutes,
    required bool isHoliday,
    required double hourlyWage,
    required bool isFiveOrMoreEmployees,
    required double
        payMultiplier, // [STUDY NOTE]: 기본 시급 대비 수당 배율 (예: 1.0, 1.25, 1.5)
  }) {
    // 1. 총 근무 시간 계산
    Duration totalDuration = endTime.difference(startTime);
    int totalMinutes = totalDuration.inMinutes;

    // 2. 실제 근무 시간 (휴게 시간 제외)
    int netMinutes = totalMinutes - breakTimeMinutes;
    if (netMinutes < 0) netMinutes = 0;
    double netHours = netMinutes / 60.0;

    // 3. 기본급 계산
    double basePayRate = isHoliday ? hourlyWage * 1.5 : hourlyWage;
    double basePay = netHours * basePayRate;

    // 4. 연장 수당 (하루 8시간 초과분) - 5인 이상 사업장 적용
    double overtimeHours = 0.0;
    if (isFiveOrMoreEmployees && netHours > 8.0) {
      overtimeHours = netHours - 8.0;
    }
    double overtimeAllowance = overtimeHours * hourlyWage * 0.5;

    // 5. 야간 근무 수당 (22:00 ~ 06:00) - 5인 이상 사업장 적용
    // 기본급에 1.0배가 포함되어 있으므로 여기서는 0.5배만 추가합니다.
    double nightHours = _calculateNightOverlapHours(startTime, endTime);

    // 안전 장치: 야간 근로 시간이 실제 순 근무 시간을 초과할 수 없음.
    if (nightHours > netHours) {
      nightHours = netHours;
    }

    double nightAllowance =
        isFiveOrMoreEmployees ? nightHours * hourlyWage * 0.5 : 0.0;

    // 6. 프리셋 커스텀 수당 (예: 이브닝 1.25배면 0.25배 해당액 추가)
    double customAllowance = 0.0;
    if (payMultiplier > 1.0) {
      customAllowance = basePay * (payMultiplier - 1.0);
    }

    // 주의: 법정 야간/연장 수당과 병원별 커스텀 수당(예: 이브닝 1.25배)이 중복될 수 있습니다.
    // 사용자가 프리셋 수당(1.25배 등)을 적용한다면, 보통 법정 수당을 포괄하는 경우가 많음.
    // 여기서는 법정 수당과 커스텀 수당 중 더 큰 혜택(또는 합산)을 어떻게 정할지는
    // 기본적으로 합산하여 보여주되, 사용자가 '5인 이상 사업장' 옵션을 끄면 커스텀 수당만 적용됩니다.

    return basePay + overtimeAllowance + nightAllowance + customAllowance;
  }

  // [STUDY NOTE]: 밤 10시(22:00)부터 다음 날 아침 6시(06:00) 사이에 근무한 '야간 근로 시간'만을 추려내는 내부용(private) 함수입니다.
  static double _calculateNightOverlapHours(DateTime start, DateTime end) {
    double totalOverlapMinutes = 0.0;

    // 기준일을 상대값으로 야간 시간을 계산합니다.
    // 근무 시간은 보통 24시간보다 짧습니다.
    // 가능한 패턴:
    // 1. 근무 시작일 당일 밤 (시작일 22:00 시작)
    // 2. 근무 시작일 전날 밤 (시작일-1 22:00 시작)
    //    (예: 새벽 01:00 에 출근한 경우)

    // 구간 1 설정: 시작일 22:00 -> 다음날 06:00
    DateTime startDayNightStart =
        DateTime(start.year, start.month, start.day, 22, 0);
    DateTime startDayNightEnd =
        startDayNightStart.add(const Duration(hours: 8)); // 다음날 06:00

    // 구간 2 설정: 전날 22:00 -> 시작일 06:00
    DateTime prevDayNightStart =
        startDayNightStart.subtract(const Duration(days: 1));
    DateTime prevDayNightEnd = prevDayNightStart.add(const Duration(hours: 8));

    // 구간 3 설정: 다음날 22:00 -> 다다음날 06:00
    // (근무 시간이 비정상적으로 긴 경우 대비)
    DateTime nextDayNightStart =
        startDayNightStart.add(const Duration(days: 1));
    DateTime nextDayNightEnd = nextDayNightStart.add(const Duration(hours: 8));

    totalOverlapMinutes +=
        _getOverlapMinutes(start, end, startDayNightStart, startDayNightEnd);
    totalOverlapMinutes +=
        _getOverlapMinutes(start, end, prevDayNightStart, prevDayNightEnd);
    totalOverlapMinutes +=
        _getOverlapMinutes(start, end, nextDayNightStart, nextDayNightEnd);

    return totalOverlapMinutes / 60.0;
  }

  static double _getOverlapMinutes(DateTime rangeStart, DateTime rangeEnd,
      DateTime windowStart, DateTime windowEnd) {
    // 겹치는 부분: Max(시작 시간, 구간 시작) ~ Min(종료 시간, 구간 종료)
    DateTime overlapStart =
        rangeStart.isAfter(windowStart) ? rangeStart : windowStart;
    DateTime overlapEnd = rangeEnd.isBefore(windowEnd) ? rangeEnd : windowEnd;

    if (overlapStart.isBefore(overlapEnd)) {
      return overlapEnd.difference(overlapStart).inMinutes.toDouble();
    }
    return 0.0;
  }
}

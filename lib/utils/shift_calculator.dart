import 'constants.dart';

// [STUDY NOTE]: 기본급 및 휴일 근로 산정을 담당하는 클래스
class BasePayCalculator {
  static double calculate({
    required double netHours,
    required bool isHoliday,
    required double hourlyWage,
    required bool isFiveOrMoreEmployees,
  }) {
    if (isHoliday && isFiveOrMoreEmployees) {
      double regularHolidayHours =
          netHours > SalaryConstants.legalWorkHoursPerDay
              ? SalaryConstants.legalWorkHoursPerDay
              : netHours;
      return regularHolidayHours *
          (hourlyWage * SalaryConstants.holidayBaseRate);
    } else {
      double rate =
          isHoliday ? hourlyWage * SalaryConstants.holidayBaseRate : hourlyWage;
      if (!isFiveOrMoreEmployees) rate = hourlyWage;
      return netHours * rate;
    }
  }

  static double calculateHolidayOvertime({
    required double netHours,
    required bool isHoliday,
    required double hourlyWage,
    required bool isFiveOrMoreEmployees,
  }) {
    // [STUDY NOTE]: 휴일근로 시 8시간 이하분은 기본 1.5배, 8시간 초과분은 2.0배 (기본 1.5배 + 휴일가산 0.5배)로 계산합니다. (5인 이상 사업장 적용)
    if (isHoliday && isFiveOrMoreEmployees) {
      double overtimeHolidayHours =
          netHours > SalaryConstants.legalWorkHoursPerDay
              ? netHours - SalaryConstants.legalWorkHoursPerDay
              : 0.0;
      return overtimeHolidayHours *
          (hourlyWage *
              (SalaryConstants.holidayBaseRate +
                  SalaryConstants.holidayAdditionRate));
    }
    return 0.0;
  }
}

// [STUDY NOTE]: 연장 수당 계산을 담당하는 클래스 (하루 8시간 초과 OR 주 40시간 초과)
class OvertimeCalculator {
  static double calculate({
    required double netHours,
    required double weeklyWorkedHours,
    required bool isHoliday,
    required double hourlyWage,
    required bool isFiveOrMoreEmployees,
  }) {
    if (isFiveOrMoreEmployees && !isHoliday) {
      double dailyOvertime = netHours > SalaryConstants.legalWorkHoursPerDay
          ? netHours - SalaryConstants.legalWorkHoursPerDay
          : 0.0;

      double hoursAfterShift = weeklyWorkedHours + netHours;
      double weeklyOvertime = 0.0;

      if (hoursAfterShift > 40.0) {
        if (weeklyWorkedHours >= 40.0) {
          weeklyOvertime = netHours;
        } else {
          weeklyOvertime = hoursAfterShift - 40.0;
        }
      }

      double effectiveOvertimeHours =
          dailyOvertime > weeklyOvertime ? dailyOvertime : weeklyOvertime;

      // [STUDY NOTE]: 일 단위 연장근로와 주 단위 연장근로가 중첩될 때, 이중 가산을 피하기 위해
      // OvertimeHours = max(dailyOvertime, weeklyOvertime) 원칙을 사용합니다.
      // 예: 주 39시간 누적 상태에서 오늘 4시간 일함 -> 일 연장 0h, 주 연장 3h -> 3h 인정
      // 예: 주 38시간 누적 상태에서 오늘 10시간 일함 -> 일 연장 2h, 주 연장 8h -> 8h 인정.
      return effectiveOvertimeHours *
          hourlyWage *
          SalaryConstants.overtimeAdditionRate;
    }
    return 0.0;
  }
}

// [STUDY NOTE]: 야간 근무 수당 계산을 담당하는 클래스
class NightShiftCalculator {
  static double calculate({
    required DateTime startTime,
    required DateTime endTime,
    required double netHours,
    required double hourlyWage,
    required bool isFiveOrMoreEmployees,
  }) {
    double nightHours = _calculateNightOverlapHours(startTime, endTime);
    if (nightHours > netHours) {
      nightHours = netHours;
    }
    return isFiveOrMoreEmployees
        ? nightHours * hourlyWage * SalaryConstants.nightAdditionRate
        : 0.0;
  }

  static double _calculateNightOverlapHours(DateTime start, DateTime end) {
    double totalOverlapMinutes = 0.0;

    DateTime startDayNightStart = DateTime(
        start.year, start.month, start.day, SalaryConstants.nightStartHour, 0);
    // 야간근무 종료시간을 구하기 위해 시간차를 더함 (22시에서 6시는 8시간)
    int durationHours =
        SalaryConstants.nightEndHour + 24 - SalaryConstants.nightStartHour;
    DateTime startDayNightEnd =
        startDayNightStart.add(Duration(hours: durationHours));

    DateTime prevDayNightStart =
        startDayNightStart.subtract(const Duration(days: 1));
    DateTime prevDayNightEnd =
        prevDayNightStart.add(Duration(hours: durationHours));

    DateTime nextDayNightStart =
        startDayNightStart.add(const Duration(days: 1));
    DateTime nextDayNightEnd =
        nextDayNightStart.add(Duration(hours: durationHours));

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
    DateTime overlapStart =
        rangeStart.isAfter(windowStart) ? rangeStart : windowStart;
    DateTime overlapEnd = rangeEnd.isBefore(windowEnd) ? rangeEnd : windowEnd;

    if (overlapStart.isBefore(overlapEnd)) {
      return overlapEnd.difference(overlapStart).inMinutes.toDouble();
    }
    return 0.0;
  }
}

// [STUDY NOTE]: 커스텀 배율 추가 수당 계산을 담당하는 클래스
class CustomAllowanceCalculator {
  static double calculate(double basePay, double payMultiplier) {
    if (payMultiplier > 1.0) {
      return basePay * (payMultiplier - 1.0);
    }
    return 0.0;
  }
}

// [STUDY NOTE]: 전체 급여 계산 로직을 제어하는 Facade 클래스
class ShiftCalculator {
  static double calculateTotalPay({
    required DateTime startTime,
    required DateTime endTime,
    required int breakTimeMinutes,
    required bool isHoliday,
    required double hourlyWage,
    required bool isFiveOrMoreEmployees,
    required double payMultiplier,
    double weeklyWorkedHours = 0.0,
  }) {
    Duration totalDuration = endTime.difference(startTime);
    int totalMinutes = totalDuration.inMinutes;

    int netMinutes = totalMinutes - breakTimeMinutes;
    if (netMinutes < 0) netMinutes = 0;
    double netHours = netMinutes / 60.0;

    double basePay = BasePayCalculator.calculate(
      netHours: netHours,
      isHoliday: isHoliday,
      hourlyWage: hourlyWage,
      isFiveOrMoreEmployees: isFiveOrMoreEmployees,
    );

    double holidayOvertimeAllowance =
        BasePayCalculator.calculateHolidayOvertime(
      netHours: netHours,
      isHoliday: isHoliday,
      hourlyWage: hourlyWage,
      isFiveOrMoreEmployees: isFiveOrMoreEmployees,
    );

    double overtimeAllowance = OvertimeCalculator.calculate(
      netHours: netHours,
      weeklyWorkedHours: weeklyWorkedHours,
      isHoliday: isHoliday,
      hourlyWage: hourlyWage,
      isFiveOrMoreEmployees: isFiveOrMoreEmployees,
    );

    double nightAllowance = NightShiftCalculator.calculate(
      startTime: startTime,
      endTime: endTime,
      netHours: netHours,
      hourlyWage: hourlyWage,
      isFiveOrMoreEmployees: isFiveOrMoreEmployees,
    );

    double customAllowance =
        CustomAllowanceCalculator.calculate(basePay, payMultiplier);

    return basePay +
        holidayOvertimeAllowance +
        overtimeAllowance +
        nightAllowance +
        customAllowance;
  }
}

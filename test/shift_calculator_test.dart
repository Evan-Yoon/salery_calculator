import 'package:flutter_test/flutter_test.dart';
import 'package:shift_salary_calculator/utils/shift_calculator.dart';

void main() {
  group('ShiftCalculator Tests', () {
    const hourlyWage = 10000.0;

    test('1. 일반 근무 (8시간 이내, 평일, 주간)', () {
      final start = DateTime(2024, 1, 1, 9, 0); // 월요일
      final end = DateTime(2024, 1, 1, 17, 0); // 8시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: false,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      expect(pay, 80000.0); // 8 * 10000
    });

    test('2. 8시간 초과 (연장근무)', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 19, 0); // 10시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: false,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 기본급: 10 * 10000 = 100000
      // 연장: 2 * 5000 = 10000
      // 총: 110000
      expect(pay, 110000.0);
    });

    test('3. 야간 근무', () {
      final start = DateTime(2024, 1, 1, 22, 0);
      final end = DateTime(2024, 1, 2, 6, 0); // 8시간 (22~06)
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: false,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 기본급: 8 * 10000 = 80000
      // 야간: 8 * 5000 = 40000
      // 총: 120000
      expect(pay, 120000.0);
    });

    test('4. 휴일 근무 (8시간 이내)', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 17, 0); // 8시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: true,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 휴일 1.5배: 8 * 15000 = 120000
      expect(pay, 120000.0);
    });

    test('5. 야간 + 연장 (8시간 초과이면서 야간)', () {
      final start = DateTime(2024, 1, 1, 18, 0);
      final end = DateTime(2024, 1, 2, 4, 0); // 10시간 근무 (18~04)
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: false,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 기본급: 10 * 10000 = 100000
      // 연장(2시간): 2 * 5000 = 10000
      // 야간(22~04, 6시간): 6 * 5000 = 30000
      // 총: 140000
      expect(pay, 140000.0);
    });

    test('6. 휴일 + 야간 (8시간 초과 포함)', () {
      final start = DateTime(2024, 1, 1, 20, 0);
      final end = DateTime(2024, 1, 2, 6, 0); // 10시간, 휴일
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: true,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 휴일 기본급(8시간): 8 * 15000 = 120000
      // 휴일 연장(2시간): 2 * 20000 = 40000
      // 야간 수당(22~06, 8시간): 8 * 5000 = 40000
      // 총: 200000
      expect(pay, 200000.0);
    });

    test('7. 휴게시간 포함', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 18, 0); // 9시간 체류
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 60, // 1시간 차감
        isHoliday: false,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 순수 8시간 일반 근로 = 80000
      expect(pay, 80000.0);
    });

    test('8. 휴일 근무 (5인 이상, 8시간 이내 - 6시간)', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 15, 0); // 6시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: true,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 6 * 10000 * 1.5 = 90000
      expect(pay, 90000.0);
    });

    test('9. 휴일 근무 (5인 이상, 8시간 초과 - 10시간)', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 19, 0); // 10시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: true,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
      );
      // 8시간분: 8 * 10000 * 1.5 = 120000
      // 초과 2시간분: 2 * 10000 * 2.0 = 40000
      // 총합 = 160000
      expect(pay, 160000.0);
    });

    test('10. 휴일 근무 (5인 미만 사업장)', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 19, 0); // 10시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: true,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: false,
        payMultiplier: 1.0,
      );
      // 5인 미만은 가산 없음, 기본 시급만 곱해짐
      // 10 * 10000 = 100000
      expect(pay, 100000.0);
    });

    test('11. 주간/일간 연장근로 중복 방지 (weekly=39, net=4)', () {
      // 주 누적 39시간 상태에서, 오늘 4시간(일 연장 0h) 일함 -> 주 연장은 3h 산출됨 => max(0, 3) = 3시간 연장 인정
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 13, 0); // 4시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: false,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
        weeklyWorkedHours: 39.0, // 누적 39시간
      );
      // 기본급: 4 * 10000 = 40000
      // 연장수당: 3 * 5000 = 15000
      // 총합 = 55000
      expect(pay, 55000.0);
    });

    test('12. 주간/일간 연장근로 중복 방지 (weekly=38, net=10)', () {
      // 주 누적 38시간 상태에서, 오늘 10시간(일 연장 2h) 일함 -> 주 연장은 8h 산출됨 => max(2, 8) = 8시간 연장 인정
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 19, 0); // 10시간
      final pay = ShiftCalculator.calculateTotalPay(
        startTime: start,
        endTime: end,
        breakTimeMinutes: 0,
        isHoliday: false,
        hourlyWage: hourlyWage,
        isFiveOrMoreEmployees: true,
        payMultiplier: 1.0,
        weeklyWorkedHours: 38.0, // 누적 38시간
      );
      // 기본급: 10 * 10000 = 100000
      // 연장수당(8시간 인정): 8 * 5000 = 40000
      // 총합 = 140000
      expect(pay, 140000.0);
    });
  });
}

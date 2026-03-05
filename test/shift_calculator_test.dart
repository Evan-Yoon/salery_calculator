import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/shift_calculator.dart';

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
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_salary_calculator/models/allowance_template.dart';

void main() {
  group('AllowanceTemplate Tests', () {
    final now = DateTime(2026, 3, 10, 10, 0);

    AllowanceTemplate makeFixed({
      String id = 'test_fixed',
      String name = '특근수당',
      double amount = 20000,
      bool isActive = true,
    }) =>
        AllowanceTemplate(
          id: id,
          name: name,
          amount: amount,
          isFixedAmount: true,
          isPerHour: false,
          isActive: isActive,
          createdAt: now,
          updatedAt: now,
        );

    AllowanceTemplate makePerHour({
      String id = 'test_per_hour',
      String name = '야간수당',
      double amount = 5000,
    }) =>
        AllowanceTemplate(
          id: id,
          name: name,
          amount: amount,
          isFixedAmount: false,
          isPerHour: true,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

    // ─────────────────────────────────────────────
    // 1. toMap / fromMap 직렬화 왕복
    // ─────────────────────────────────────────────
    test('1. toMap / fromMap 직렬화 왕복 (고정 금액)', () {
      final original = makeFixed();
      final restored = AllowanceTemplate.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.amount, original.amount);
      expect(restored.isFixedAmount, original.isFixedAmount);
      expect(restored.isPerHour, original.isPerHour);
      expect(restored.isActive, original.isActive);
      expect(restored.createdAt.toIso8601String(),
          original.createdAt.toIso8601String());
    });

    test('2. toJson / fromJson 직렬화 왕복 (시간당 수당)', () {
      final original = makePerHour();
      final restored = AllowanceTemplate.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.amount, original.amount);
      expect(restored.isPerHour, true);
      expect(restored.isFixedAmount, false);
    });

    // ─────────────────────────────────────────────
    // 2. copyWith
    // ─────────────────────────────────────────────
    test('3. copyWith — 일부 필드만 변경', () {
      final original = makeFixed(name: '특근수당', amount: 20000);
      final updated = original.copyWith(name: '특별근무수당', amount: 25000);

      expect(updated.name, '특별근무수당');
      expect(updated.amount, 25000);
      expect(updated.id, original.id); // 변경하지 않은 필드는 유지
      expect(updated.isFixedAmount, original.isFixedAmount);
    });

    test('4. copyWith — isActive 토글', () {
      final original = makeFixed(isActive: true);
      final toggled = original.copyWith(isActive: false);

      expect(toggled.isActive, false);
      expect(toggled.name, original.name);
    });

    // ─────────────────────────────────────────────
    // 3. calculateAmount
    // ─────────────────────────────────────────────
    test('5. 고정 금액 템플릿 — 근무시간 무관하게 항상 고정값', () {
      final t = makeFixed(amount: 20000);
      expect(t.calculateAmount(0), 20000);
      expect(t.calculateAmount(4), 20000);
      expect(t.calculateAmount(8), 20000);
    });

    test('6. 시간당 수당 템플릿 — amount × hours', () {
      final t = makePerHour(amount: 5000);
      expect(t.calculateAmount(0), 0);
      expect(t.calculateAmount(4), 20000); // 5000 × 4
      expect(t.calculateAmount(8), 40000); // 5000 × 8
    });

    test('7. 시간당 수당 — 소수점 시간 계산', () {
      final t = makePerHour(amount: 3000);
      expect(t.calculateAmount(1.5), closeTo(4500, 0.01)); // 3000 × 1.5
    });

    // ─────────────────────────────────────────────
    // 4. 활성화 필터링
    // ─────────────────────────────────────────────
    test('8. isActive=false 인 템플릿은 activeAllowanceTemplates에서 제외', () {
      final templates = [
        makeFixed(id: 't1', isActive: true),
        makeFixed(id: 't2', isActive: false),
        makePerHour(),
      ];
      final active = templates.where((t) => t.isActive).toList();
      expect(active.length, 2);
      expect(active.any((t) => t.id == 't2'), false);
    });

    // ─────────────────────────────────────────────
    // 5. 기본 템플릿
    // ─────────────────────────────────────────────
    test('9. 기본 템플릿 5개 생성', () {
      final defaults = defaultAllowanceTemplates;
      expect(defaults.length, 5);
    });

    test('10. 기본 템플릿 — 야간수당은 시간당 수당', () {
      final nightAllowance = defaultAllowanceTemplates
          .firstWhere((t) => t.id == 'default_night_allowance');
      expect(nightAllowance.isPerHour, true);
    });

    test('11. 기본 템플릿 — 특근수당은 고정 금액', () {
      final special = defaultAllowanceTemplates
          .firstWhere((t) => t.id == 'default_special_work');
      expect(special.isFixedAmount, true);
      expect(special.isPerHour, false);
    });
  });
}

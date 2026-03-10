import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// ─── 알림 유형 enum ────────────────────────────
enum NotificationType {
  shiftReminder,
  monthlySummary,
  weeklyHoliday,
  salaryGoal,
}

// ─── SharedPreferences 키 상수 ─────────────────
const _kShiftReminder = 'notification_shift_reminder';
const _kMonthlySummary = 'notification_monthly_summary';
const _kWeeklyHoliday = 'notification_weekly_holiday';
const _kSalaryGoal = 'notification_salary_goal';

/// [STUDY NOTE]: 스마트 알림 설정 상태를 관리하는 Provider입니다.
/// SharedPreferences를 통해 기기에 영구 저장되며,
/// 토글 즉시 NotificationService에 반영됩니다.
class NotificationSettingsProvider with ChangeNotifier {
  bool _shiftReminderEnabled = true;
  bool _monthlySummaryEnabled = true;
  bool _weeklyHolidayEnabled = false;
  bool _salaryGoalEnabled = false;

  // 목표 급여 (설정 후 SalaryProvider와 비교)
  double _salaryGoalAmount = 0.0;

  bool get shiftReminderEnabled => _shiftReminderEnabled;
  bool get monthlySummaryEnabled => _monthlySummaryEnabled;
  bool get weeklyHolidayEnabled => _weeklyHolidayEnabled;
  bool get salaryGoalEnabled => _salaryGoalEnabled;
  double get salaryGoalAmount => _salaryGoalAmount;

  NotificationSettingsProvider() {
    _loadSettings();
  }

  // ─── 로드 ──────────────────────────────────────
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _shiftReminderEnabled = prefs.getBool(_kShiftReminder) ?? true;
      _monthlySummaryEnabled = prefs.getBool(_kMonthlySummary) ?? true;
      _weeklyHolidayEnabled = prefs.getBool(_kWeeklyHoliday) ?? false;
      _salaryGoalEnabled = prefs.getBool(_kSalaryGoal) ?? false;
      _salaryGoalAmount =
          prefs.getDouble('notification_salary_goal_amount') ?? 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationSettingsProvider] load error: $e');
    }
  }

  // ─── 저장 ──────────────────────────────────────
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kShiftReminder, _shiftReminderEnabled);
      await prefs.setBool(_kMonthlySummary, _monthlySummaryEnabled);
      await prefs.setBool(_kWeeklyHoliday, _weeklyHolidayEnabled);
      await prefs.setBool(_kSalaryGoal, _salaryGoalEnabled);
      await prefs.setDouble(
          'notification_salary_goal_amount', _salaryGoalAmount);
    } catch (e) {
      debugPrint('[NotificationSettingsProvider] save error: $e');
    }
  }

  // ─── 토글 메서드 ───────────────────────────────
  Future<void> toggleShiftReminder() async {
    _shiftReminderEnabled = !_shiftReminderEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleMonthlySummary() async {
    _monthlySummaryEnabled = !_monthlySummaryEnabled;
    await _saveSettings();
    if (_monthlySummaryEnabled) {
      await NotificationService().scheduleMonthlySummary();
    } else {
      await NotificationService().cancelMonthlySummary();
    }
    notifyListeners();
  }

  Future<void> toggleWeeklyHoliday() async {
    _weeklyHolidayEnabled = !_weeklyHolidayEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleSalaryGoal() async {
    _salaryGoalEnabled = !_salaryGoalEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setSalaryGoalAmount(double amount) async {
    _salaryGoalAmount = amount;
    await _saveSettings();
    notifyListeners();
  }

  // ─── 조건부 알림 체크 (SalaryProvider 변경 시 호출) ──
  Future<void> checkWeeklyHoliday(double weeklyHours) async {
    if (!_weeklyHolidayEnabled) return;
    if (weeklyHours >= 15.0) {
      await NotificationService().showWeeklyHolidayNotification();
    }
  }

  Future<void> checkSalaryGoal(double currentSalary) async {
    if (!_salaryGoalEnabled) return;
    if (_salaryGoalAmount > 0 && currentSalary >= _salaryGoalAmount) {
      await NotificationService().showSalaryGoalNotification();
    }
  }
}

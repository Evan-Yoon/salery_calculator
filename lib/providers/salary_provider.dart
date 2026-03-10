import 'dart:convert';
import 'package:flutter/material.dart';
// [STUDY NOTE]: SharedPreferences는 기기 내부에 데이터를 영구적으로 저장할 때 쓰는 플러그인입니다. (예: 자동로그인, 설정 기록)
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_entry.dart';
import '../models/bonus_entry.dart';
import '../models/shift_preset.dart';
import '../models/workplace_preset.dart';
import '../models/allowance_template.dart';
import '../services/notification_service.dart';
import '../utils/shift_calculator.dart';
import '../utils/holiday_utils.dart';

// [STUDY NOTE]: ChangeNotifier를 상속받으면 notifyListeners()를 호출해 UI를 자동으로 갱신할 수 있습니다.
// 이 클래스는 앱의 '급여 데이터'라는 상태를 총괄하며, 데이터의 추가/삭제/수정을 처리합니다.
class SalaryProvider with ChangeNotifier {
  // [STUDY NOTE]: 근무 기록(ShiftEntry)과 보너스 기록(BonusEntry)을 담는 리스트입니다.
  List<ShiftEntry> _shifts = [];
  List<BonusEntry> _bonuses = [];

  // [STUDY NOTE]: 기본 시급 및 계산 설정값들입니다.
  double _hourlyWage = 10000;
  bool _isFiveOrMoreEmployees = true;
  double _taxRate = 0.0; // 0.0: 미적용, 0.033: 3.3%, 0.094: 4대보험 등
  bool _isShiftWorker = true;
  bool _hasCompletedOnboarding = false;
  bool _assumeFullAttendance = false;
  bool _hasAgreedToLegal = false;

  // [STUDY NOTE]: 근무지 프리셋 목록 및 현재 적용 중인 프리셋 ID
  List<WorkplacePreset> _workplacePresets = [];
  String? _activeWorkplacePresetId;

  // [STUDY NOTE]: 수당 템플릿 목록 (updatedAt 내림차순 정렬)
  List<AllowanceTemplate> _allowanceTemplates = [];

  // [STUDY NOTE]: 외부에서 데이터를 가져다 쓸 수 있도록 열어둔 getter 함수입니다. 외부에서는 데이터를 직접 변경할 수 없습니다.
  List<ShiftEntry> get shifts => _shifts;
  List<BonusEntry> get bonuses => _bonuses;
  double get hourlyWage => _hourlyWage;
  List<ShiftPreset> get shiftPresets => _shiftPresets;
  bool get isFiveOrMoreEmployees => _isFiveOrMoreEmployees;
  double get taxRate => _taxRate;
  bool get isShiftWorker => _isShiftWorker;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get assumeFullAttendance => _assumeFullAttendance;
  bool get hasAgreedToLegal => _hasAgreedToLegal;
  List<WorkplacePreset> get workplacePresets => _workplacePresets;
  String? get activeWorkplacePresetId => _activeWorkplacePresetId;
  List<AllowanceTemplate> get allowanceTemplates => _allowanceTemplates;
  List<AllowanceTemplate> get activeAllowanceTemplates =>
      _allowanceTemplates.where((t) => t.isActive).toList();

  // [STUDY NOTE]: 등록된 모든 근무 기록의 총 급여와 비정기 급여를 합산하여 반환하는 Getter
  double get totalSalary {
    // fold 함수는 리스트의 모든 요소를 하나의 값으로 누적할 때 사용합니다.
    final shiftTotal = _shifts.fold(
        0.0, (previousValue, element) => previousValue + element.totalPay);
    final bonusTotal = _bonuses.fold(
        0.0, (previousValue, element) => previousValue + element.amount);
    return shiftTotal + bonusTotal;
  }

  // [STUDY NOTE]: 등록된 모든 근무 기록의 순수 실제 근무 시간(휴게시간 제외)을 합산하여 반환합니다.
  double get totalWorkHours {
    return _shifts.fold(0.0, (prev, element) {
      int netMinutes = element.endTime.difference(element.startTime).inMinutes -
          element.breakTimeMinutes;
      return prev + (netMinutes / 60.0);
    });
  }

  // [STUDY NOTE]: 시프트 프리셋(예: 주간, 야간 등 자주 쓰는 시간대) 리스트입니다.
  List<ShiftPreset> _shiftPresets = [];

  SalaryProvider() {
    loadData(); // 클래스가 생성될 때 데이터를 불러옵니다.
  }

  // [STUDY NOTE]: SharedPreferences에서 저장된 데이터를 가져오는 비동기 함수입니다.
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _hourlyWage = prefs.getDouble('hourlyWage') ?? 10000.0;
    _isFiveOrMoreEmployees = prefs.getBool('isFiveOrMoreEmployees') ?? true;
    _taxRate = prefs.getDouble('taxRate') ?? 0.0;
    _isShiftWorker = prefs.getBool('isShiftWorker') ?? true;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    _assumeFullAttendance = prefs.getBool('assumeFullAttendance') ?? false;
    _hasAgreedToLegal = prefs.getBool('hasAgreedToLegal') ?? false;
    _activeWorkplacePresetId = prefs.getString('activeWorkplacePresetId');

    // 수당 템플릿 로드
    final String? allowanceTemplatesString =
        prefs.getString('allowance_templates');
    if (allowanceTemplatesString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(allowanceTemplatesString);
        _allowanceTemplates =
            decoded.map((e) => AllowanceTemplate.fromMap(e)).toList();
        _sortAllowanceTemplates();
      } catch (e) {
        debugPrint('Error loading allowance templates: $e');
        _allowanceTemplates = defaultAllowanceTemplates;
      }
    } else {
      // 최초 실행: 기본 템플릿 자동 생성
      _allowanceTemplates = defaultAllowanceTemplates;
    }

    // 프리셋 데이터 로드
    final String? presetsString = prefs.getString('shiftPresets');
    if (presetsString != null) {
      final List<dynamic> decoded = jsonDecode(presetsString);
      _shiftPresets = decoded.map((e) => ShiftPreset.fromMap(e)).toList();
    }

    final String? workplacePresetsString = prefs.getString('workplacePresets');
    if (workplacePresetsString != null) {
      final List<dynamic> decoded = jsonDecode(workplacePresetsString);
      _workplacePresets =
          decoded.map((e) => WorkplacePreset.fromMap(e)).toList();
    }

    // 근무 기록 로드
    final String? shiftsString = prefs.getString('shifts');
    if (shiftsString != null) {
      final List<dynamic> decoded = jsonDecode(shiftsString);
      _shifts = decoded.map((e) => ShiftEntry.fromMap(e)).toList();
      // 날짜순으로 정렬 (최신순)
      _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
    }

    // 보너스 기록 로드
    final String? bonusesString = prefs.getString('bonuses');
    if (bonusesString != null) {
      final List<dynamic> decoded = jsonDecode(bonusesString);
      _bonuses = decoded.map((e) => BonusEntry.fromMap(e)).toList();
      _bonuses.sort((a, b) => b.date.compareTo(a.date));
    }

    notifyListeners();
  }

  // [STUDY NOTE]: 데이터를 SharedPreferences에 저장하는 비동기 함수입니다.
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('hourlyWage', _hourlyWage);
    prefs.setBool('isFiveOrMoreEmployees', _isFiveOrMoreEmployees);
    prefs.setDouble('taxRate', _taxRate);
    prefs.setBool('isShiftWorker', _isShiftWorker);
    prefs.setBool('hasCompletedOnboarding', _hasCompletedOnboarding);
    prefs.setBool('assumeFullAttendance', _assumeFullAttendance);
    prefs.setBool('hasAgreedToLegal', _hasAgreedToLegal);

    prefs.setString('workplacePresets',
        jsonEncode(_workplacePresets.map((e) => e.toMap()).toList()));
    if (_activeWorkplacePresetId != null) {
      prefs.setString('activeWorkplacePresetId', _activeWorkplacePresetId!);
    } else {
      prefs.remove('activeWorkplacePresetId');
    }

    // 수당 템플릿 저장
    prefs.setString('allowance_templates',
        jsonEncode(_allowanceTemplates.map((e) => e.toMap()).toList()));

    // [STUDY NOTE]: 시프트 리스트를 JSON 텍스트로 변환하여 저장합니다.
    final String shiftsString =
        jsonEncode(_shifts.map((e) => e.toMap()).toList());
    prefs.setString('shifts', shiftsString);

    // [STUDY NOTE]: 보너스 리스트를 JSON 텍스트로 변환하여 저장합니다.
    final String bonusesString =
        jsonEncode(_bonuses.map((e) => e.toMap()).toList());
    prefs.setString('bonuses', bonusesString);

    final String presetsString =
        jsonEncode(_shiftPresets.map((e) => e.toMap()).toList());
    prefs.setString('shiftPresets', presetsString);
  }

  // ─────────────────────────────────────────────
  // 근무/보너스 관리 메서드
  // ─────────────────────────────────────────────

  void addShift(ShiftEntry shift) {
    _shifts.add(shift);
    _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
    saveData();

    // 알림 예약
    NotificationService().scheduleShiftReminder(shift);

    notifyListeners(); // [STUDY NOTE]: 상태가 변경되었음을 UI에 알려줍니다. (Consumer/Provider가 UI를 다시 그림)
  }

  void removeShift(String id) {
    // 알림 취소
    NotificationService().cancelShiftReminder(id);

    _shifts.removeWhere((element) => element.id == id);
    saveData();
    notifyListeners();
  }

  void updateShift(ShiftEntry updatedShift) {
    final index =
        _shifts.indexWhere((element) => element.id == updatedShift.id);
    if (index != -1) {
      _shifts[index] = updatedShift;
      _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
      saveData();

      // 알림 갱신 (기존 취소 후 재예약)
      NotificationService().cancelShiftReminder(updatedShift.id);
      NotificationService().scheduleShiftReminder(updatedShift);

      notifyListeners();
    }
  }

  void addBonus(BonusEntry bonus) {
    _bonuses.add(bonus);
    _bonuses.sort((a, b) => b.date.compareTo(a.date));
    saveData();
    notifyListeners();
  }

  void removeBonus(String id) {
    _bonuses.removeWhere((element) => element.id == id);
    saveData();
    notifyListeners();
  }

  void setHourlyWage(double wage) {
    _hourlyWage = wage;
    saveData();
    notifyListeners();
  }

  void setIsFiveOrMoreEmployees(bool value) {
    _isFiveOrMoreEmployees = value;
    saveData();
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    saveData();
    notifyListeners();
  }

  void setIsShiftWorker(bool value) {
    _isShiftWorker = value;
    saveData();
    notifyListeners();
  }

  void setOnboardingCompleted(bool value) {
    _hasCompletedOnboarding = value;
    saveData();
    notifyListeners();
  }

  void setAssumeFullAttendance(bool value) {
    _assumeFullAttendance = value;
    saveData();
    notifyListeners();
  }

  void agreeToLegalTerms() {
    _hasAgreedToLegal = true;
    saveData();
    notifyListeners();
  }

  void setWorkerType(bool isShiftWorker) {
    _isShiftWorker = isShiftWorker;
    saveData();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await saveData();
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // [STUDY NOTE]: 수당 템플릿 CRUD 메서드들입니다.
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void addAllowanceTemplate(AllowanceTemplate template) {
    _allowanceTemplates.add(template);
    _sortAllowanceTemplates();
    saveData();
    notifyListeners();
  }

  void updateAllowanceTemplate(AllowanceTemplate updated) {
    final idx = _allowanceTemplates.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _allowanceTemplates[idx] = updated;
      _sortAllowanceTemplates();
      saveData();
      notifyListeners();
    }
  }

  void deleteAllowanceTemplate(String id) {
    _allowanceTemplates.removeWhere((t) => t.id == id);
    saveData();
    notifyListeners();
  }

  void toggleAllowanceTemplateActive(String id) {
    final idx = _allowanceTemplates.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _allowanceTemplates[idx] = _allowanceTemplates[idx].copyWith(
        isActive: !_allowanceTemplates[idx].isActive,
        updatedAt: DateTime.now(),
      );
      _sortAllowanceTemplates();
      saveData();
      notifyListeners();
    }
  }

  void _sortAllowanceTemplates() {
    _allowanceTemplates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _applyPresetValues(WorkplacePreset preset) {
    _hourlyWage = preset.hourlyWage;
    _isFiveOrMoreEmployees = preset.isFiveOrMoreEmployees;
    _taxRate = preset.taxRate;
    _activeWorkplacePresetId = preset.id;
    saveData();
    notifyListeners();
  }

  void applyWorkplacePreset(String presetId) {
    final preset = _workplacePresets.firstWhere((p) => p.id == presetId);
    _applyPresetValues(preset);
  }

  void setActiveWorkplacePreset(WorkplacePreset preset) {
    _applyPresetValues(preset);
  }

  void updateWorkplacePreset(WorkplacePreset updated) {
    final index = _workplacePresets.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _workplacePresets[index] = updated;
      if (_activeWorkplacePresetId == updated.id) {
        _applyPresetValues(updated);
      }
      saveData();
      notifyListeners();
    }
  }

  void addWorkplacePreset(WorkplacePreset preset) {
    _workplacePresets.add(preset);
    saveData();
    notifyListeners();
  }

  void removeWorkplacePreset(String id) {
    _workplacePresets.removeWhere((p) => p.id == id);
    if (_activeWorkplacePresetId == id) {
      _activeWorkplacePresetId = null;
    }
    saveData();
    notifyListeners();
  }

  void clearActiveWorkplacePreset() {
    _activeWorkplacePresetId = null;
    saveData();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 프리셋 관리 메서드 (ShiftPreset)
  // ─────────────────────────────────────────────

  void addPreset(ShiftPreset preset) => addShiftPreset(preset);
  void updatePreset(ShiftPreset updated) => updateShiftPreset(updated);
  void removePreset(String id) => removeShiftPreset(id);

  void addShiftPreset(ShiftPreset preset) {
    _shiftPresets.add(preset);
    saveData();
    notifyListeners();
  }

  void updateShiftPreset(ShiftPreset updated) {
    final index = _shiftPresets.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _shiftPresets[index] = updated;
      saveData();
      notifyListeners();
    }
  }

  void removeShiftPreset(String id) {
    _shiftPresets.removeWhere((p) => p.id == id);
    saveData();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 통계 보조 메서드
  // ─────────────────────────────────────────────

  /// 특정 월의 근무 목록 반환
  List<ShiftEntry> getShiftsForMonth(DateTime month) {
    return _shifts
        .where((s) =>
            s.startTime.year == month.year && s.startTime.month == month.month)
        .toList();
  }

  /// 특정 월의 보너스 목록 반환
  List<BonusEntry> getBonusesForMonth(DateTime month) {
    return _bonuses
        .where((b) => b.date.year == month.year && b.date.month == month.month)
        .toList();
  }

  /// 주간 요약 데이터 (주휴수당 포함)
  Map<String, dynamic> getWeeklySummary(DateTime date) {
    double workedHours = getWeeklyWorkedHours(date);
    double weeklyHolidayAllowance = 0.0;

    // 주 15시간 이상 근무 시 주휴수당 발생
    if (workedHours >= 15.0) {
      double limitHours = workedHours > 40.0 ? 40.0 : workedHours;
      weeklyHolidayAllowance = (limitHours / 40.0) * 8.0 * _hourlyWage;
    }

    return {
      'workedHours': workedHours,
      'weeklyHolidayAllowance': weeklyHolidayAllowance,
    };
  }

  /// 이번 주 누적 근무 시간 계산 (주휴수당 체크용)
  double getWeeklyWorkedHours(DateTime date) {
    final firstDayOfWeek = HolidayUtils.getFirstDayOfWeek(date);
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 7));

    final weeklyShifts = _shifts.where((s) =>
        s.startTime
            .isAfter(firstDayOfWeek.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(lastDayOfWeek));

    return weeklyShifts.fold(0.0, (prev, s) {
      final netMins =
          s.endTime.difference(s.startTime).inMinutes - s.breakTimeMinutes;
      return prev + (netMins / 60.0);
    });
  }

  /// 특정 근무를 제외한 이번 주 누적 시간 (저장 시 사용)
  double getWeeklyWorkedHoursBefore(DateTime date, {String? excludeShiftId}) {
    final firstDayOfWeek = HolidayUtils.getFirstDayOfWeek(date);
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 7));

    final weeklyShifts = _shifts.where((s) =>
        s.id != excludeShiftId &&
        s.startTime
            .isAfter(firstDayOfWeek.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(lastDayOfWeek));

    return weeklyShifts.fold(0.0, (prev, s) {
      final netMins =
          s.endTime.difference(s.startTime).inMinutes - s.breakTimeMinutes;
      return prev + (netMins / 60.0);
    });
  }

  /// 이번 달 총 급여 계산 (목표 급여 체크용)
  double getMonthlyTotalSalary(DateTime date) {
    final monthShifts = getShiftsForMonth(date);
    final monthBonuses = getBonusesForMonth(date);

    double shiftTotal = monthShifts.fold(0.0, (prev, s) => prev + s.totalPay);
    double bonusTotal = monthBonuses.fold(0.0, (prev, b) => prev + b.amount);

    // 주휴수당 합산
    double weeklyHolidayTotal = 0.0;
    Map<String, List<ShiftEntry>> shiftsByWeek = {};
    for (var s in monthShifts) {
      final weekKey = HolidayUtils.getFirstDayOfWeek(s.startTime)
          .toIso8601String()
          .split('T')[0];
      if (!shiftsByWeek.containsKey(weekKey)) shiftsByWeek[weekKey] = [];
      shiftsByWeek[weekKey]!.add(s);
    }
    for (var weekKey in shiftsByWeek.keys) {
      DateTime weekDate = DateTime.parse(weekKey);
      weeklyHolidayTotal +=
          getWeeklySummary(weekDate)['weeklyHolidayAllowance'];
    }

    return shiftTotal + bonusTotal + weeklyHolidayTotal;
  }

  /// 패턴 생성 로직
  Future<void> generatePatternShifts({
    required DateTime month,
    required List<dynamic> pattern,
    required DateTime startFrom,
  }) async {
    int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    for (int i = 0; i < daysInMonth; i++) {
      DateTime currentDay = DateTime(month.year, month.month, i + 1);
      if (currentDay.isBefore(startFrom)) continue;

      int diffDays = currentDay.difference(startFrom).inDays;
      if (diffDays < 0) continue;

      var p = pattern[diffDays % pattern.length];
      if (p != null && p is ShiftPreset) {
        final startTime = TimeOfDay(
            hour: int.parse(p.startTime.split(':')[0]),
            minute: int.parse(p.startTime.split(':')[1]));
        final endTime = TimeOfDay(
            hour: int.parse(p.endTime.split(':')[0]),
            minute: int.parse(p.endTime.split(':')[1]));

        final startDT = DateTime(currentDay.year, currentDay.month,
            currentDay.day, startTime.hour, startTime.minute);
        var endDT = DateTime(currentDay.year, currentDay.month, currentDay.day,
            endTime.hour, endTime.minute);
        if (endDT.isBefore(startDT) || endDT.isAtSameMomentAs(startDT)) {
          endDT = endDT.add(const Duration(days: 1));
        }

        final totalPay = ShiftCalculator.calculateTotalPay(
          startTime: startDT,
          endTime: endDT,
          breakTimeMinutes: p.breakTimeMinutes,
          isHoliday: HolidayUtils.isHoliday(currentDay),
          hourlyWage: _hourlyWage,
          isFiveOrMoreEmployees: _isFiveOrMoreEmployees,
          payMultiplier: p.multiplier,
          weeklyWorkedHours: 0,
        );

        final entry = ShiftEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          date: currentDay,
          startTime: startDT,
          endTime: endDT,
          breakTimeMinutes: p.breakTimeMinutes,
          isHoliday: HolidayUtils.isHoliday(currentDay),
          hourlyWage: _hourlyWage,
          payMultiplier: p.multiplier,
          totalPay: totalPay,
        );
        _shifts.add(entry);
      }
    }
    _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
    await saveData();
    notifyListeners();
  }

  Future<void> clearShiftsForMonth(DateTime month) async {
    _shifts.removeWhere((s) =>
        s.startTime.year == month.year && s.startTime.month == month.month);
    await saveData();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 백업/복원용 JSON 내보내기/가져오기
  // ─────────────────────────────────────────────

  String exportToJson() {
    final Map<String, dynamic> data = {
      'hourlyWage': _hourlyWage,
      'isFiveOrMoreEmployees': _isFiveOrMoreEmployees,
      'taxRate': _taxRate,
      'isShiftWorker': _isShiftWorker,
      'hasCompletedOnboarding': _hasCompletedOnboarding,
      'assumeFullAttendance': _assumeFullAttendance,
      'hasAgreedToLegal': _hasAgreedToLegal,
      'shifts': _shifts.map((s) => s.toMap()).toList(),
      'bonuses': _bonuses.map((b) => b.toMap()).toList(),
      'shiftPresets': _shiftPresets.map((p) => p.toMap()).toList(),
      'workplacePresets': _workplacePresets.map((p) => p.toMap()).toList(),
      'activeWorkplacePresetId': _activeWorkplacePresetId,
      'allowanceTemplates': _allowanceTemplates.map((t) => t.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  Future<void> importFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    if (data['hourlyWage'] != null) _hourlyWage = data['hourlyWage'];
    if (data['isFiveOrMoreEmployees'] != null) {
      _isFiveOrMoreEmployees = data['isFiveOrMoreEmployees'];
    }
    if (data['taxRate'] != null) _taxRate = data['taxRate'];
    if (data['isShiftWorker'] != null) _isShiftWorker = data['isShiftWorker'];
    if (data['hasCompletedOnboarding'] != null) {
      _hasCompletedOnboarding = data['hasCompletedOnboarding'];
    }
    if (data['assumeFullAttendance'] != null) {
      _assumeFullAttendance = data['assumeFullAttendance'];
    }
    if (data['hasAgreedToLegal'] != null) {
      _hasAgreedToLegal = data['hasAgreedToLegal'];
    }
    if (data['activeWorkplacePresetId'] != null) {
      _activeWorkplacePresetId = data['activeWorkplacePresetId'];
    }

    if (data['shifts'] != null) {
      _shifts = (data['shifts'] as List)
          .map((e) => ShiftEntry.fromMap(e as Map<String, dynamic>))
          .toList();
      _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
    if (data['bonuses'] != null) {
      _bonuses = (data['bonuses'] as List)
          .map((e) => BonusEntry.fromMap(e as Map<String, dynamic>))
          .toList();
      _bonuses.sort((a, b) => b.date.compareTo(a.date));
    }
    if (data['shiftPresets'] != null) {
      _shiftPresets = (data['shiftPresets'] as List)
          .map((e) => ShiftPreset.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    if (data['workplacePresets'] != null) {
      _workplacePresets = (data['workplacePresets'] as List)
          .map((e) => WorkplacePreset.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    if (data['allowanceTemplates'] != null) {
      _allowanceTemplates = (data['allowanceTemplates'] as List)
          .map((e) => AllowanceTemplate.fromMap(e as Map<String, dynamic>))
          .toList();
      _sortAllowanceTemplates();
    }

    await saveData();
    notifyListeners();
  }
}

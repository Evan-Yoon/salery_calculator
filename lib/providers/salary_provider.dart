import 'dart:convert';
import 'package:flutter/material.dart';
// [STUDY NOTE]: SharedPreferences는 기기 내부에 데이터를 영구적으로 저장할 때 쓰는 플러그인입니다. (예: 자동로그인, 설정 기록)
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_entry.dart';
import '../models/bonus_entry.dart';
import '../models/shift_preset.dart';
import '../models/workplace_preset.dart';
import '../utils/shift_calculator.dart';
import '../utils/holiday_utils.dart';

// [STUDY NOTE]: SalaryProvider는 앱 전체의 상태(근무 기록 리스트, 시급 설정 등)를 관리하는 역할을 합니다.
// ChangeNotifier를 믹스인(with)으로 사용하여, 데이터가 변경될 때마다 화면을 새로고침하도록 알림을 줍니다.
class SalaryProvider with ChangeNotifier {
  // [STUDY NOTE]: 프라이빗 변수(_shifts, _hourlyWage, _bonuses)로 실제 데이터를 안전하게 보관합니다.
  List<ShiftEntry> _shifts = [];
  List<BonusEntry> _bonuses = [];
  double _hourlyWage = 10320.0; // 2026년 기준 최저시급 등 기본값

  // [STUDY NOTE]: 앱 확장을 위한 새로운 전역 설정값들입니다. (프리셋, 5인 이상 여부, 세금)
  List<ShiftPreset> _shiftPresets = [
    ShiftPreset(
        id: 'default_day',
        name: '데이(Day)',
        startTime: '07:00',
        endTime: '15:00',
        breakTimeMinutes: 60,
        multiplier: 1.0,
        iconType: 'sunny'),
    ShiftPreset(
        id: 'default_eve',
        name: '이브닝(Eve)',
        startTime: '15:00',
        endTime: '23:00',
        breakTimeMinutes: 60,
        multiplier: 1.0,
        iconType: 'cloud'),
    ShiftPreset(
        id: 'default_night',
        name: '나이트(Night)',
        startTime: '23:00',
        endTime: '07:00',
        breakTimeMinutes: 60,
        multiplier: 1.5,
        iconType: 'night'),
  ];
  bool _isFiveOrMoreEmployees = false;
  double _taxRate = 0.0; // 0.0(세금 없음), 0.033(프리랜서), 0.094(4대보험)

  // [STUDY NOTE]: Phase 2: 온보딩 기능 도입 (교대 근무자 vs 고정 시간 근무자)
  bool _isShiftWorker = true;
  bool _hasCompletedOnboarding = false;

  // [STUDY NOTE]: Phase 9: 주휴수당 개근 가정 토글 (기본값 설정 OFF)
  bool _assumeFullAttendance = false;

  // [STUDY NOTE]: Phase 11: 법적 고지 동의 여부 저장
  bool _hasAgreedToLegal = false;

  // [STUDY NOTE]: 근무지 프리셋 목록 및 현재 적용 중인 프리셋 ID
  List<WorkplacePreset> _workplacePresets = [];
  String? _activeWorkplacePresetId;

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
      if (netMinutes < 0) netMinutes = 0; // 예외 처리: 휴게시간이 전체 근무시간보다 긴 경우 0으로 처리
      return prev + (netMinutes / 60.0);
    });
  }

  // [STUDY NOTE]: Provider가 처음 생성될 때 자동으로 저장된 데이터를 불러오도록 합니다.
  SalaryProvider() {
    loadData();
  }

  // [STUDY NOTE]: 스마트폰 내부 저장소(SharedPreferences)에서 시급 설정과 기존 근무 기록을 불러옵니다.
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 시급 및 전역 설정 가져오기
    _hourlyWage = prefs.getDouble('hourlyWage') ?? 10320.0;
    _isFiveOrMoreEmployees = prefs.getBool('isFiveOrMoreEmployees') ?? false;
    _taxRate = prefs.getDouble('taxRate') ?? 0.0;
    _isShiftWorker = prefs.getBool('isShiftWorker') ?? true;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    _assumeFullAttendance = prefs.getBool('assumeFullAttendance') ?? false;
    _hasAgreedToLegal = prefs.getBool('hasAgreedToLegal') ?? false;

    // 근무지 프리셋 로드
    final String? workplacePresetsString = prefs.getString('workplacePresets');
    if (workplacePresetsString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(workplacePresetsString);
        _workplacePresets =
            decoded.map((e) => WorkplacePreset.fromMap(e)).toList();
      } catch (e) {
        debugPrint('Error loading workplace presets: $e');
      }
    }
    _activeWorkplacePresetId = prefs.getString('activeWorkplacePresetId');

    // 프리셋 데이터 로드
    final String? presetsString = prefs.getString('shiftPresets');
    if (presetsString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(presetsString);
        _shiftPresets = decoded.map((e) => ShiftPreset.fromMap(e)).toList();
      } catch (e) {
        debugPrint('Error loading presets: $e');
      }
    }

    // 근무 기록 가져오기 (저장된 리스트 형태의 텍스트가 있는지 확인)
    final String? shiftsString = prefs.getString('shifts');
    if (shiftsString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(shiftsString);
        _shifts = decoded.map((e) => ShiftEntry.fromMap(e)).toList();
        _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
      } catch (e) {
        debugPrint('Error loading shifts: $e');
      }
    }

    // 비정기 급여(상여금) 기록 가져오기
    final String? bonusesString = prefs.getString('bonuses');
    if (bonusesString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(bonusesString);
        _bonuses = decoded.map((e) => BonusEntry.fromMap(e)).toList();
        _bonuses.sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        debugPrint('Error loading bonuses: $e');
      }
    }

    // [STUDY NOTE]: 데이터를 다 불러왔으니 UI(화면)에게 업데이트하라고 알립니다.
    notifyListeners();
  }

  // [STUDY NOTE]: 현재 메모리에 있는 리스트와 시급 데이터를 스마트폰 내부 저장소에 저장합니다.
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('hourlyWage', _hourlyWage);
    prefs.setBool('isFiveOrMoreEmployees', _isFiveOrMoreEmployees);
    prefs.setDouble('taxRate', _taxRate);
    prefs.setBool('isShiftWorker', _isShiftWorker);
    prefs.setBool('hasCompletedOnboarding', _hasCompletedOnboarding);
    prefs.setBool('assumeFullAttendance', _assumeFullAttendance);
    prefs.setString('shiftPresets',
        jsonEncode(_shiftPresets.map((e) => e.toMap()).toList()));
    prefs.setString('workplacePresets',
        jsonEncode(_workplacePresets.map((e) => e.toMap()).toList()));
    if (_activeWorkplacePresetId != null) {
      prefs.setString('activeWorkplacePresetId', _activeWorkplacePresetId!);
    } else {
      prefs.remove('activeWorkplacePresetId');
    }

    // [STUDY NOTE]: 시프트 리스트를 JSON 텍스트로 변환하여 저장합니다.
    final String shiftsString =
        jsonEncode(_shifts.map((e) => e.toMap()).toList());
    prefs.setString('shifts', shiftsString);

    // [STUDY NOTE]: 보너스 리스트도 JSON 텍스트로 변환하여 저장합니다.
    final String bonusesString =
        jsonEncode(_bonuses.map((e) => e.toMap()).toList());
    prefs.setString('bonuses', bonusesString);
  }

  // [STUDY NOTE]: 새로운 근무 기록을 추가하고, 다시 정렬한 뒤 영구 저장 및 화면 새로고침을 합니다.
  void addShift(ShiftEntry shift) {
    _shifts.add(shift);
    _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
    saveData();
    notifyListeners(); // [STUDY NOTE]: 상태가 변경되었음을 UI에 알려줍니다. (Consumer/Provider가 UI를 다시 그림)
  }

  // [STUDY NOTE]: 특정 근무 기록을 삭제할 때 호출합니다.
  void removeShift(String id) {
    _shifts.removeWhere((element) => element.id == id);
    saveData();
    notifyListeners();
  }

  // [STUDY NOTE]: 기존 근무 기록을 수정할 때 호출합니다. (ID로 기존 항목을 찾아 덮어씌웁니다)
  void updateShift(ShiftEntry updatedShift) {
    final index =
        _shifts.indexWhere((element) => element.id == updatedShift.id);
    if (index != -1) {
      _shifts[index] = updatedShift;
      _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
      saveData();
      notifyListeners();
    }
  }

  // [STUDY NOTE]: 새로운 보너스/상여금 기록을 추가하고, 정렬 후 저장합니다.
  void addBonus(BonusEntry bonus) {
    _bonuses.add(bonus);
    _bonuses.sort((a, b) => b.date.compareTo(a.date));
    saveData();
    notifyListeners();
  }

  // [STUDY NOTE]: 보너스 기록을 삭제합니다.
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

  // [STUDY NOTE]: 프리셋 관련 CRUD 함수들입니다.
  void addPreset(ShiftPreset preset) {
    _shiftPresets.add(preset);
    saveData();
    notifyListeners();
  }

  void updatePreset(ShiftPreset updatedPreset) {
    final index = _shiftPresets.indexWhere((p) => p.id == updatedPreset.id);
    if (index != -1) {
      _shiftPresets[index] = updatedPreset;
      saveData();
      notifyListeners();
    }
  }

  void removePreset(String id) {
    _shiftPresets.removeWhere((p) => p.id == id);
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

  void setAssumeFullAttendance(bool value) {
    _assumeFullAttendance = value;
    saveData();
    notifyListeners();
  }

  // [STUDY NOTE]: 근무지 프리셋 CRUD 메서드들입니다.
  void addWorkplacePreset(WorkplacePreset preset) {
    _workplacePresets.add(preset);
    saveData();
    notifyListeners();
  }

  void updateWorkplacePreset(WorkplacePreset updated) {
    final idx = _workplacePresets.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _workplacePresets[idx] = updated;
      // 현재 적용 중인 프리셋이 수정되면 설정값도 함께 업데이트
      if (_activeWorkplacePresetId == updated.id) {
        _applyPresetValues(updated);
      }
      saveData();
      notifyListeners();
    }
  }

  void removeWorkplacePreset(String id) {
    _workplacePresets.removeWhere((p) => p.id == id);
    if (_activeWorkplacePresetId == id) {
      _activeWorkplacePresetId = null;
    }
    saveData();
    notifyListeners();
  }

  // [STUDY NOTE]: 선택한 근무지 프리셋을 현재 급여 설정에 즉시 적용합니다.
  void applyWorkplacePreset(String id) {
    final preset = _workplacePresets.firstWhere((p) => p.id == id,
        orElse: () => throw Exception('Preset not found'));
    _activeWorkplacePresetId = id;
    _applyPresetValues(preset);
    saveData();
    notifyListeners();
  }

  void _applyPresetValues(WorkplacePreset preset) {
    _hourlyWage = preset.hourlyWage;
    _isFiveOrMoreEmployees = preset.isFiveOrMoreEmployees;
    _taxRate = preset.taxRate;
    _assumeFullAttendance = preset.assumeFullAttendance;
  }

  // [STUDY NOTE]: 법적 고지 및 개인정보 처리를 동의했을 때 저장합니다.
  void agreeToLegalTerms() async {
    _hasAgreedToLegal = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasAgreedToLegal', true);
  }

  // [STUDY NOTE]: 온보딩의 첫 화면에서 근무 형태(교대 근무 여부)만 먼저 설정할 때 호출됩니다.
  void setWorkerType(bool isShiftWorker) {
    _isShiftWorker = isShiftWorker;
    saveData();
    notifyListeners();
  }

  // [STUDY NOTE]: 온보딩의 두 번째 화면(급여 입력)까지 마치면 최종적으로 온보딩 완료 처리를 합니다.
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await saveData();
    notifyListeners();
  }

  // [STUDY NOTE]: 설정 페이지에서 사용자가 프리셋 시간이나 이름을 변경할 때 호출되는 함수입니다.
  void updateShiftPreset(ShiftPreset updatedPreset) {
    final index = _shiftPresets.indexWhere((p) => p.id == updatedPreset.id);
    if (index != -1) {
      _shiftPresets[index] = updatedPreset;
      saveData();
      notifyListeners();
    }
  }

  // [STUDY NOTE]: 특정 날짜 기준, 해당 '주차(월~일)'에 이미 근무한 총 시간을 계산하여 반환합니다. (주 40시간 초과 연장수당용)
  double getWeeklyWorkedHoursBefore(DateTime targetDate,
      {String? excludeShiftId}) {
    // 1. targetDate가 속한 주의 월요일 시작시간 구하기 (Korean Time 기준 월요일이 한 주의 시작)
    int daysFromMonday = targetDate.weekday - DateTime.monday;
    if (daysFromMonday < 0) {
      daysFromMonday += 7; // 방어 로직 (기본적으로 DateTime.monday는 1, 일요일은 7)
    }

    DateTime mondayStart =
        DateTime(targetDate.year, targetDate.month, targetDate.day)
            .subtract(Duration(days: daysFromMonday));

    // 2. 해당 주차 월요일 00:00:00 부터 targetDate 직전까지의 시프트 찾기
    double weeklyHours = 0.0;
    for (var shift in _shifts) {
      // 본인 시프트 업데이트 시 중복 합산 방지
      if (excludeShiftId != null && shift.id == excludeShiftId) continue;

      // 시프트가 이번 주인가? && 시작시간이 타겟 시간보다 이전인가?
      if (shift.startTime.isAfter(mondayStart) ||
          shift.startTime.isAtSameMomentAs(mondayStart)) {
        if (shift.startTime.isBefore(targetDate)) {
          int netMinutes = shift.endTime.difference(shift.startTime).inMinutes -
              shift.breakTimeMinutes;
          if (netMinutes > 0) {
            weeklyHours += (netMinutes / 60.0);
          }
        }
      }
    }
    return weeklyHours;
  }

  // [STUDY NOTE]: 주휴수당을 계산합니다. 조건: 주 15시간 이상 근무 & 사용자가 '개근 가정'을 활성화했을 때만.
  // 계산식: (주 근로시간 / 근무일수) * 시급
  double calculateWeeklyHolidayAllowance(
      double weeklyHours, int workDays, double hourlyWage) {
    if (!_assumeFullAttendance) {
      return 0.0; // 사용자가 개근(Full Attendance) 토글을 켜지 않으면 주휴수당 발생 안함
    }
    if (weeklyHours < 15.0 || workDays <= 0) {
      return 0.0; // 주 15시간 미만 또는 근무일이 없으면 주휴수당 없음
    }
    return (weeklyHours / workDays) * hourlyWage;
  }

  // [STUDY NOTE]: 특정 날짜가 속한 '주(Week)'의 총 근무시간, 총 근무일수, 그리고 계산된 주휴수당을 한 번에 반환합니다.
  Map<String, dynamic> getWeeklySummary(DateTime targetDate) {
    int daysFromMonday = targetDate.weekday - DateTime.monday;
    if (daysFromMonday < 0) {
      daysFromMonday += 7;
    }
    DateTime mondayStart =
        DateTime(targetDate.year, targetDate.month, targetDate.day)
            .subtract(Duration(days: daysFromMonday));
    DateTime nextMondayStart = mondayStart.add(const Duration(days: 7));

    double weeklyHours = 0.0;
    Set<String> uniqueWorkDays = {}; // 근무일수 카운팅을 위한 Set (같은 날 2교대 하더라도 1일로 산정)

    for (var shift in _shifts) {
      if ((shift.startTime.isAfter(mondayStart) ||
              shift.startTime.isAtSameMomentAs(mondayStart)) &&
          shift.startTime.isBefore(nextMondayStart)) {
        int netMinutes = shift.endTime.difference(shift.startTime).inMinutes -
            shift.breakTimeMinutes;
        if (netMinutes > 0) {
          weeklyHours += (netMinutes / 60.0);
          uniqueWorkDays.add(
              '${shift.startTime.year}-${shift.startTime.month}-${shift.startTime.day}');
        }
      }
    }

    int workDays = uniqueWorkDays.length;
    double allowance =
        calculateWeeklyHolidayAllowance(weeklyHours, workDays, _hourlyWage);

    return {
      'weeklyHours': weeklyHours,
      'workDays': workDays,
      'weeklyHolidayAllowance': allowance,
    };
  }

  // [STUDY NOTE]: 선택된 달의 모든 근무 기록을 삭제합니다. (패턴 재생성 전 초기화용)
  Future<void> clearShiftsForMonth(DateTime month) async {
    _shifts.removeWhere((s) =>
        s.startTime.year == month.year && s.startTime.month == month.month);
    await saveData();
    notifyListeners();
  }

  // [STUDY NOTE]: 사용자가 정의한 패턴(리스트)을 해당 달 전체에 반복 적용합니다.
  Future<void> generatePatternShifts({
    required DateTime month,
    required List<ShiftPreset?> pattern, // null은 '휴무'를 의미함
    required DateTime startFrom,
  }) async {
    if (pattern.isEmpty) return;

    // 해당 달의 마지막 날 구하기
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    int patternIdx = 0;
    List<ShiftEntry> newShifts = [];

    for (int day = 1; day <= lastDay; day++) {
      final currentDay = DateTime(month.year, month.month, day);

      // 시작일 이전은 건너뜀
      if (currentDay
          .isBefore(DateTime(startFrom.year, startFrom.month, startFrom.day))) {
        continue;
      }

      final preset = pattern[patternIdx % pattern.length];
      patternIdx++;

      if (preset == null) continue; // 휴무면 스킵

      // 이미 해당 날짜에 근무가 있는지 확인 (중복 방지)
      bool exists = _shifts.any((s) =>
          s.startTime.year == currentDay.year &&
          s.startTime.month == currentDay.month &&
          s.startTime.day == currentDay.day);
      if (exists) continue;

      // 시프트 데이터 생성
      final startTimeParts = preset.startTime.split(':');
      final endTimeParts = preset.endTime.split(':');

      DateTime shiftStart = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      DateTime shiftEnd = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      // 퇴근 시간이 다음 날인 경우 처리 (예: 23:00 ~ 07:00)
      if (shiftEnd.isBefore(shiftStart) ||
          shiftEnd.isAtSameMomentAs(shiftStart)) {
        shiftEnd = shiftEnd.add(const Duration(days: 1));
      }

      final isHoliday = HolidayUtils.isHoliday(currentDay);

      // 급여 계산
      final totalPay = ShiftCalculator.calculateTotalPay(
        startTime: shiftStart,
        endTime: shiftEnd,
        hourlyWage: _hourlyWage,
        breakTimeMinutes: preset.breakTimeMinutes,
        isHoliday: isHoliday,
        isFiveOrMoreEmployees: _isFiveOrMoreEmployees,
        payMultiplier: preset.multiplier,
      );

      newShifts.add(ShiftEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}_$day',
        date: currentDay,
        startTime: shiftStart,
        endTime: shiftEnd,
        breakTimeMinutes: preset.breakTimeMinutes,
        isHoliday: isHoliday,
        hourlyWage: _hourlyWage,
        payMultiplier: preset.multiplier,
        totalPay: totalPay,
        iconType: preset.iconType,
      ));
    }

    if (newShifts.isNotEmpty) {
      _shifts.addAll(newShifts);
      _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
      await saveData();
      notifyListeners();
    }
  }

  // [STUDY NOTE]: 앱의 모든 데이터를 JSON 문자열로 직렬화합니다. (백업용)
  String exportToJson() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'hourlyWage': _hourlyWage,
      'isFiveOrMoreEmployees': _isFiveOrMoreEmployees,
      'taxRate': _taxRate,
      'isShiftWorker': _isShiftWorker,
      'assumeFullAttendance': _assumeFullAttendance,
      'shifts': _shifts.map((s) => s.toMap()).toList(),
      'bonuses': _bonuses.map((b) => b.toMap()).toList(),
      'shiftPresets': _shiftPresets.map((p) => p.toMap()).toList(),
      'workplacePresets': _workplacePresets.map((p) => p.toMap()).toList(),
      'activeWorkplacePresetId': _activeWorkplacePresetId,
    };
    return jsonEncode(data);
  }

  // [STUDY NOTE]: JSON 문자열로부터 앱의 모든 데이터를 복원합니다.
  // 기존 데이터를 모두 덮어씁니다.
  Future<void> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    _hourlyWage = (data['hourlyWage'] as num?)?.toDouble() ?? _hourlyWage;
    _isFiveOrMoreEmployees =
        data['isFiveOrMoreEmployees'] ?? _isFiveOrMoreEmployees;
    _taxRate = (data['taxRate'] as num?)?.toDouble() ?? _taxRate;
    _isShiftWorker = data['isShiftWorker'] ?? _isShiftWorker;
    _assumeFullAttendance =
        data['assumeFullAttendance'] ?? _assumeFullAttendance;
    _activeWorkplacePresetId = data['activeWorkplacePresetId'];

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

    await saveData();
    notifyListeners();
  }
}

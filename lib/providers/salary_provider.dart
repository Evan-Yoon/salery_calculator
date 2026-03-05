import 'dart:convert';
import 'package:flutter/material.dart';
// [STUDY NOTE]: SharedPreferences는 기기 내부에 데이터를 영구적으로 저장할 때 쓰는 플러그인입니다. (예: 자동로그인, 설정 기록)
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_entry.dart';
import '../models/bonus_entry.dart';
import '../models/shift_preset.dart';

// [STUDY NOTE]: SalaryProvider는 앱 전체의 상태(근무 기록 리스트, 시급 설정 등)를 관리하는 역할을 합니다.
// ChangeNotifier를 믹스인(with)으로 사용하여, 데이터가 변경될 때마다 화면을 새로고침하도록 알림을 줍니다.
class SalaryProvider with ChangeNotifier {
  // [STUDY NOTE]: 프라이빗 변수(_shifts, _hourlyWage, _bonuses)로 실제 데이터를 안전하게 보관합니다.
  List<ShiftEntry> _shifts = [];
  List<BonusEntry> _bonuses = [];
  double _hourlyWage = 10320.0; // 2024년 기준 최저시급 등 기본값

  // [STUDY NOTE]: 앱 확장을 위한 새로운 전역 설정값들입니다. (프리셋, 5인 이상 여부, 세금)
  List<ShiftPreset> _shiftPresets = [
    ShiftPreset(
        id: 'default_day',
        name: '데이(Day)',
        startTime: const TimeOfDay(hour: 7, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        breakTimeMinutes: 60),
    ShiftPreset(
        id: 'default_eve',
        name: '이브닝(Eve)',
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 23, minute: 0),
        breakTimeMinutes: 60),
    ShiftPreset(
        id: 'default_night',
        name: '나이트(Night)',
        startTime: const TimeOfDay(hour: 23, minute: 0),
        endTime: const TimeOfDay(hour: 7, minute: 0),
        breakTimeMinutes: 60),
  ];
  bool _isFiveOrMoreEmployees = false;
  double _taxRate = 0.0; // 0.0(세금 없음), 0.033(프리랜서), 0.094(4대보험)

  // [STUDY NOTE]: Phase 2: 온보딩 기능 도입 (교대 근무자 vs 고정 시간 근무자)
  bool _isShiftWorker = true;
  bool _hasCompletedOnboarding = false;

  // [STUDY NOTE]: 외부에서 데이터를 가져다 쓸 수 있도록 열어둔 getter 함수입니다. 외부에서는 데이터를 직접 변경할 수 없습니다.
  List<ShiftEntry> get shifts => _shifts;
  List<BonusEntry> get bonuses => _bonuses;
  double get hourlyWage => _hourlyWage;
  List<ShiftPreset> get shiftPresets => _shiftPresets;
  bool get isFiveOrMoreEmployees => _isFiveOrMoreEmployees;
  double get taxRate => _taxRate;
  bool get isShiftWorker => _isShiftWorker;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

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

    // 근무 프리셋 가져오기
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
    prefs.setString('shiftPresets',
        jsonEncode(_shiftPresets.map((e) => e.toMap()).toList()));

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

  // [STUDY NOTE]: 설정 탭에서 시급을 변경할 때 쓰이는 함수입니다.
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

  // [STUDY NOTE]: 주휴수당을 계산합니다. 조건: 주 15시간 이상 근무 & 개근 (개근 여부는 앱에서 증명 불가하므로 시간 조건만 체크)
  // 계산식: (주 근로시간 / 근무일수) * 시급
  double calculateWeeklyHolidayAllowance(
      double weeklyHours, int workDays, double hourlyWage) {
    if (weeklyHours < 15.0 || workDays <= 0) {
      return 0.0; // 주 15시간 미만 또는 근무일이 없으면 주휴수당 없음
    }
    return (weeklyHours / workDays) * hourlyWage;
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
// [STUDY NOTE]: SharedPreferences는 기기 내부에 데이터를 영구적으로 저장할 때 쓰는 플러그인입니다. (예: 자동로그인, 설정 기록)
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_entry.dart';
import '../models/bonus_entry.dart';

// [STUDY NOTE]: SalaryProvider는 앱 전체의 상태(근무 기록 리스트, 시급 설정 등)를 관리하는 역할을 합니다.
// ChangeNotifier를 믹스인(with)으로 사용하여, 데이터가 변경될 때마다 화면을 새로고침하도록 알림을 줍니다.
class SalaryProvider with ChangeNotifier {
  // [STUDY NOTE]: 프라이빗 변수(_shifts, _hourlyWage, _bonuses)로 실제 데이터를 안전하게 보관합니다.
  List<ShiftEntry> _shifts = [];
  List<BonusEntry> _bonuses = [];
  double _hourlyWage = 10320.0; // 2024년 기준 최저시급 등 기본값

  // [STUDY NOTE]: 외부에서 데이터를 가져다 쓸 수 있도록 열어둔 getter 함수입니다. 외부에서는 데이터를 직접 변경할 수 없습니다.
  List<ShiftEntry> get shifts => _shifts;
  List<BonusEntry> get bonuses => _bonuses;
  double get hourlyWage => _hourlyWage;

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

    // 시급 설정 가져오기 (저장된 값이 없으면 10320.0 반환)
    _hourlyWage = prefs.getDouble('hourlyWage') ?? 10320.0;

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
}

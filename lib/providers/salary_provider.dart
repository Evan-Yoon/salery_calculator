import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_entry.dart';

class SalaryProvider with ChangeNotifier {
  List<ShiftEntry> _shifts = [];
  double _hourlyWage = 10320.0;

  List<ShiftEntry> get shifts => _shifts;
  double get hourlyWage => _hourlyWage;

  double get totalSalary {
    return _shifts.fold(0.0, (previousValue, element) => previousValue + element.totalPay);
  }

  double get totalWorkHours {
      return _shifts.fold(0.0, (prev, element) {
          int netMinutes = element.endTime.difference(element.startTime).inMinutes - element.breakTimeMinutes;
          if (netMinutes < 0) netMinutes = 0;
          return prev + (netMinutes / 60.0);
      });
  }

  SalaryProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Wage
    _hourlyWage = prefs.getDouble('hourlyWage') ?? 10320.0;

    // Load Shifts
    final String? shiftsString = prefs.getString('shifts');
    if (shiftsString != null) {
      try {
          final List<dynamic> decoded = jsonDecode(shiftsString);
          _shifts = decoded.map((e) => ShiftEntry.fromMap(e)).toList();
          // Sort descending
          _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
      } catch (e) {
          debugPrint('Error loading shifts: $e');
      }
    }
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('hourlyWage', _hourlyWage);

    final String shiftsString = jsonEncode(_shifts.map((e) => e.toMap()).toList());
    prefs.setString('shifts', shiftsString);
    // notifyListeners(); // Not strictly needed unless UI depends on save status
  }

  void addShift(ShiftEntry shift) {
    _shifts.add(shift);
    _shifts.sort((a, b) => b.startTime.compareTo(a.startTime));
    saveData();
    notifyListeners();
  }

  void removeShift(String id) {
    _shifts.removeWhere((element) => element.id == id);
    saveData();
    notifyListeners();
  }

  void setHourlyWage(double wage) {
    _hourlyWage = wage;
    saveData();
    notifyListeners();
  }
}

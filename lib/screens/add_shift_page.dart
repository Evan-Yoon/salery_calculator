import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/shift_entry.dart';
import '../utils/shift_calculator.dart';
import '../utils/holiday_utils.dart';
import '../widgets/add_shift/preset_chips.dart';
import '../widgets/add_shift/date_time_card.dart';

// [STUDY NOTE]: StatefulWidget은 화면의 상태(데이터)가 변할 때마다 화면을 다시 그릴 수 있는 위젯입니다.
// 이 페이지는 사용자가 입력하는 날짜, 시간 등의 '상태'가 계속 변하므로 StatefulWidget을 사용합니다.
class AddShiftPage extends StatefulWidget {
  final ShiftEntry? existingShift;

  const AddShiftPage({super.key, this.existingShift});

  @override
  State<AddShiftPage> createState() => _AddShiftPageState();
}

class _AddShiftPageState extends State<AddShiftPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  int _breakTimeMinutes = 60;
  bool _isHoliday = false;
  double _payMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingShift != null) {
      final shift = widget.existingShift!;
      _selectedDate = shift.date;
      _startTime = TimeOfDay.fromDateTime(shift.startTime);
      _endTime = TimeOfDay.fromDateTime(shift.endTime);
      _breakTimeMinutes = shift.breakTimeMinutes;
      _isHoliday = shift.isHoliday;
      _payMultiplier = shift.payMultiplier;
    } else {
      if (HolidayUtils.isHoliday(_selectedDate)) {
        _isHoliday = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingShift != null;

    // [STUDY NOTE]: Scaffold는 화면의 기본 뼈대(AppBar, Body 등)를 제공하는 머티리얼 디자인 위젯입니다.
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '근무 기록 수정' : '근무 추가하기',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteShift(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Provider.of<SalaryProvider>(context).isShiftWorker)
                    _buildSectionTitle('근무 프리셋 (빠른 입력)'),
                  PresetChips(
                    onPresetSelected: (start, end, breakMins, multiplier) {
                      setState(() {
                        _startTime = start;
                        _endTime = end;
                        _breakTimeMinutes = breakMins;
                        _payMultiplier = multiplier;
                      });
                    },
                  ),
                  if (Provider.of<SalaryProvider>(context).isShiftWorker)
                    const SizedBox(height: 24),
                  _buildSectionTitle('날짜 및 시간'),
                  DateTimeCard(
                    selectedDate: _selectedDate,
                    startTime: _startTime,
                    endTime: _endTime,
                    onPickDate: _pickDate,
                    onPickTime: _pickTime,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('휴게 시간 (분)'),
                  _buildBreakTimeCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('추가 옵션'),
                  _buildOptionsCard(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBreakTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 휴게 시간', style: TextStyle(fontSize: 16)),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () {
                        setState(() {
                          if (_breakTimeMinutes >= 5) _breakTimeMinutes -= 5;
                        });
                      },
                    ),
                    Text(
                      '$_breakTimeMinutes',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        setState(() {
                          _breakTimeMinutes += 5;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '휴게 시간은 급여 계산 및 실제 근무 시간에서 자동으로 제외됩니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    final provider = Provider.of<SalaryProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // [STUDY NOTE]: 교대 근무자에게만 '수당 배율' 조절 UI를 보여줍니다.
          if (provider.isShiftWorker)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('수당 배율', style: TextStyle(fontSize: 16)),
                  const Text('근무 조에 따른 배율 (1.0 = 배율 없음)\n※ 통상임금 기준 가산',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          if (_payMultiplier > 1.0) _payMultiplier -= 0.05;
                        }),
                      ),
                      InkWell(
                        onTap: () => _showMultiplierEditDialog(),
                        child: Text('${_payMultiplier.toStringAsFixed(2)}배',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() {
                          _payMultiplier += 0.05;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('휴일 근무', style: TextStyle(fontSize: 16)),
              const Text('1.5배 수당 추가 (통상임금 기준)',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              Switch(
                value: _isHoliday,
                onChanged: (val) => setState(() => _isHoliday = val),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [STUDY NOTE]: 화면 하단에 보이는 실시간 근무 시간 결과와 '저장하기' 버튼 영역을 만듭니다.
  Widget _buildBottomBar() {
    // 결과 미리 계산
    final start = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime.hour, _startTime.minute);
    var end = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _endTime.hour, _endTime.minute);

    // 자정(오밤중)을 넘어가는 경우 처리
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    // 순수 실제 근무 시간
    final totalMins = end.difference(start).inMinutes;
    final netMins = totalMins - _breakTimeMinutes;
    final netHours = (netMins > 0 ? netMins : 0) / 60.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('예상 급여 계산 시간',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                        '휴게 ${(_breakTimeMinutes / 60).toStringAsFixed(1)}시간 제외됨',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    const Text('실제 근무 시간 ',
                        style: TextStyle(color: Colors.grey)),
                    Text('${netHours.toStringAsFixed(1)} ',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    const Text('시간',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveShift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('저장하기',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.check),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime tempDate = _selectedDate;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(8),
          content: SizedBox(
            width: 300,
            height: 400,
            child: StatefulBuilder(
              builder: (ctx, setDialogState) {
                return TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: tempDate,
                  selectedDayPredicate: (day) => isSameDay(tempDate, day),
                  holidayPredicate: (day) => HolidayUtils.isHoliday(day),
                  locale: 'ko_KR',
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    holidayTextStyle: const TextStyle(color: Colors.red),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setDialogState(() {
                      tempDate = selectedDay;
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, tempDate),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (HolidayUtils.isHoliday(picked)) {
          _isHoliday = true;
        } else {
          _isHoliday = false; // 공휴일이 아니면 기본값으로 해제 (수동 조작을 위해 고민이 필요하지만 일단 자동화)
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // [STUDY NOTE]: 사용자가 입력한 데이터를 토대로 급여를 계산하고, 객체를 만들어 Provider를 통해 저장하는 핵심 함수입니다.
  void _saveShift() {
    // [STUDY NOTE]: Provider(상태 관리자)에 접근하여 데이터를 저장할 준비를 합니다. (화면을 새로 그릴 필요는 없으므로 listen: false)
    final provider = Provider.of<SalaryProvider>(context, listen: false);

    // DateTime 객체 조립
    final start = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime.hour, _startTime.minute);
    var end = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _endTime.hour, _endTime.minute);

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      end = end.add(const Duration(days: 1));
    }

    // 주 40시간 초과 연장 연산을 위해, 이번 주 누적 근무 시간을 미리 계산합니다.
    final weeklyWorkedHoursBeforeThisShift =
        provider.getWeeklyWorkedHoursBefore(
      start,
      excludeShiftId: widget.existingShift?.id,
    );

    final totalPay = ShiftCalculator.calculateTotalPay(
      startTime: start,
      endTime: end,
      breakTimeMinutes: _breakTimeMinutes,
      isHoliday: _isHoliday,
      hourlyWage: provider.hourlyWage,
      isFiveOrMoreEmployees: provider.isFiveOrMoreEmployees,
      payMultiplier: _payMultiplier,
      weeklyWorkedHours: weeklyWorkedHoursBeforeThisShift,
    );

    final entry = ShiftEntry(
      id: widget.existingShift?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      startTime: start,
      endTime: end,
      breakTimeMinutes: _breakTimeMinutes,
      isHoliday: _isHoliday,
      hourlyWage: provider.hourlyWage,
      payMultiplier: _payMultiplier,
      totalPay: totalPay,
    );

    if (widget.existingShift != null) {
      provider.updateShift(entry);
    } else {
      provider.addShift(entry);
    }

    Navigator.pop(context);
  }

  void _deleteShift() {
    if (widget.existingShift != null) {
      Provider.of<SalaryProvider>(context, listen: false)
          .removeShift(widget.existingShift!.id);
      Navigator.pop(context);
    }
  }

  void _showMultiplierEditDialog() {
    final TextEditingController controller =
        TextEditingController(text: _payMultiplier.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('수당 배율 입력',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '예: 1.5',
              suffixText: '배',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? parsed = double.tryParse(controller.text);
                if (parsed != null && parsed >= 0) {
                  setState(() {
                    _payMultiplier = parsed;
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}

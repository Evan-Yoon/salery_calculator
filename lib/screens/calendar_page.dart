import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/shift_entry.dart';
import '../models/bonus_entry.dart';
import '../widgets/main_bottom_nav.dart';

// [STUDY NOTE]: 달력을 보여주고, 매일의 근무 시간, 급여, 상여금을 관리하는 페이지입니다.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay =
      DateTime.now(); // [STUDY NOTE]: 달력이 현재 보여주고 있는 달을 추적합니다.
  DateTime? _selectedDay = DateTime.now(); // [STUDY NOTE]: 사용자가 터치해서 선택한 날짜입니다.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, // 하단 탭으로 이동하므로 뒤로가기 숨김
      ),
      body: Consumer<SalaryProvider>(
        builder: (context, provider, child) {
          // [STUDY NOTE]: Provider가 변경될 때마다 화면을 다시 그립니다.
          List<ShiftEntry> selectedShifts =
              _getShiftsForDay(provider, _selectedDay ?? _focusedDay);
          List<BonusEntry> selectedBonuses =
              _getBonusesForDay(provider, _selectedDay ?? _focusedDay);

          return Column(
            children: [
              _buildCalendar(provider),
              const Divider(color: Colors.white10),
              Expanded(
                child: _buildDailyDetails(
                    selectedShifts, selectedBonuses, provider.taxRate),
              ),
            ],
          );
        },
      ),
      // [STUDY NOTE]: 선택된 날짜에 비정기 급여(상여금)를 추가하는 버튼입니다.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBonusDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('수입 추가', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      bottomNavigationBar:
          const MainBottomNav(currentIndex: 1), // 네비게이션 바 '캘린더' 인덱스
    );
  }

  // [STUDY NOTE]: table_calendar 라이브러리를 활용해 달력을 그리는 함수입니다.
  Widget _buildCalendar(SalaryProvider provider) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      locale: 'ko_KR', // [STUDY NOTE]: 요일과 달을 한국어로 표시합니다 (마지막 줄).
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
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
      // [STUDY NOTE]: 각 날짜(day) 아래에 작은 점(마커)을 표시하기 위해 이벤트를 반환합니다. 근무나 보너스가 있으면 반환.
      eventLoader: (day) {
        final shifts = _getShiftsForDay(provider, day);
        final bonuses = _getBonusesForDay(provider, day);
        return [...shifts, ...bonuses]; // 리스트 합치기
      },
      // [STUDY NOTE]: 달력 날짜 칸 안에 추가 정보(몇 시간 일했는지 등)를 넣기 위한 커스텀 빌더입니다. 공간 제약상 마커로 대체하거나, 여기에 수입을 표시할 수도 있습니다.
    );
  }

  // [STUDY NOTE]: 특정 날짜의 근무 및 상여금 리스트, 일일 요약을 보여줍니다.
  Widget _buildDailyDetails(
      List<ShiftEntry> shifts, List<BonusEntry> bonuses, double taxRate) {
    if (shifts.isEmpty && bonuses.isEmpty) {
      return const Center(
        child: Text('이 날의 근무 또는 수입 기록이 없습니다.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final multiplier = 1.0 - taxRate;
    final double dailyShiftPay =
        shifts.fold(0.0, (sum, s) => sum + s.totalPay * multiplier);
    final double dailyBonusPay =
        bonuses.fold(0.0, (sum, b) => sum + b.amount * multiplier);
    final double dailyTotalPay = dailyShiftPay + dailyBonusPay;

    final double dailyNetHours = shifts.fold(0.0, (sum, s) {
      int netMins =
          s.endTime.difference(s.startTime).inMinutes - s.breakTimeMinutes;
      return sum + (netMins > 0 ? netMins / 60.0 : 0.0);
    });

    final formatter = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. 일일 요약 카드
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('근무 시간', '${dailyNetHours.toStringAsFixed(1)}h',
                  Icons.schedule, Colors.blue),
              _buildSummaryItem('일일 수익', '₩${formatter.format(dailyShiftPay)}',
                  Icons.payments, Colors.green),
              _buildSummaryItem(
                  '총 수익',
                  '₩${formatter.format(dailyTotalPay)}',
                  Icons.account_balance_wallet,
                  Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. 근무 기록 목록
        if (shifts.isNotEmpty) ...[
          const Text('근무 내역',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          ...shifts.map((shift) => _buildShiftTile(shift)),
          const SizedBox(height: 16),
        ],

        // 3. 상여금 기록 목록
        if (bonuses.isNotEmpty) ...[
          const Text('비정기 수입 내역',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          ...bonuses.map((bonus) => _buildBonusTile(bonus)),
        ],

        const SizedBox(height: 80), // 하단 플로팅 버튼 여백
      ],
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // [STUDY NOTE]: 홈 화면에서 썼던 것과 비슷한 모양으로 각 근무(Shift)를 보여줍니다.
  Widget _buildShiftTile(ShiftEntry shift) {
    final formatter = NumberFormat('#,###');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.work, color: Theme.of(context).colorScheme.primary),
        title: Text(
            '${DateFormat('HH:mm').format(shift.startTime)} ~ ${DateFormat('HH:mm').format(shift.endTime)}'),
        subtitle: Text('휴게시간: ${shift.breakTimeMinutes}분'),
        trailing: Text('₩${formatter.format(shift.totalPay.round())}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // [STUDY NOTE]: 상여금(Bonus) 내역을 리스트 형태로 보여주는 위젯입니다. 스와이프해서 지울 수 있습니다.
  Widget _buildBonusTile(BonusEntry bonus) {
    final formatter = NumberFormat('#,###');
    return Dismissible(
      key: Key(bonus.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        Provider.of<SalaryProvider>(context, listen: false)
            .removeBonus(bonus.id);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.amber.withValues(alpha: 0.1),
        child: ListTile(
          leading: const Icon(Icons.star, color: Colors.amber),
          title: Text(bonus.description.isEmpty ? '추가 수입' : bonus.description),
          trailing: Text('₩${formatter.format(bonus.amount.round())}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amber)),
        ),
      ),
    );
  }

  // [STUDY NOTE]: 특정 날짜와 동일한 날의 근무를 필터링하는 도우미 함수들입니다.
  List<ShiftEntry> _getShiftsForDay(SalaryProvider provider, DateTime day) {
    return provider.shifts.where((s) => isSameDay(s.startTime, day)).toList();
  }

  List<BonusEntry> _getBonusesForDay(SalaryProvider provider, DateTime day) {
    return provider.bonuses.where((b) => isSameDay(b.date, day)).toList();
  }

  // [STUDY NOTE]: 플로팅 버튼을 누르면 밑에서 올라오는 창(BottomSheet)으로 상여금을 입력받습니다.
  void _showAddBonusDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드가 올라올 때 창도 같이 올라가게 합니다.
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, // 키보드 높이만큼 여백
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내부 내용만큼만 높이 차지
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${DateFormat('MM월 dd일').format(_selectedDay ?? DateTime.now())} 수입 추가',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration:
                    const InputDecoration(labelText: '수입 내용 (예: 상여금, 용돈)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '금액 (원)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount > 0) {
                    final newBonus = BonusEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: _selectedDay ?? DateTime.now(),
                      amount: amount,
                      description: titleController.text,
                    );
                    Provider.of<SalaryProvider>(context, listen: false)
                        .addBonus(newBonus);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('저장하기'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/shift_entry.dart';
import 'add_shift_page.dart';
import 'shift_history_page.dart';
import '../widgets/main_bottom_nav.dart';

// [STUDY NOTE]: 앱을 켰을 때 가장 먼저 나오는 메인 대시보드 화면입니다.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _currentMonth = DateTime.now();

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 그렇지 않으면 홈 대시보드를 보여줍니다.
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    _buildShiftListHeader(),
                    _buildShiftList(),
                    const SizedBox(height: 80), // 추가 버튼(FAB)을 위한 여백
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddShiftPage()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Column(
            children: [
              Text(
                DateFormat('yyyy년').format(_currentMonth),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              Text(
                DateFormat('MM월 급여').format(_currentMonth),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // [STUDY NOTE]: 화면 상단의 이번 달 총수입, 근무 시간을 보여주는 요약 카드를 만듭니다.
  Widget _buildSummaryCard() {
    // [STUDY NOTE]: Consumer는 Provider의 데이터가 변경될 때마다 이 부분의 UI만 콕 집어서 다시 그려주는 역할을 합니다.
    return Consumer<SalaryProvider>(
      builder: (context, provider, child) {
        // 해당 월에 맞는 근무 기록만 필터링합니다.
        final monthlyShifts = provider.shifts
            .where((s) =>
                s.startTime.year == _currentMonth.year &&
                s.startTime.month == _currentMonth.month)
            .toList();

        final formatter = NumberFormat('#,###');

        // 주휴수당 계산 로직 (해당 달의 근무들을 주 단위로 그루핑하여 합산)
        double totalWeeklyHolidayAllowance = 0.0;

        // 1. 달의 모든 근무를 주차별로 분류 (연도-주차 문자열 형식의 키 사용. 예: "2024-W12" 혹은 단순하게 몇번째 주인지)
        Map<String, List<ShiftEntry>> shiftsByWeek = {};
        for (var s in monthlyShifts) {
          int daysFromMonday = s.startTime.weekday - DateTime.monday;
          if (daysFromMonday < 0) daysFromMonday += 7;
          DateTime mondayStart =
              DateTime(s.startTime.year, s.startTime.month, s.startTime.day)
                  .subtract(Duration(days: daysFromMonday));
          String weekKey =
              "${mondayStart.year}-${mondayStart.month}-${mondayStart.day}";

          if (!shiftsByWeek.containsKey(weekKey)) shiftsByWeek[weekKey] = [];
          shiftsByWeek[weekKey]!.add(s);
        }

        // 2. 주별로 순 근로시간 산정 후 주휴수당 부과
        for (var weekString in shiftsByWeek.keys) {
          List<String> parts = weekString.split('-');
          DateTime weekDate = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

          Map<String, dynamic> summary = provider.getWeeklySummary(weekDate);
          totalWeeklyHolidayAllowance += summary['weeklyHolidayAllowance'];
        }

        final totalSalary =
            monthlyShifts.fold(0.0, (sum, s) => sum + s.totalPay) +
                totalWeeklyHolidayAllowance;
        // 대시보드 표시용으로 순수 실제 근무 시간을 합산합니다:
        final totalNetHours = monthlyShifts.fold(0.0, (sum, s) {
          int netMins =
              s.endTime.difference(s.startTime).inMinutes - s.breakTimeMinutes;
          return sum + (netMins > 0 ? netMins / 60.0 : 0.0);
        });

        final double netSalary = totalSalary * (1.0 - provider.taxRate);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]),
          child: Column(
            children: [
              const Text('이번 달 총 예상 급여 (실수령액)',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '₩${formatter.format(netSalary.round())}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (provider.taxRate > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '세전 ₩${formatter.format(totalSalary.round())} (-${(provider.taxRate * 100).toStringAsFixed(1)}% 세금 적용)',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              if (totalWeeklyHolidayAllowance > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '(주휴수당 ₩${formatter.format(totalWeeklyHolidayAllowance.round())} 포함)',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('총 근무 ${totalNetHours.toStringAsFixed(1)}시간'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('최근 근무 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ShiftHistoryPage()),
              );
            },
            child: const Text('전체보기'),
          ),
        ],
      ),
    );
  }

  // [STUDY NOTE]: 아래에 뜨는 개별 근무 기록(리스트)을 화면에 그리는 함수입니다.
  Widget _buildShiftList() {
    return Consumer<SalaryProvider>(
      builder: (context, provider, child) {
        final monthlyShifts = provider.shifts
            .where((s) =>
                s.startTime.year == _currentMonth.year &&
                s.startTime.month == _currentMonth.month)
            .toList();

        if (monthlyShifts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('근무 기록이 없습니다.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: monthlyShifts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final shift = monthlyShifts[index];
            final formatter = NumberFormat('#,###');

            // 아이콘과 색상 결정
            IconData icon = Icons.wb_sunny;
            Color iconColor = Colors.orange;
            String tag = '주간';
            Color tagColor = Colors.grey;

            if (shift.isHoliday) {
              tag = '특근'; // 휴일 수당 적용
              tagColor = Colors.indigo;
              icon = Icons.star;
              iconColor = Colors.indigo;
            } else if (shift.startTime.hour >= 18 ||
                shift.startTime.hour <= 5) {
              tag = '야간';
              icon = Icons.dark_mode;
              iconColor = Colors.purple;
            }

            // [STUDY NOTE]: 사용자가 항목을 옆으로 밀어(Swipe/Dismiss) 삭제할 수 있게 해주는 기능입니다.
            return Dismissible(
              key: Key(shift.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                provider.removeShift(shift.id);
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddShiftPage(existingShift: shift),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  DateFormat('MM.dd (E)', 'ko_KR')
                                      .format(shift.startTime),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tagColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tag,
                                      style: TextStyle(
                                          fontSize: 10, color: tagColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('HH:mm').format(shift.startTime)} ~ ${DateFormat('HH:mm').format(shift.endTime)} (${shift.totalDurationHours.toStringAsFixed(1)}h)',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₩${formatter.format(shift.totalPay.round())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

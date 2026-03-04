import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import 'add_shift_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _currentMonth = DateTime.now();
  int _currentIndex = 0;

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    // If current index is Settings (3), show Settings Page
    if (_currentIndex == 3) {
      return const SettingsPage();
    }

    // Otherwise show Home Dashboard
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
                    const SizedBox(height: 80), // Space for FAB
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3 || index == 0) {
            // Only Home and Settings functional for now
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardTheme.color,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: '캘린더'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: '통계'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
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

  Widget _buildSummaryCard() {
    return Consumer<SalaryProvider>(
      builder: (context, provider, child) {
        // Filter shifts by month
        final monthlyShifts = provider.shifts
            .where((s) =>
                s.startTime.year == _currentMonth.year &&
                s.startTime.month == _currentMonth.month)
            .toList();

        final totalSalary =
            monthlyShifts.fold(0.0, (sum, s) => sum + s.totalPay);
        // Let's use net hours for the dashboard:
        final totalNetHours = monthlyShifts.fold(0.0, (sum, s) {
          int netMins =
              s.endTime.difference(s.startTime).inMinutes - s.breakTimeMinutes;
          return sum + (netMins > 0 ? netMins / 60.0 : 0.0);
        });

        final formatter = NumberFormat('#,###');

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]),
          child: Column(
            children: [
              const Text('총 예상 급여',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '₩${formatter.format(totalSalary.round())}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
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
          TextButton(onPressed: () {}, child: const Text('전체보기')),
        ],
      ),
    );
  }

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

            // Determine Icon and Color
            IconData icon = Icons.wb_sunny;
            Color iconColor = Colors.orange;
            String tag = '주간';
            Color tagColor = Colors.grey;

            if (shift.isHoliday) {
              tag = '특근'; // Holiday work
              tagColor = Colors.indigo;
              icon = Icons.star;
              iconColor = Colors.indigo;
            } else if (shift.startTime.hour >= 18 ||
                shift.startTime.hour <= 5) {
              tag = '야간';
              icon = Icons.dark_mode;
              iconColor = Colors.purple;
            }

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
                        color: iconColor.withOpacity(0.1),
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
                                  color: tagColor.withOpacity(0.2),
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
            );
          },
        );
      },
    );
  }
}

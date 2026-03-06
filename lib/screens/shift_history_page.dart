import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/shift_entry.dart';
import 'add_shift_page.dart';

// [STUDY NOTE]: 앱 홈 화면에서 '전체보기'를 눌렀을 때 나타나는 기존 기록 전체 조회 페이지입니다.
class ShiftHistoryPage extends StatelessWidget {
  const ShiftHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 근무 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SalaryProvider>(
        builder: (context, provider, child) {
          final allShifts = provider.shifts;

          if (allShifts.isEmpty) {
            return const Center(
              child: Text('저장된 근무 기록이 없습니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          // [STUDY NOTE]: 월별로 데이터를 그룹화하여 보여주기 위한 맵핑 (연-월 기준)
          final Map<String, List<ShiftEntry>> groupedShifts = {};
          for (var shift in allShifts) {
            final monthKey = DateFormat('yyyy.MM').format(shift.startTime);
            if (!groupedShifts.containsKey(monthKey)) {
              groupedShifts[monthKey] = [];
            }
            groupedShifts[monthKey]!.add(shift);
          }

          final sortedKeys = groupedShifts.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final monthKey = sortedKeys[index];
              final shiftsInMonth = groupedShifts[monthKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      monthKey,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  ),
                  ...shiftsInMonth.map(
                      (shift) => _buildShiftCard(context, shift, provider)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShiftCard(
      BuildContext context, ShiftEntry shift, SalaryProvider provider) {
    final formatter = NumberFormat('#,###');
    IconData icon = Icons.wb_sunny;
    Color iconColor = Colors.orange;
    String tag = '주간';
    Color tagColor = Colors.grey;

    if (shift.isHoliday) {
      tag = '특근';
      tagColor = Colors.indigo;
      icon = Icons.star;
      iconColor = Colors.indigo;
    } else if (shift.startTime.hour >= 18 || shift.startTime.hour <= 5) {
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
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
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
          margin: const EdgeInsets.only(bottom: 12),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                              style: TextStyle(fontSize: 10, color: tagColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('HH:mm').format(shift.startTime)} ~ ${DateFormat('HH:mm').format(shift.endTime)} (${shift.totalDurationHours.toStringAsFixed(1)}h)',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
  }
}

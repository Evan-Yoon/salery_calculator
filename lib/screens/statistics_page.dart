import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/salary_provider.dart';
import '../models/shift_entry.dart';
import '../models/bonus_entry.dart';
import '../utils/report_generator.dart';
import '../widgets/main_bottom_nav.dart';

// [STUDY NOTE]: 이 페이지는 수집된 근무 기록과 보너스를 그래프로 보여주고, 알면 유용한 급여 팁을 제공합니다.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // [STUDY NOTE]: 사용자가 보고 싶은 통계의 기준(월별, 일별 등)을 선택하는 변수입니다. 0: 월별, 1: 일별
  int _selectedViewIndex = 0;
  final formatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 및 인사이트',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded,
                color: Colors.white, size: 22),
            tooltip: 'PDF 리포트 내보내기',
            onPressed: () async {
              try {
                // 저장 아이콘 클릭 시 로딩 인디케이터 시작
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('PDF 명세서를 생성 중입니다...'),
                      duration: Duration(seconds: 1)),
                );

                final provider =
                    Provider.of<SalaryProvider>(context, listen: false);
                // 통계 및 인사이트는 현재 달 기준 리포트를 기본으로 내보냅니다.
                final pdfBytes = await ReportGenerator.generateMonthlyReport(
                    provider, DateTime.now());

                // 기기 임시 폴더에 저장
                final tempDir = await getTemporaryDirectory();
                final file = File(
                    '${tempDir.path}/salary_report_${DateFormat('yyyyMM').format(DateTime.now())}.pdf');
                await file.writeAsBytes(pdfBytes);

                // 공유 모달 띄우기
                // ignore: deprecated_member_use
                await Share.shareXFiles([XFile(file.path)],
                    text: '이번 달 월간 급여/근무 명세 리포트입니다.');
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('리포트 생성 중 오류가 발생했습니다: $e')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<SalaryProvider>(
        builder: (context, provider, child) {
          final shifts = provider.shifts;
          final bonuses = provider.bonuses;
          final taxRate = provider.taxRate;

          if (shifts.isEmpty && bonuses.isEmpty) {
            return const Center(
              child: Text('기록된 데이터가 없어 통계를 낼 수 없습니다.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildViewToggler(),
              const SizedBox(height: 24),
              _buildBarChart(shifts, bonuses, taxRate),
              const SizedBox(height: 24),
              _buildIncomeRatioChart(shifts, bonuses, taxRate),
              const SizedBox(height: 24),
              _buildFunFacts(shifts),
              const SizedBox(height: 24),
              _buildMonthlyTipCard(),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 2), // 네비게이션 인덱스 2
    );
  }

  // [STUDY NOTE]: 월별 통계를 볼지 일별 통계를 볼지 선택하는 토글 스위치입니다.
  Widget _buildViewToggler() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleOption(0, '월별 보기'),
          _buildToggleOption(1, '일별 보기 (최근 7일)'),
        ],
      ),
    );
  }

  Widget _buildToggleOption(int index, String title) {
    final isSelected = _selectedViewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedViewIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // [STUDY NOTE]: fl_chart 패키지를 사용해 데이터를 막대그래프(Bar Chart)로 시각화합니다.
  Widget _buildBarChart(
      List<ShiftEntry> shifts, List<BonusEntry> bonuses, double taxRate) {
    // 1. 데이터 집계하기 (세금 공제 후 순수익 기준)
    Map<String, double> dataMap = {};
    DateTime now = DateTime.now();
    final double multiplier = 1.0 - taxRate;

    if (_selectedViewIndex == 0) {
      // 월별 (최근 6개월)
      final provider =
          Provider.of<SalaryProvider>(context, listen: false); // 주휴수당 계산을 위해 호출
      for (int i = 5; i >= 0; i--) {
        DateTime monthDate = DateTime(now.year, now.month - i);
        String label = '${monthDate.month}월';
        double monthTotal = 0;

        List<ShiftEntry> thisMonthShifts = [];

        for (var s in shifts) {
          if (s.startTime.year == monthDate.year &&
              s.startTime.month == monthDate.month) {
            monthTotal += s.totalPay * multiplier;
            thisMonthShifts.add(s);
          }
        }
        for (var b in bonuses) {
          if (b.date.year == monthDate.year &&
              b.date.month == monthDate.month) {
            monthTotal += b.amount * multiplier;
          }
        }

        // 해당 월의 주휴수당 합산 로직
        double monthlyHolidayAllowance = 0.0;
        Map<String, List<ShiftEntry>> shiftsByWeek = {};
        for (var s in thisMonthShifts) {
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
        for (var weekString in shiftsByWeek.keys) {
          List<String> parts = weekString.split('-');
          DateTime weekDate = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

          Map<String, dynamic> summary = provider.getWeeklySummary(weekDate);
          monthlyHolidayAllowance += summary['weeklyHolidayAllowance'];
        }

        monthTotal += (monthlyHolidayAllowance * multiplier);

        dataMap[label] = monthTotal;
      }
    } else {
      // 일별 (최근 7일)
      // 7일간의 데이터를 가져오되, 해당 일이 속한 주의 총 근무시간을 계산해야 정확한 주휴수당 분배가 가능합니다.
      // 가장 단순하고 명확한 방법은, 해당 7일 중 '각 주차의 마지막 근무일'에 주휴수당을 얹어주는 것입니다.
      final provider = Provider.of<SalaryProvider>(context, listen: false);

      for (int i = 6; i >= 0; i--) {
        DateTime dayDate = now.subtract(Duration(days: i));
        String label = DateFormat('MM.dd').format(dayDate);
        double dayTotal = 0;

        bool hasShiftToday = false;
        for (var s in shifts) {
          if (s.startTime.year == dayDate.year &&
              s.startTime.month == dayDate.month &&
              s.startTime.day == dayDate.day) {
            dayTotal += s.totalPay * multiplier;
            hasShiftToday = true;
          }
        }
        for (var b in bonuses) {
          if (b.date.year == dayDate.year &&
              b.date.month == dayDate.month &&
              b.date.day == dayDate.day) {
            dayTotal += b.amount * multiplier;
          }
        }

        // 오늘 근무가 있었다면, 오늘이 이번 주의 마지막 근무일인지 확인하여 주휴수당을 정산합니다.
        // (미래 일정이 등록되어 있을 수 있으므로, 단순화를 위해 일요일이거나 오늘이 마지막 조회일인 경우 정산)
        if (hasShiftToday && (dayDate.weekday == DateTime.sunday || i == 0)) {
          Map<String, dynamic> summary = provider.getWeeklySummary(dayDate);
          double weeklyAllowance = summary['weeklyHolidayAllowance'];
          dayTotal += (weeklyAllowance * multiplier);
        }

        dataMap[label] = dayTotal;
      }
    }

    // 2. 최대값 찾기 (그래프 비율 조정을 위함)
    double maxPay = 0;
    for (var val in dataMap.values) {
      if (val > maxPay) {
        maxPay = val;
      }
    }
    if (maxPay == 0) {
      maxPay = 10000; // 빈 그래프 방지
    }

    // 3. 차트로 그리기
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_selectedViewIndex == 0 ? '최근 6개월 수입 추이' : '최근 7일 수입 추이',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxPay * 1.2, // 맨 위에 여백 주기
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${dataMap.keys.elementAt(group.x.toInt())}\n',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '₩${formatter.format(rod.toY.round())}',
                            style: TextStyle(color: Colors.yellow[200]),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dataMap.keys.elementAt(value.toInt()),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: dataMap.entries.map((entry) {
                  int index = dataMap.keys.toList().indexOf(entry.key);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: Theme.of(context).colorScheme.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [STUDY NOTE]: 일한 돈(근로 소득)과 추가로 받은 돈(상여금)의 비율을 보여주는 원형(Pie) 차트입니다.
  Widget _buildIncomeRatioChart(
      List<ShiftEntry> shifts, List<BonusEntry> bonuses, double taxRate) {
    if (shifts.isEmpty && bonuses.isEmpty) {
      return const SizedBox();
    }

    final multiplier = 1.0 - taxRate;
    final shiftTotal =
        shifts.fold(0.0, (sum, s) => sum + s.totalPay * multiplier);
    final bonusTotal =
        bonuses.fold(0.0, (sum, b) => sum + b.amount * multiplier);
    final total = shiftTotal + bonusTotal;

    if (total == 0) {
      return const SizedBox();
    }

    final mainColor = Theme.of(context).colorScheme.primary;
    const bonusColor = Colors.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 25,
                sections: [
                  PieChartSectionData(
                    value: shiftTotal,
                    color: mainColor,
                    title:
                        '${((shiftTotal / total) * 100).toStringAsFixed(0)}%',
                    radius: 20,
                    titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  if (bonusTotal > 0)
                    PieChartSectionData(
                      value: bonusTotal,
                      color: bonusColor,
                      title:
                          '${((bonusTotal / total) * 100).toStringAsFixed(0)}%',
                      radius: 25,
                      titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('수입 구성비',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildLegend(
                    '기본 근로 수입', formatter.format(shiftTotal), mainColor),
                const SizedBox(height: 8),
                _buildLegend(
                    '비정기 수입 (상여/팁)', formatter.format(bonusTotal), bonusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String title, String value, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Text('₩$value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  // [STUDY NOTE]: 재미있는 수치들(가장 돈 많이 번 요일 등)을 계산해서 텍스트로 보여줍니다.
  Widget _buildFunFacts(List<ShiftEntry> shifts) {
    if (shifts.isEmpty) {
      return const SizedBox();
    }

    // 1. 역대 총 근무시간 계산
    double totalHours = shifts.fold(0.0, (sum, s) {
      int netMins =
          s.endTime.difference(s.startTime).inMinutes - s.breakTimeMinutes;
      return sum + (netMins > 0 ? netMins / 60.0 : 0.0);
    });

    // 2. 가장 일 많이 한/돈을 많이 번 요일 찾기
    List<int> weekdayEarns = List.filled(8, 0); // 1: 월, 7: 일
    for (var s in shifts) {
      weekdayEarns[s.startTime.weekday] += s.totalPay.toInt();
    }

    int maxEarn = 0;
    int bestWeekday = 1;
    for (int i = 1; i <= 7; i++) {
      if (weekdayEarns[i] > maxEarn) {
        maxEarn = weekdayEarns[i];
        bestWeekday = i;
      }
    }

    const weekdayNames = ['', '월', '화', '수', '목', '금', '토', '일'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎉 나의 알바 요약 포인트',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildInsightBox(
                    '총 달린 시간',
                    '${totalHours.toStringAsFixed(0)} 시간',
                    Icons.directions_run,
                    Colors.teal)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildInsightBox(
                    '황금 요일',
                    '${weekdayNames[bestWeekday]}요일!',
                    Icons.star,
                    Colors.orange)),
          ],
        )
      ],
    );
  }

  Widget _buildInsightBox(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // [STUDY NOTE]: 요청하신 4월 건강보험료 연말정산 등 '월별 꿀팁'을 유동적으로 보여주는 영역입니다.
  Widget _buildMonthlyTipCard() {
    int currentMonth = DateTime.now().month;
    String tipTitle = '💡 이달의 급여 꿀팁';
    String tipContent = '매월 급여 관리는 꼼꼼하게 기록하는 것부터 시작합니다.';

    if (currentMonth == 4) {
      tipTitle = '💡 4월은 왜 내 월급이 줄었지?';
      tipContent =
          '4월은 직장인들의 "건강보험료 연말정산"이 있는 달입니다. 작년 소득이 줄었다면 환급받지만, 늘었다면 추가 납부액이 공제되어 평소보다 실급여가 적을 수 있으니 당황하지 마세요!';
    } else if (currentMonth == 5) {
      tipTitle = '💡 5월 종합소득세 신고의 달';
      tipContent =
          '프리랜서(3.3%)나 알바로 소득을 신고하셨다면 5월 "종합소득세" 및 "근로장려금" 신청을 놓치지 마세요. 세금을 환급받을 수 있는 기회입니다!';
    } else if (currentMonth == 1) {
      tipTitle = '💡 1월부터 바뀌는 최저시급';
      tipContent =
          '새해가 되면 언제나 최저시급이 오릅니다. 알바를 하고 있다면 주휴수당과 기타 수당들이 새 기준에 맞춰 인상되었는지 근로계약서를 꼭 확인해보세요.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tipTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(tipContent,
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }
}

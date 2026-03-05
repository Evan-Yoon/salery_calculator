import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/salary_provider.dart';
import '../utils/shift_calculator.dart';

// [STUDY NOTE]: 월별 급여 및 통계 데이터를 바탕으로 PDF 문서를 생성하는 유틸리티 클래스입니다.
class ReportGenerator {
  // 한글 폰트를 지원하기 위해 기본 폰트(Roboto 등) 대신 Noto Sans KR 등을 사용해야 합니다.
  // 여기서는 시스템 기본 한글 인식 혹은 폰트를 불러와 세팅합니다.
  static Future<pw.Font> _getKoreanFont() async {
    // 앱 내 assets/fonts 에 폰트가 없다면, Google Fonts에서 온라인으로 받거나
    // 환경에 따라 기본 제공되는 fallback 폰트를 씁니다.
    // 여기서는 기본 내장 코어 폰트를 사용시 한글이 깨질 수 있으므로,
    // [중요]: 실제 프로덕션 패키징시에는 assets/fonts/NotoSansKR-Regular.ttf 를 넣어 사용하는 것이 좋습니다.
    // 현재는 pdf 패키지에 내장된 기본 한글 폰트를 시도합니다.
    try {
      final fontData =
          await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // 폰트가 없으면 시스템 fallback (한글이 깨질 위험 있음. 나중에 폰트 추가 권장)
      return pw.Font.helvetica();
    }
  }

  static Future<Uint8List> generateMonthlyReport(
      SalaryProvider provider, DateTime targetMonth) async {
    final pdf = pw.Document();

    // 폰트 처리 방어 코드
    pw.Font baseFont = await _getKoreanFont();
    pw.Font boldFont = await _getKoreanFont();

    final ttf = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );

    // 날짜 포맷
    final monthFormat = DateFormat('yyyy년 MM월');
    final numberFormat = NumberFormat('#,###');

    // 통계 데이터 산출 로직 (StatisticsPage와 동일한 로직 적용)
    final filteredShifts = provider.shifts.where((s) =>
        s.startTime.year == targetMonth.year &&
        s.startTime.month == targetMonth.month);

    final filteredBonuses = provider.bonuses.where((b) =>
        b.date.year == targetMonth.year && b.date.month == targetMonth.month);

    double totalBasePay = 0;
    double totalOvertimePay = 0;
    double totalNightPay = 0;
    double totalHolidayPay = 0;
    double totalBonus = 0;
    double totalWorkHours = 0;

    for (var s in filteredShifts) {
      double curNetHours = s.totalDurationHours - (s.breakTimeMinutes / 60.0);
      if (curNetHours < 0) curNetHours = 0;

      double base = BasePayCalculator.calculate(
          netHours: curNetHours,
          isHoliday: s.isHoliday,
          hourlyWage: s.hourlyWage,
          isFiveOrMoreEmployees: provider.isFiveOrMoreEmployees);
      double night = NightShiftCalculator.calculate(
          startTime: s.startTime,
          endTime: s.endTime,
          netHours: curNetHours,
          hourlyWage: s.hourlyWage,
          isFiveOrMoreEmployees: provider.isFiveOrMoreEmployees);
      double holidayOvertime = BasePayCalculator.calculateHolidayOvertime(
          netHours: curNetHours,
          isHoliday: s.isHoliday,
          hourlyWage: s.hourlyWage,
          isFiveOrMoreEmployees: provider.isFiveOrMoreEmployees);

      double overtime = s.totalPay - base - night - holidayOvertime;
      if (overtime < 0) overtime = 0; // 부동소수점 오차 방어

      totalBasePay += base;
      totalOvertimePay += overtime;
      totalNightPay += night;
      totalHolidayPay += holidayOvertime;
      totalWorkHours += curNetHours;
    }

    for (var b in filteredBonuses) {
      totalBonus += b.amount;
    }

    // 주휴수당 합산 (주 단위)
    Map<String, List<dynamic>> shiftsByWeek = {};
    for (var s in filteredShifts) {
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

    double totalWeeklyHolidayAllowance = 0;
    for (var weekString in shiftsByWeek.keys) {
      List<String> parts = weekString.split('-');
      DateTime weekDate = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      Map<String, dynamic> summary = provider.getWeeklySummary(weekDate);
      totalWeeklyHolidayAllowance += summary['weeklyHolidayAllowance'];
    }

    final preTaxTotal = totalBasePay +
        totalOvertimePay +
        totalNightPay +
        totalHolidayPay +
        totalWeeklyHolidayAllowance +
        totalBonus;

    final deduatableTotal = preTaxTotal; // 식대 비과세 등 향후 확장 가능성
    final taxAmount = deduatableTotal * provider.taxRate;
    final netPay = preTaxTotal - taxAmount;

    // PDF 페이지 생성
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: ttf,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 헤더 영력
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('급여 명세 실적 리포트',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(monthFormat.format(targetMonth),
                        style: const pw.TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                  '작성일자: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.SizedBox(height: 20),

              // 급여 총괄표
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                padding: const pw.EdgeInsets.all(15),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('실수령 추정액 (Net Pay)',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${numberFormat.format(netPay)} 원',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // 상세 내역 테이블
              pw.Text('지급 내역 (근무시간: ${totalWorkHours.toStringAsFixed(1)} h)',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  _buildTableRow('기본급 (Base Pay)', totalBasePay, numberFormat),
                  _buildTableRow(
                      '연장 수당 (Overtime)', totalOvertimePay, numberFormat),
                  _buildTableRow(
                      '야간 수당 (Night Shift)', totalNightPay, numberFormat),
                  _buildTableRow(
                      '휴일 수당 (Holiday)', totalHolidayPay, numberFormat),
                  if (provider.assumeFullAttendance)
                    _buildTableRow('주휴 수당 (Weekly Holiday)',
                        totalWeeklyHolidayAllowance, numberFormat),
                  _buildTableRow('기타 수당/상여금 (Bonus)', totalBonus, numberFormat),
                  _buildTableRow('지급액 합계 (Pre-tax)', preTaxTotal, numberFormat,
                      isBold: true, bgColor: PdfColors.grey100),
                ],
              ),
              pw.SizedBox(height: 20),

              // 공제 내역 테이블
              pw.Text('공제 내역',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  _buildTableRow(
                      '세금/보험료 (Tax: ${(provider.taxRate * 100).toStringAsFixed(1)}%)',
                      taxAmount,
                      numberFormat),
                  _buildTableRow('공제액 합계 (Deductions)', taxAmount, numberFormat,
                      isBold: true, bgColor: PdfColors.red50),
                ],
              ),

              pw.Spacer(),

              // 하단 면책 조항
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                '※ 본 명세서는 사용자가 입력한 데이터를 바탕으로 작성된 [참고/추정용] 자료입니다.\n'
                '※ 시급: ${numberFormat.format(provider.hourlyWage)}원 | 사업장 규모: ${provider.isFiveOrMoreEmployees ? "5인 이상" : "5인 미만"} | 주휴수당 가정: ${provider.assumeFullAttendance ? "개근" : "미적용"}\n'
                '※ 실제 수령액 및 세금/4대보험 공제액은 근로계약서, 취업규칙, 사업장 상황에 따라 달라질 수 있으며 본 리포트는 법적 증빙 효력이 없습니다.',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(
      String label, double amount, NumberFormat format,
      {bool isBold = false, PdfColor? bgColor}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label,
              style: pw.TextStyle(
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text('${format.format(amount)} 원',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }
}

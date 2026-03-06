import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/shift_entry.dart';
import '../models/bonus_entry.dart';

// [STUDY NOTE]: 근무 기록 데이터를 CSV 형식 문자열로 변환하는 유틸리티입니다.
// 엑셀, 구글 시트 등 스프레드시트 앱에서 바로 열 수 있는 .csv 파일을 생성합니다.
class CsvGenerator {
  static String generateShiftsCsv(SalaryProvider provider, DateTime? month) {
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('HH:mm');

    List<ShiftEntry> shifts = provider.shifts;
    List<BonusEntry> bonuses = provider.bonuses;

    // 특정 달 필터링
    if (month != null) {
      shifts = shifts
          .where((s) =>
              s.startTime.year == month.year &&
              s.startTime.month == month.month)
          .toList();
      bonuses = bonuses
          .where(
              (b) => b.date.year == month.year && b.date.month == month.month)
          .toList();
    }

    final rows = <List<String>>[];

    // ── 근무 기록 섹션 ──
    rows.add(['[근무 기록]']);
    rows.add([
      '날짜',
      '시작 시간',
      '종료 시간',
      '휴게(분)',
      '공휴일',
      '시급(원)',
      '배율',
      '총 급여(원)',
    ]);

    for (final s in shifts) {
      rows.add([
        dateFmt.format(s.date),
        timeFmt.format(s.startTime),
        timeFmt.format(s.endTime),
        s.breakTimeMinutes.toString(),
        s.isHoliday ? '예' : '아니오',
        fmt.format(s.hourlyWage.toInt()),
        s.payMultiplier.toStringAsFixed(1),
        fmt.format(s.totalPay.toInt()),
      ]);
    }

    rows.add([]); // 빈 줄

    // ── 비정기 수입 섹션 ──
    rows.add(['[비정기 수입 (상여/팁)]']);
    rows.add(['날짜', '메모', '금액(원)']);

    for (final b in bonuses) {
      rows.add([
        dateFmt.format(b.date),
        b.description,
        fmt.format(b.amount.toInt()),
      ]);
    }

    rows.add([]); // 빈 줄

    // ── 요약 섹션 ──
    final shiftTotal = shifts.fold(0.0, (sum, s) => sum + s.totalPay);
    final bonusTotal = bonuses.fold(0.0, (sum, b) => sum + b.amount);
    final preTax = shiftTotal + bonusTotal;
    final deduction = preTax * provider.taxRate;
    final net = preTax - deduction;

    rows.add(['[요약]']);
    rows.add(['항목', '금액']);
    rows.add(['근무 급여 합계', '${fmt.format(shiftTotal.toInt())}원']);
    rows.add(['비정기 수입 합계', '${fmt.format(bonusTotal.toInt())}원']);

    if (provider.taxRate > 0) {
      rows.add([
        '세금/보험료 공제 (${(provider.taxRate * 100).toStringAsFixed(1)}%)',
        '-${fmt.format(deduction.toInt())}원'
      ]);
    }

    rows.add(['실수령 추정액', '${fmt.format(net.toInt())}원']);
    rows.add([]);
    rows.add(['※ 본 파일은 참고용이며 법적 증빙 효력이 없습니다.']);

    return _encodeCsv(rows);
  }

  /// 각 행의 셀을 쉼표로 연결하고, 쉼표/따옴표/줄바꿈이 포함된 셀은 큰따옴표로 감쌉니다.
  static String _encodeCsv(List<List<String>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
          return '"${cell.replaceAll('"', '""')}"';
        }
        return cell;
      }).join(',');
    }).join('\n');
  }
}

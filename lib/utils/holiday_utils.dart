import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../repositories/holiday_repository.dart';

class HolidayUtils {
  // 메모리에 캐싱할 공휴일 데이터
  static final Map<String, String> _holidays = {};

  // 데이터 출처를 UI에 표시하기 위한 상태 변수
  static String dataSourceProvider = '알 수 없음';

  // 데이터 소스 설정
  static final HolidayRepository _fallbackRepo =
      LocalFallbackHolidayRepository();

  // [STUDY NOTE]: 앱 시작 시(예: main.dart) 호출하여 미리 2024~2026년 공휴일 데이터를 로드(Fetch)해둡니다.
  // 첫 번째로 Remote API를 시도하고, 실패 시 내장된 Fallback을 사용하도록 구성된 구조입니다.
  static Future<void> initializeHolidays() async {
    try {
      // 1. 공공데이터 연동 시도
      final String apiKey = dotenv.env['HOLIDAY_API_KEY'] ?? '';
      final HolidayRepository remoteRepo =
          RemoteHolidayRepository(apiKey: apiKey);

      final holidays2024 = await remoteRepo.fetchHolidays(2024);
      final holidays2025 = await remoteRepo.fetchHolidays(2025);
      final holidays2026 = await remoteRepo.fetchHolidays(2026);

      _holidays.addAll(holidays2024);
      _holidays.addAll(holidays2025);
      _holidays.addAll(holidays2026);

      dataSourceProvider = '공공데이터포털 연동 (실시간)';
    } catch (e) {
      // 2. 실패 시 Fallback(하드코딩) 파싱
      final fallback2024 = await _fallbackRepo.fetchHolidays(2024);
      final fallback2025 = await _fallbackRepo.fetchHolidays(2025);
      final fallback2026 = await _fallbackRepo.fetchHolidays(2026);

      _holidays.addAll(fallback2024);
      _holidays.addAll(fallback2025);
      _holidays.addAll(fallback2026);

      dataSourceProvider = '내장 오프라인 데이터 (Fallback)';
    }
  }

  static bool isHoliday(DateTime date) {
    String dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _holidays.containsKey(dateString);
  }

  static String? getHolidayName(DateTime date) {
    String dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _holidays[dateString];
  }

  /// 해당 날짜가 속한 주의 월요일을 반환합니다.
  static DateTime getFirstDayOfWeek(DateTime date) {
    int daysToSubtract = (date.weekday - DateTime.monday) % 7;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }
}

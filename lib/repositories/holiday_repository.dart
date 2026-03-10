import 'dart:convert';
import 'package:http/http.dart' as http;

// [STUDY NOTE]: 데이터 소스(API vs 로컬 하드코딩) 분리를 위한 인터페이스입니다.
abstract class HolidayRepository {
  Future<Map<String, String>> fetchHolidays(int year);
}

// [STUDY NOTE]: 만약 API 호출에 실패하거나 오프라인 상태일 경우 사용하는 '안전 장치(Fallback)' 입니다.
class LocalFallbackHolidayRepository implements HolidayRepository {
  // 기존의 하드코딩된 데이터를 여기에 보관합니다.
  final Map<String, String> _hardcodedHolidays = {
    // 2024
    '2024-01-01': '신정',
    '2024-02-09': '설날 연휴',
    '2024-02-10': '설날',
    '2024-02-11': '설날 연휴',
    '2024-02-12': '대체공휴일(설날)',
    '2024-03-01': '3·1절',
    '2024-04-10': '제22대 국회의원 선거',
    '2024-05-05': '어린이날',
    '2024-05-06': '대체공휴일(어린이날)',
    '2024-05-15': '부처님오신날',
    '2024-06-06': '현충일',
    '2024-08-15': '광복절',
    '2024-09-16': '추석 연휴',
    '2024-09-17': '추석',
    '2024-09-18': '추석 연휴',
    '2024-10-01': '국군의 날 (임시공휴일)',
    '2024-10-03': '개천절',
    '2024-10-09': '한글날',
    '2024-12-25': '기독탄신일',

    // 2025
    '2025-01-01': '신정',
    '2025-01-28': '설날 연휴',
    '2025-01-29': '설날',
    '2025-01-30': '설날 연휴',
    '2025-03-01': '3·1절',
    '2025-03-03': '대체공휴일(3·1절)',
    '2025-05-05': '어린이날/부처님오신날', // 겹침
    '2025-05-06': '대체공휴일(어린이날)',
    '2025-06-06': '현충일',
    '2025-08-15': '광복절',
    '2025-10-03': '개천절',
    '2025-10-05': '추석 연휴',
    '2025-10-06': '추석',
    '2025-10-07': '추석 연휴',
    '2025-10-08': '대체공휴일(추석)',
    '2025-10-09': '한글날',
    '2025-12-25': '기독탄신일',

    // 2026
    '2026-01-01': '신정',
    '2026-02-16': '설날 연휴',
    '2026-02-17': '설날',
    '2026-02-18': '설날 연휴',
    '2026-03-01': '3·1절',
    '2026-03-02': '대체공휴일(3·1절)',
    '2026-05-05': '어린이날',
    '2026-05-24': '부처님오신날',
    '2026-05-25': '대체공휴일(부처님오신날)',
    '2026-06-06': '현충일',
    '2026-08-15': '광복절',
    '2026-08-17': '대체공휴일(광복절)',
    '2026-09-24': '추석 연휴',
    '2026-09-25': '추석',
    '2026-09-26': '추석 연휴',
    '2026-10-03': '개천절',
    '2026-10-05': '대체공휴일(개천절)',
    '2026-10-09': '한글날',
    '2026-12-25': '기독탄신일',
  };

  @override
  Future<Map<String, String>> fetchHolidays(int year) async {
    // 하드코딩 데이터 중 해당 연도의 데이터만 필터링하여 반환합니다.
    Map<String, String> result = {};
    _hardcodedHolidays.forEach((dateStr, name) {
      if (dateStr.startsWith(year.toString())) {
        result[dateStr] = name;
      }
    });

    // 딜레이를 주어 비동기(Future) 동작을 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100));
    return result;
  }
}

// [STUDY NOTE]: 공공데이터포털(Data.go.kr) 특일정보 API 연동용 클래스입니다
class RemoteHolidayRepository implements HolidayRepository {
  final String apiKey;
  RemoteHolidayRepository({required this.apiKey});

  @override
  Future<Map<String, String>> fetchHolidays(int year) async {
    if (apiKey.isEmpty) {
      throw Exception("API Key is empty for Remote Fetches.");
    }

    final url = Uri.parse(
        'https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo?ServiceKey=$apiKey&solYear=$year&numOfRows=100&_type=json');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedData = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decodedData);

      final body = data['response']['body'];
      final totalCount = body['totalCount'];

      if (totalCount == 0) return {};

      final items = body['items']['item'];
      Map<String, String> holidays = {};

      if (items is List) {
        for (var item in items) {
          if (item['isHoliday'] == 'Y') {
            String dateStr = item['locdate'].toString();
            String formattedDate =
                '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
            holidays[formattedDate] = item['dateName'];
          }
        }
      } else if (items is Map) {
        if (items['isHoliday'] == 'Y') {
          String dateStr = items['locdate'].toString();
          String formattedDate =
              '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
          holidays[formattedDate] = items['dateName'];
        }
      }
      return holidays;
    } else {
      throw Exception(
          "Failed to fetch holidays from API. HTTP Status: ${response.statusCode}");
    }
  }
}

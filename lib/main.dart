// [STUDY NOTE]: 이 파일은 앱이 처음 시작될 때 실행되는 진입점(Entry point)입니다.
import 'package:flutter/material.dart';
// [STUDY NOTE]: provider는 상태 관리(State Management)를 위해 사용되는 패키지입니다.
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/salary_provider.dart';
import 'screens/home_page.dart';

// [STUDY NOTE]: main() 함수는 Dart 프로그램의 시작점입니다.
// runApp()을 호출하여 앱의 루트 위젯을 화면에 그립니다.
void main() {
  runApp(const MyApp());
}

// [STUDY NOTE]: MyApp은 앱의 뼈대를 이루는 루트 위젯입니다. 상태가 변하지 않으므로 StatelessWidget을 상속받습니다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [STUDY NOTE]: MultiProvider를 사용해 앱 전체에서 사용할 상태(Provider)들을 등록합니다.
    // 여기서는 SalaryProvider를 등록해 앱 전역에서 급여 데이터에 접근하고 변경할 수 있게 합니다.
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SalaryProvider())],
      // [STUDY NOTE]: MaterialApp은 Material Design을 사용하는 플러터 앱의 기본 위젯입니다.
      child: MaterialApp(
        title: 'Shift Salary Calculator',
        debugShowCheckedModeBanner:
            false, // [STUDY NOTE]: 화면 우측 상단의 디버그 배너를 숨깁니다.

        // [STUDY NOTE]: theme은 라이트 모드일 때의 앱 전체 디자인 테마를 설정합니다.
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Manrope',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2B8CEE),
            brightness: Brightness.light,
            surface: const Color(0xFFFFFFFF),
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        ),

        // [STUDY NOTE]: darkTheme은 다크 모드일 때의 디자인 테마를 설정합니다.
        darkTheme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Manrope',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2B8CEE),
            brightness: Brightness.dark,
            surface: const Color(0xFF1C2A38),
          ),
          scaffoldBackgroundColor: const Color(0xFF111A22),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111A22),
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(color: Color(0xFF1C2A38)),
        ),

        // [STUDY NOTE]: 기본적으로 다크 모드를 사용하도록 설정합니다.
        themeMode: ThemeMode.dark,

        // [STUDY NOTE]: 달력(DatePicker) 등을 한국어로 표시하기 위한 다국어(Localization) 설정입니다.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // [STUDY NOTE]: 앱에서 지원하는 언어를 설정합니다 (한국어, 영어).
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],

        // [STUDY NOTE]: 앱을 시작했을 때 가장 먼저 보여줄 화면입니다.
        home: const HomePage(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import '../utils/holiday_utils.dart';
import 'home_page.dart';
import 'legal_onboarding_page.dart';
import 'onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. 필요한 설정 로드
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Error loading .env file: $e');
    }

    // 2. 공휴일 데이터 초기화
    await HolidayUtils.initializeHolidays();

    // 3. SharedPreferences 데이터 로드 (SalaryProvider 내부에서 수행됨)
    if (!mounted) return;
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    await provider.loadData();

    // 4. 최소 노출 시간 보장 (부드러운 전환을 위해)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 5. 다음 화면 결정 및 이동
    Widget nextScreen;
    if (!provider.hasAgreedToLegal) {
      nextScreen = const LegalOnboardingPage();
    } else if (!provider.hasCompletedOnboarding) {
      nextScreen = const OnboardingPage();
    } else {
      nextScreen = const HomePage();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111821), // 요청하신 남색 배경
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 아이콘
            Image.asset(
              'assets/icon/app_icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 48),
            // 로딩 스피너 (뱅글뱅글 돌아가는 표시)
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

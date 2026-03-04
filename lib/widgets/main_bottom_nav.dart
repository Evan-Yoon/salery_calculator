import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/settings_page.dart';

// [STUDY NOTE]: 앱 하단의 탭 바(네비게이션 바)를 여러 화면에서 공통으로 사용하기 위해 분리한 위젯입니다.
class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // 이미 현재 탭이면 무시합니다.

    Widget page;
    // 현재는 홈(0)과 설정(3) 탭만 작동합니다.
    if (index == 0) {
      page = const HomePage();
    } else if (index == 3) {
      page = const SettingsPage();
    } else {
      return; // 캘린더나 통계 탭은 아직 준비 중
    }

    // [STUDY NOTE]: 선택한 탭 화면으로 데이터를 유지한 채로 전환합니다.
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => page,
        // 애니메이션 없이 즉시 전환 (탭 전환 느낌을 위해)
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).cardTheme.color,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '캘린더'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: '통계'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
      ],
    );
  }
}

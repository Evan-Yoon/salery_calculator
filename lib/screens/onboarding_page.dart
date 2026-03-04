import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import '../widgets/main_bottom_nav.dart';

// [STUDY NOTE]: 앱을 처음 실행했을 때 근무 형태(교대 vs 고정)를 묻는 온보딩 화면입니다.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calculate_rounded,
                  size: 80, color: Color(0xFF2B8CEE)),
              const SizedBox(height: 32),
              const Text(
                '환영합니다!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '정확한 급여 계산과 맞춤형 화면 제공을 위해\n회원님의 근무 형태를 선택해 주세요.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // [STUDY NOTE]: 교대 근무자용 버튼 (데이/이브/나이트 프리셋 기능 제공)
              _buildChoiceButton(
                context: context,
                title: '교대 근무자 (스케줄 근무)',
                subtitle: '데이, 이브닝, 나이트 등 매일 근무 시간이 바뀌는 분',
                icon: Icons.sync,
                onTap: () => _selectWorkerType(context, true),
              ),

              const SizedBox(height: 16),

              // [STUDY NOTE]: 고정 시간 근무자용 버튼 (프리셋 기능 숨김 처리)
              _buildChoiceButton(
                context: context,
                title: '고정 시간 근무자',
                subtitle: '주 5일 평일 근무 등 정해진 시간에 일하시는 분',
                icon: Icons.access_time_filled,
                onTap: () => _selectWorkerType(context, false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 28, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // [STUDY NOTE]: 버튼 클릭 시 상태(교대 여부)를 설정하고 홈 화면(BottomNav)으로 이동합니다.
  void _selectWorkerType(BuildContext context, bool isShiftWorker) {
    Provider.of<SalaryProvider>(context, listen: false)
        .setWorkerType(isShiftWorker);

    // 화면 교체 (뒤로 가기 방지)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const MainBottomNav(currentIndex: 0)),
    );
  }
}

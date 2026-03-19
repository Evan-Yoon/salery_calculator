import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import 'onboarding_page.dart';

// [STUDY NOTE]: 앱을 최초 실행 시 반드시 동의해야 하는 법적 고지 및 개인정보 취급 방침 화면입니다.
class LegalOnboardingPage extends StatelessWidget {
  const LegalOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.gavel_rounded,
                  size: 60, color: Color(0xFF2B8CEE)),
              const SizedBox(height: 24),
              const Text(
                '앱 이용을 위한\n법적 고지 및 개인정보 안내',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BulletPoint(
                          title: '본 앱은 참고용 계산기입니다.',
                          description:
                              '계산된 급여와 수당 내역은 일반적인 기준에 기초한 참고용(추정치)입니다. 실제 임금은 개별 근로계약, 취업규칙, 사업장 상황 등에 따라 변동될 수 있습니다.',
                        ),
                        SizedBox(height: 20),
                        _BulletPoint(
                          title: '법적 증빙 자료로 사용할 수 없습니다.',
                          description:
                              '어떠한 경우에도 노사 갈등, 임금 체불 등 법적 분쟁 상황에서 증거 자료로 활용될 수 없으며, 정확한 법률 안내는 고용노동부 또는 공인노무사에게 문의하시기 바랍니다.',
                        ),
                        SizedBox(height: 20),
                        _BulletPoint(
                          title: '데이터는 기기에 안전하게 저장됩니다.',
                          description:
                              '입력된 근무 및 급여 정보는 기본적으로 사용자의 기기 내부에만 저장됩니다. 단, 프리미엄 백업 기능(Google 클라우드 로그인 연동) 사용 시에는 데이터 보존을 위해 사용자의 개인 클라우드에 데이터가 안전하게 백업 및 보관됩니다.',
                        ),
                        SizedBox(height: 20),
                        _BulletPoint(
                          title: '법정 규격은 변동될 수 있습니다.',
                          description:
                              '공휴일, 4대보험 요율, 세금 등은 정부 정책 변화에 따라 달라질 수 있으므로 반드시 최신 업데이트를 유지해주시기 바랍니다.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 동의 시 상태 업데이트 후 다음 화면(OnboardingPage)으로 이동
                  Provider.of<SalaryProvider>(context, listen: false)
                      .agreeToLegalTerms();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OnboardingPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B8CEE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '위 내용을 확인하고 동의합니다',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '동의 버튼을 누르시면 앱 진입 및 데이터 저장이 시작됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String title;
  final String description;

  const _BulletPoint({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4.0, right: 8.0),
              child:
                  Icon(Icons.check_circle, size: 16, color: Color(0xFF2B8CEE)),
            ),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: Text(
            description,
            style:
                const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
        ),
      ],
    );
  }
}

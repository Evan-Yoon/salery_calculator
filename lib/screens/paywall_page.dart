import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../premium/premium_state.dart';

// [STUDY NOTE]: 앱 내 프리미엄 기능 결제를 유도하는 상세 페이지입니다.
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // 헤더 섹션
              const Text(
                '교대근무를 자동으로 관리하고\n월말 정산을 정확하게 확인하세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 기능 목록 섹션
              Expanded(
                child: ListView(
                  children: [
                    _buildFeatureItem(Icons.auto_awesome, '교대 패턴 자동 생성'),
                    _buildFeatureItem(Icons.local_hospital, '병원별 급여 규정 저장'),
                    _buildFeatureItem(Icons.analytics, '월말 정산 리포트'),
                    _buildFeatureItem(Icons.cloud_sync, '기기 변경 시 데이터 복원'),
                    _buildFeatureItem(Icons.table_chart, '엑셀 리포트'),
                  ],
                ),
              ),

              // 가격 및 결제 버튼 섹션
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceCard(
                      context: context,
                      title: '월 구독',
                      price: '₩2,000',
                      period: '/월',
                      onTap: () {
                        final provider = Provider.of<PremiumProvider>(context,
                            listen: false);
                        provider.setPremium(true);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('월 구독이 시작되었습니다! (테스트 모드)')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceCard(
                      context: context,
                      title: '연 구독',
                      price: '₩19,900',
                      period: '/연',
                      isPopular: true,
                      onTap: () {
                        final provider = Provider.of<PremiumProvider>(context,
                            listen: false);
                        provider.setPremium(true);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('연 구독이 시작되었습니다! (테스트 모드)')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  '나중에',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildPriceCard({
    required BuildContext context,
    required String title,
    required String price,
    required String period,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isPopular
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular
                ? Theme.of(context).colorScheme.primary
                : Colors.white10,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('인기',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(price,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(period,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

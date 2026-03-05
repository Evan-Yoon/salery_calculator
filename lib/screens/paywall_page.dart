import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../premium/premium_state.dart';

// [STUDY NOTE]: 앱 내 프리미엄 기능 결제를 유도하는 상세 페이지입니다.
// 타겟 사용자(간호사/교대근무자)의 전환율을 높이기 위해 디자인되었습니다.
class PaywallPage extends StatefulWidget {
  final String? entryPoint;
  final String? featureHint;

  const PaywallPage({
    super.key,
    this.entryPoint,
    this.featureHint,
  });

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  // 연간 구독이 기본 선택되도록 true로 초기화
  bool _isYearlySelected = true;
  late final VoidCallback _premiumListener;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PremiumProvider>(context, listen: false);
    _premiumListener = () {
      if (provider.isPremium && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium 구독이 활성화되었습니다!')),
        );
        Navigator.pop(context);
      }
    };
    provider.addListener(_premiumListener);
  }

  @override
  void dispose() {
    Provider.of<PremiumProvider>(context, listen: false)
        .removeListener(_premiumListener);
    super.dispose();
  }

  void _onSubscribe() async {
    final iapService =
        Provider.of<PremiumProvider>(context, listen: false).iapService;
    if (_isYearlySelected) {
      await iapService.buyYearly();
    } else {
      await iapService.buyMonthly();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 닫기 버튼 영역
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 핵심 컨텐츠 영역 (스크롤 가능)
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  // 진입점 힌트 서브 텍스트
                  if (widget.featureHint != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '이 기능은 Premium에서 제공됩니다.\n교대 패턴을 자동으로 생성하고 월말 정산을 더 쉽게 관리하세요.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 메인 헤드라인
                  const Text(
                    '복잡한 교대 스케줄과 급여 계산을\n한 번에 해결하세요',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 기능 강조 카드 목록 (1줄 설명)
                  _buildFeatureCard(Icons.auto_awesome, '교대 패턴 자동 생성 및 반복'),
                  _buildFeatureCard(
                      Icons.local_hospital, '병원별 급여 규정 맞춤 저장 (야간/공휴일 등)'),
                  _buildFeatureCard(
                      Icons.receipt_long, '증빙용 월말 정산 리포트 및 엑셀 내보내기'),
                  _buildFeatureCard(Icons.cloud_sync, '기기 변경 시 안전한 데이터 백업/복원'),
                  _buildFeatureCard(Icons.layers, '수당 템플릿 및 프리셋 공유'),
                  _buildFeatureCard(
                      Icons.notifications_active, '근무 전/월말/주휴 스마트 알림 제공'),

                  const SizedBox(height: 32),

                  // 웹 환경 처리
                  if (kIsWeb) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          '프리미엄 구독은 모바일 앱에서만 가능합니다.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ] else ...[
                    // 가격 선택 UI
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildPriceSelector(
                            isYearly: true,
                            title: '연간 구독',
                            price: '₩19,900',
                            period: '/ 연',
                            subText: '월 ₩1,658',
                            badgeText: 'BEST VALUE',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPriceSelector(
                            isYearly: false,
                            title: '월간 구독',
                            price: '₩2,000',
                            period: '/ 월',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 무료 체험 안내 텍스트
                    const Text(
                      '3일 무료 체험 후 결제됩니다 · 언제든지 취소 가능',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // 메인 CTA 버튼
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isYearlySelected ? '3일 무료 체험으로 시작하기' : '월 구독 시작하기',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 나중에 버튼
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('나중에',
                        style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ),

                  // 구매 복원 버튼
                  TextButton(
                    onPressed: () async {
                      final iapService =
                          Provider.of<PremiumProvider>(context, listen: false)
                              .iapService;
                      await iapService.restore();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('구매 복원을 요청했습니다. 잠시 후 반영됩니다.')),
                        );
                      }
                    },
                    child: const Text('구매 복원 (Restore)',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            decoration: TextDecoration.underline)),
                  ),

                  const SizedBox(height: 16),

                  // 구독 가치 설명 (Why Premium)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Premium 구독은 앱 유지 및 기능 개선에 사용됩니다.\n더 정확한 교대 관리와 정산 기능을 위해 끊임없이 노력하겠습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 구독 정책 상세 안내
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _PolicyText('구독은 Apple ID 또는 Google 계정에 연결됩니다.'),
                        _PolicyText("기기 변경 시 동일 계정으로 로그인 후 '구매 복원'을 눌러주세요."),
                        _PolicyText('구독 취소는 스토어에서 언제든지 가능합니다.'),
                        _PolicyText(
                            '구독 취소 후 Premium 상태는 다음 결제 주기까지 유지될 수 있습니다.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 신뢰 메시지 (작은 글씨 & 아이콘)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustMessageItem(
                          icon: Icons.storefront, text: '스토어에서 관리됩니다'),
                      SizedBox(width: 8),
                      Text("·", style: TextStyle(color: Colors.grey)),
                      SizedBox(width: 8),
                      _TrustMessageItem(
                          icon: Icons.cancel_outlined, text: '언제든지 취소 가능'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustMessageItem(
                          icon: Icons.security, text: '데이터는 안전하게 저장/복원됩니다'),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSelector({
    required bool isYearly,
    required String title,
    required String price,
    required String period,
    String? subText,
    String? badgeText,
  }) {
    final isSelected = _isYearlySelected == isYearly;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearlySelected = isYearly;
        });
      },
      child: Container(
        height: 140, // Height consistency depending on layout
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.08)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const SizedBox(height: 24), // Keep alignment

            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            if (subText != null) ...[
              const SizedBox(height: 4),
              Text(
                subText,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrustMessageItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustMessageItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _PolicyText extends StatelessWidget {
  final String text;
  const _PolicyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }
}

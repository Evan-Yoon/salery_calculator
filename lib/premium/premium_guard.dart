import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'premium_features.dart';
import 'premium_state.dart';
import '../screens/paywall_page.dart';

// [STUDY NOTE]: 특정 위젯을 Premium 기능 전용으로 잠그거나 가리는 역할을 하는 UI 가드입니다.
// 앞으로 앱 내 모든 프리미엄 기능 페이지나 버튼을 만들 때는 반드시 이 PremiumGuard로 감싸주세요.
//
// [사용 예시]
// 1. 위젯 레벨: PremiumGuard(feature: ..., featureHint: "...", child: MyButton()) -> 투명도와 자물쇠 오버레이 적용
// 2. 페이지 레벨: SettingsPage 등에서 통째로 감싸서 진입 자체를 막거나 리다이렉트 유도 가능
class PremiumGuard extends StatelessWidget {
  final PremiumFeature feature;
  final Widget child;
  final Widget? lockedBuilder;

  /// Paywall 페이지로 전달될 진입점 식별자 (예: "home_banner", "settings_locked")
  final String? entryPoint;

  /// Paywall 페이지 상단에 노출될 기능 힌트 (예: "엑셀 리포트", "패턴 자동 생성")
  final String? featureHint;

  const PremiumGuard({
    super.key,
    required this.feature,
    required this.child,
    this.lockedBuilder,
    this.entryPoint,
    this.featureHint,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, _) {
        // 프리미엄 상태이거나 해당 기능이 열려있으면 그대로 child를 보여줍니다.
        if (premiumProvider.hasFeature(feature)) {
          return child;
        }

        // 잠겨있을 때의 기본 UI
        return lockedBuilder ?? _buildDefaultLockedUI(context);
      },
    );
  }

  Widget _buildDefaultLockedUI(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaywallPage(
              entryPoint: entryPoint,
              featureHint: featureHint,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 기존 UI를 약간 투명하게 보여줌
          Opacity(
            opacity: 0.3,
            child: IgnorePointer(child: child),
          ),
          // 잠금 아이콘 및 Premium 레이블
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Premium',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

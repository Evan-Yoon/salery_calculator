import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'premium_features.dart';
import 'premium_state.dart';
import '../screens/paywall_page.dart';

// [STUDY NOTE]: 특정 위젯을 Premium 기능 전용으로 잠그거나 가리는 역할을 하는 UI 가드입니다.
class PremiumGuard extends StatelessWidget {
  final PremiumFeature feature;
  final Widget child;
  final Widget? lockedBuilder;

  const PremiumGuard({
    super.key,
    required this.feature,
    required this.child,
    this.lockedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, _) {
        // 프리미엄 상태이거나 해당 기능이 열려있으면 그대로 child를 보여줍니다.
        if (premiumProvider.hasFeature(feature)) {
          return child;
        }

        // 잠겨있을 때의 기본 UI (lockedBuilder가 없다면 기본 잠금 오버레이 등을 보여줄 수 있습니다)
        return lockedBuilder ?? _buildDefaultLockedUI(context);
      },
    );
  }

  Widget _buildDefaultLockedUI(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaywallPage()),
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
          // 잠금 아이콘
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

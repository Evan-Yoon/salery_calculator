import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium_features.dart';
import '../services/revenue_cat_service.dart';

class PremiumState {
  final bool isPremium;
  final Set<PremiumFeature> enabledFeatures;

  PremiumState({
    required this.isPremium,
    required this.enabledFeatures,
  });

  // [STUDY NOTE]: 기본 상태는 무료(Premium 아님), 활성화된 프리미엄 기능은 없음.
  factory PremiumState.initial() {
    return PremiumState(
      isPremium: false,
      enabledFeatures: {},
    );
  }
}

class PremiumProvider extends ChangeNotifier {
  PremiumState _state = PremiumState.initial();
  bool _isLoading = true;

  int _monthlyPdfCount = 0;
  String _lastPdfMonth = '';

  PremiumState get state => _state;
  bool get isPremium => _state.isPremium;
  bool get isLoading => _isLoading;
  int get monthlyPdfCount => _monthlyPdfCount;

  PremiumProvider() {
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool('isPremium') ?? false;

      _monthlyPdfCount = prefs.getInt('monthly_pdf_count') ?? 0;
      _lastPdfMonth = prefs.getString('last_pdf_month') ?? '';

      // 월이 바뀌었으면(또는 초기상태면) 카운트 리셋
      final currentMonth = DateTime.now().toString().substring(0, 7); // yyyy-MM
      if (_lastPdfMonth != currentMonth) {
        _monthlyPdfCount = 0;
        _lastPdfMonth = currentMonth;
        await prefs.setInt('monthly_pdf_count', 0);
        await prefs.setString('last_pdf_month', currentMonth);
      }

      // RevenueCat을 통한 실제 결제 기록 복원 및 확인
      final rcService = RevenueCatService();
      final isActuallyPremium = await rcService.isPremiumActive();

      // 로컬 SharedPreferences 값과 RevenueCat 상태 중 하나라도 true면 프리미엄으로 간주할 수 있음
      // (일반적으로는 RevenueCat 상태가 더 정확함)
      final effectivePremium = isPremium || isActuallyPremium;

      _state = PremiumState(
        isPremium: effectivePremium,
        enabledFeatures: effectivePremium ? PremiumFeature.values.toSet() : {},
      );

      // 만약 RevenueCat에서 프리미엄임이 확인되었는데 로컬이 false였다면 로컬 동기화
      if (isActuallyPremium && !isPremium) {
        await prefs.setBool('isPremium', true);
      }
    } catch (e) {
      debugPrint("Failed to load premium state: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final rcService = RevenueCatService();
      final success = await rcService.restorePurchases();

      if (success) {
        await setPremium(true);
      }
    } catch (e) {
      debugPrint("Failed to restore purchases: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPremium(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', isPremium);

      _state = PremiumState(
        isPremium: isPremium,
        enabledFeatures: isPremium ? PremiumFeature.values.toSet() : {},
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to save premium state: $e");
    }
  }

  bool hasFeature(PremiumFeature feature) {
    return _state.enabledFeatures.contains(feature) || _state.isPremium;
  }

  // PDF 생성 가능 여부를 체크하고, 가능하면 카운트를 1 올림
  Future<bool> checkAndIncrementPdfCount() async {
    // 1. 프리미엄 유저면 무제한 허용
    if (isPremium) return true;

    // 2. 월이 바뀌었는지 재확인
    final currentMonth = DateTime.now().toString().substring(0, 7);
    if (_lastPdfMonth != currentMonth) {
      _monthlyPdfCount = 0;
      _lastPdfMonth = currentMonth;
    }

    // 3. 무료 유저는 월 1회 제한
    if (_monthlyPdfCount >= 1) {
      return false; // 제한에 걸림 (Paywall로 이동 시켜야 함)
    }

    // 4. 허용됨 -> 카운트 증가 저장
    _monthlyPdfCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthly_pdf_count', _monthlyPdfCount);
    await prefs.setString('last_pdf_month', _lastPdfMonth);
    notifyListeners();

    return true;
  }
}

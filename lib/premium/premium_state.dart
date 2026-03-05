import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium_features.dart';
import 'iap/iap_service.dart';

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
  bool _isBannerDismissed = false;

  late final IapService _iapService;

  PremiumState get state => _state;
  bool get isPremium => _state.isPremium;
  bool get isLoading => _isLoading;
  bool get isBannerDismissed => _isBannerDismissed;
  int get monthlyPdfCount => _monthlyPdfCount;
  IapService get iapService => _iapService;

  PremiumProvider() {
    _iapService = IapService(this);
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      _monthlyPdfCount = prefs.getInt('pdf_export_count') ?? 0;
      _lastPdfMonth = prefs.getString('pdf_export_month') ?? '';
      _isBannerDismissed = prefs.getBool('premium_banner_dismissed') ?? false;

      // 월이 바뀌었으면(또는 초기상태면) 카운트 리셋 (YYYYMM 포맷)
      final now = DateTime.now();
      final currentMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
      if (_lastPdfMonth != currentMonth) {
        _monthlyPdfCount = 0;
        _lastPdfMonth = currentMonth;
        await prefs.setInt('pdf_export_count', 0);
        await prefs.setString('pdf_export_month', currentMonth);
      }

      // 오프라인 캐시 상태 우선 적용
      final isPremiumCache = prefs.getBool('premium_enabled') ?? false;
      setPremium(isPremiumCache, source: "offline_cache");

      // IapService 초기화 (복원이 이뤄지며 스토어 상태가 최신화됨)
      if (!kIsWeb) {
        await _iapService.init();
      }
    } catch (e) {
      debugPrint("Failed to load premium state: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPremium(bool enabled, {String? source}) {
    debugPrint("setPremium: $enabled, source: $source");
    _state = PremiumState(
      isPremium: enabled,
      enabledFeatures: enabled ? PremiumFeature.values.toSet() : {},
    );
    notifyListeners();

    // 오프라인용 캐시 저장
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('premium_enabled', enabled);
    });
  }

  bool hasFeature(PremiumFeature feature) {
    return _state.enabledFeatures.contains(feature) || _state.isPremium;
  }

  // PDF 생성 가능 여부를 체크하고, 가능하면 카운트를 1 올림
  Future<bool> checkAndIncrementPdfCount() async {
    // 1. 프리미엄 유저면 무제한 허용
    if (isPremium) return true;

    // 2. 월이 바뀌었는지 재확인 (YYYYMM 포맷)
    final now = DateTime.now();
    final currentMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
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
    await prefs.setInt('pdf_export_count', _monthlyPdfCount);
    await prefs.setString('pdf_export_month', _lastPdfMonth);
    notifyListeners();

    return true;
  }

  Future<void> dismissBanner() async {
    _isBannerDismissed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium_banner_dismissed', true);
    notifyListeners();
  }
}

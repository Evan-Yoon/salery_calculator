import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_ids.dart';
import '../premium_state.dart';

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  final PremiumProvider premiumProvider;
  Timer? _verifyTimer;
  static const int _maxProcessedKeys = 50;

  IapService(this.premiumProvider);

  Future<void> init() async {
    // 1. purchaseStream.listen 먼저 등록
    _subscription = _iap.purchaseStream.listen(_listenToPurchaseUpdates);

    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      debugPrint("스토어 결제 기능을 사용할 수 없습니다.");
      return;
    }

    // 2. queryProductDetails
    final response = await _iap.queryProductDetails(subscriptionIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("상품 조회 실패: ${response.notFoundIDs}");
    }
    _products = response.productDetails;

    // 3. 복원 전에는 상태를 그대로 두거나 필요한 경우 알 수 없는 상태로 설정.
    // 여기서 PremiumProvider가 이미 캐시와 TTL로 초기값을 설정했습니다.

    // 4. 앱 시작 시 구독 상태 "복원/조회" 수행 및 타임아웃 5초 대기 설정
    await _iap.restorePurchases();
    _startVerificationTimeout();
  }

  void _startVerificationTimeout() {
    _verifyTimer?.cancel();
    _verifyTimer = Timer(const Duration(seconds: 5), () {
      if (premiumProvider.status == PremiumStatus.unknown) {
        debugPrint(
            "IAP Restore Timeout: No purchases found, setting inactive.");
        premiumProvider.setPremium(PremiumStatus.inactive, source: "timeout");
      }
    });
  }

  void dispose() {
    _verifyTimer?.cancel();
    _subscription.cancel();
  }

  Future<void> buyMonthly() async {
    try {
      if (_products.isEmpty) throw Exception('상품 정보를 불러오지 못했습니다 (빈 상태).');
      final product = _products.firstWhere((p) => p.id == monthlyId);
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("buyMonthly error: $e");
      rethrow;
    }
  }

  Future<void> buyYearly() async {
    try {
      if (_products.isEmpty) throw Exception('상품 정보를 불러오지 못했습니다 (빈 상태).');
      final product = _products.firstWhere((p) => p.id == yearlyId);
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("buyYearly error: $e");
      rethrow;
    }
  }

  Future<void> restore() async {
    premiumProvider.setPremium(PremiumStatus.unknown, source: "manual_restore");
    await _iap.restorePurchases();
    _startVerificationTimeout();
  }

  Future<bool> _isKeyProcessed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('processed_purchase_keys') ?? [];
    return keys.contains(key);
  }

  Future<void> _markKeyProcessed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('processed_purchase_keys') ?? [];
    if (!keys.contains(key)) {
      keys.add(key);
      if (keys.length > _maxProcessedKeys) {
        keys.removeAt(0);
      }
      await prefs.setStringList('processed_purchase_keys', keys);
    }
  }

  void _listenToPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      final key = purchase.purchaseID ??
          "\${purchase.productID}_\${purchase.transactionDate}";

      // 중복 방지: 이미 처리된 키이고, pendingCompletePurchase가 아니면 스킵
      if (await _isKeyProcessed(key) && !purchase.pendingCompletePurchase) {
        debugPrint("Skipping duplicate purchase: \$key");
        continue;
      }
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint("Purchase pending: ${purchase.productID}");
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == monthlyId ||
              purchase.productID == yearlyId) {
            premiumProvider.setPremium(PremiumStatus.active,
                source: "purchaseStream");
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          await _markKeyProcessed(key);
          break;
        case PurchaseStatus.error:
          debugPrint("Purchase error: \${purchase.error}");
          break;
        case PurchaseStatus.canceled:
          debugPrint("Purchase canceled");
          break;
      }
    }
  }
}

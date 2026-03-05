import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'subscription_ids.dart';
import '../premium_state.dart';

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  final PremiumProvider premiumProvider;

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

    // 3. restorePurchases 호출 전에 Premium 상태를 false로 초기화 (취소/만료 대응)
    premiumProvider.setPremium(false, source: "startupCheck");

    // 4. 앱 시작 시 구독 상태 "복원/조회" 수행
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription.cancel();
  }

  Future<void> buyMonthly() async {
    try {
      final product = _products.firstWhere((p) => p.id == monthlyId);
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("buyMonthly error: $e");
    }
  }

  Future<void> buyYearly() async {
    try {
      final product = _products.firstWhere((p) => p.id == yearlyId);
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("buyYearly error: $e");
    }
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  void _listenToPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint("Purchase pending: ${purchase.productID}");
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == monthlyId ||
              purchase.productID == yearlyId) {
            premiumProvider.setPremium(true, source: "purchaseStream");
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          debugPrint("Purchase error: ${purchase.error}");
          break;
        case PurchaseStatus.canceled:
          debugPrint("Purchase canceled");
          break;
      }
    }
  }
}

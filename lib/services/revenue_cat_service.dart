import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  static const _entitlementId = 'premium'; // RevenueCat에서 설정한 Entitlement ID

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint(
          "RevenueCat is not supported on Web. Skipping initialization.");
      return;
    }
    await Purchases.setLogLevel(LogLevel.debug);

    String? apiKey;
    if (Platform.isAndroid) {
      apiKey = dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    } else if (Platform.isIOS) {
      apiKey = dotenv.env['REVENUECAT_IOS_API_KEY'];
    }

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("RevenueCat API Key is missing. Please check your .env file.");
      return;
    }

    PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
  }

  /// 현재 프리미엄 구독 상태인지 확인
  Future<bool> isPremiumActive() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint("Failed to get CustomerInfo: $e");
      return false;
    }
  }

  /// 구매 내역 복원
  Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo restoredInfo = await Purchases.restorePurchases();
      return restoredInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint("Failed to restore purchases: $e");
      return false;
    }
  }
}

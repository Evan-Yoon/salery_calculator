// [STUDY NOTE]: 실제 인앱 결제 모듈( RevenueCat, StoreKit, Play Billing 등)과 연동될 구독 상품의 ID와 기본 정보를 정의합니다.
class SubscriptionProducts {
  // 스토어에 등록할 / 등록된 월간 구독 상품 ID
  static const String monthlyPremium = "premium_monthly";

  // 스토어에 등록할 / 등록된 연간 구독 상품 ID
  static const String yearlyPremium = "premium_yearly";

  // 화면 표시에 사용할 기본 가격 정보 (결제 모듈 연동 전에는 하드코딩된 값 사용)
  static const String monthlyPriceString = "₩2,000";
  static const String yearlyPriceString = "₩19,900";

  static const double monthlyPrice = 2000.0;
  static const double yearlyPrice = 19900.0;
}

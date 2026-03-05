# In-App Purchase 설정 가이드

본 문서는 앱 출시를 위해 Google Play Console 및 App Store Connect에서 필요한 구독 상품 설정 방법을 안내합니다.

## Google Play Console

1. **내 앱 선택** > **수익 창출** > **정기 결제** 메뉴로 이동합니다.
2. 아래의 상품 ID로 정기 결제 상품을 생성하고 활성화합니다.
   - `premium_monthly`: 월간 구독 (추천 가격: ₩2,000)
   - `premium_yearly`: 연간 구독 (추천 가격: ₩19,900)
3. **무료 체험 설정**:
   - `premium_yearly` 상품에 **3일 무료 체험(Free Trial)** 혜택을 추가합니다.
4. **테스트 계정**:
   - **설정** > **라이선스 테스트** 메뉴에서 테스트할 계정을 등록하여 실제 결제 없이 기능을 테스트할 수 있습니다.

## App Store Connect

1. **내 앱** > **기능** > **앱 내 구입** > **구독** 메뉴로 이동합니다.
2. **구독 그룹**을 생성한 후 아래 상품 ID를 추가합니다.
   - `premium_monthly`: 월간 구독 (추천 가격: ₩2,000)
   - `premium_yearly`: 연간 구독 (추천 가격: ₩19,900)
3. **체험판 혜택 (Introductory Offer)**:
   - `premium_yearly` 상품에 **3일 무료 체험(Free Trial)**을 설정합니다.
4. **샌드박스 테스터**:
   - **사용자 및 액세스** > **샌드박스 테스터**에서 테스트 계정을 생성하여 구매 흐름을 확인합니다.

---
**주의**: 상품 ID(`monthlyId`, `yearlyId`)가 코드(`lib/premium/iap/subscription_ids.dart`)와 일치해야 정상적으로 작동합니다.

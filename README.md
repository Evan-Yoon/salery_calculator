WorkWage
Work Hours & Salary Calculator

WorkWage는 근무 시간 기반 급여 계산 및 근무 관리 앱입니다.
근무 기록을 입력하면 월 급여, 통계, 예상 세후 급여를 자동으로 계산합니다.

이 앱은 특히 간호사, 교대 근무자, 아르바이트 근무자에게 유용하게 설계되었습니다.

주요 기능
근무 기록 관리

사용자는 하루 단위로 근무를 입력할 수 있습니다.

입력 정보

날짜

근무 시작 시간

근무 종료 시간

휴게 시간

근무 타입

앱은 이를 기반으로 자동으로 근무 시간과 급여를 계산합니다.

월 급여 자동 계산

입력된 근무 데이터를 기반으로 다음을 자동 계산합니다.

총 근무 시간

월 총 급여

근무 통계

목표 금액 설정 (Free)

사용자는 이번 달 목표 급여를 설정할 수 있습니다.

예

목표 금액
2,000,000원

앱은 다음 정보를 보여줍니다.

현재 누적 급여

목표 달성률

목표까지 남은 금액

예

현재 62% 달성
목표까지 380,000원 남음
Premium 기능

Premium 구독을 통해 추가 기능을 사용할 수 있습니다.

교대 패턴 자동 생성

예

D → E → N → OFF

패턴을 입력하면 한 달 근무 일정이 자동으로 생성됩니다.

병원 규정 커스터마이즈

다음 규정을 사용자 환경에 맞게 설정할 수 있습니다.

야간 시작 시간

연장 근무 기준

휴게 시간 규칙

공휴일 규정

Excel Export

월 급여 데이터를 Excel 파일로 export할 수 있습니다.

스마트 알림

다음 알림을 받을 수 있습니다.

근무 시작 알림

월말 정산 알림

주휴 충족 알림

목표 급여 달성 알림

각 알림은 설정 화면에서 ON/OFF 할 수 있습니다.

이번 달 예상 급여 (세후)

현재 근무 데이터를 기반으로 이번 달 예상 세후 급여를 계산합니다.

예

예상 세후 급여
1,850,000원

이 값은 현재 근무 기록 기준 추정치입니다.

공휴일 자동 반영

대한민국 공공데이터포털 OpenAPI를 사용하여 공휴일 정보를 가져옵니다.

API

SpcdeInfoService/getRestDeInfo

이를 통해

공휴일

대체 공휴일

정보가 자동 반영됩니다.

기술 스택

Framework

Flutter

State Management

Provider

Local Storage

SharedPreferences

In-App Purchase

in_app_purchase

Notifications

flutter_local_notifications
timezone

Sharing

share_plus
screenshot
pdf
구독 모델

Premium 구독

월 구독 2,000원
연 구독 19,900원

연 구독은 3일 무료 체험이 제공됩니다.

인앱결제

앱은 Google Play와 Apple App Store 구독 결제를 지원합니다.

상품 ID

premium_monthly
premium_yearly

구매 복원 기능을 통해 기기 변경 시에도 Premium 기능을 다시 사용할 수 있습니다.

프로젝트 구조
lib
├─ models
├─ providers
├─ screens
├─ services
├─ utils
├─ premium
│ ├─ iap
│ └─ paywall
향후 계획

다음 기능이 추가될 예정입니다.

근무 캘린더 공유

교대 패턴 자동 생성 개선

데이터 백업 기능 강화

글로벌 버전 출시

설치

Flutter 프로젝트 실행

flutter pub get
flutter run

Release build

flutter build appbundle --release
라이선스

MIT License

개발자

Evan Yoon

# WorkWage — 교대 근무 급여 계산기

> 근무 시간을 기록하면 월 급여·야간·연장·휴일 수당을 자동으로 계산해 주는 Flutter 앱입니다.  
> 간호사, 교대 근무자, 아르바이트생을 위해 설계되었습니다.

---

## 목차

1. [앱 소개](#앱-소개)
2. [주요 화면](#주요-화면)
3. [기능 목록](#기능-목록)
   - [무료 기능](#무료-기능)
   - [Premium 기능](#premium-기능)
4. [급여 계산 방식](#급여-계산-방식)
5. [기술 스택](#기술-스택)
6. [프로젝트 구조](#프로젝트-구조)
7. [개발 환경 설정](#개발-환경-설정)
8. [구독 모델](#구독-모델)
9. [향후 계획](#향후-계획)
10. [라이선스 및 개발자](#라이선스-및-개발자)

---

## 앱 소개

**WorkWage**는 복잡한 급여 계산을 대신해 주는 모바일 앱입니다.

근무 시작·종료 시간과 휴게 시간만 입력하면 근로기준법에 따른 **기본급·연장수당·야간수당·휴일수당**을 자동으로 계산합니다. 세후 급여 추정, 월별 통계 차트, PDF·CSV 내보내기까지 지원합니다.

| 대상 사용자 | 주요 고민 | WorkWage 해결책 |
|---|---|---|
| 병원 간호사 | 3교대 근무 급여 계산이 복잡함 | 교대 패턴 자동 생성 + 야간수당 자동 계산 |
| 아르바이트생 | 시급 × 시간만 알고 주휴수당·연장수당은 모름 | 주 15시간 초과 시 주휴수당 자동 반영 |
| 프리랜서·단기 근무자 | 여러 직장 급여를 따로 관리하기 어려움 | 직장 프리셋으로 여러 사업장 분리 관리 |

---

## 주요 화면

| 화면 | 설명 |
|---|---|
| **홈 (대시보드)** | 이번 달 총 급여·근무 시간·목표 달성률 한눈에 확인 |
| **근무 추가** | 날짜·시작/종료·휴게 시간·근무 타입 입력 |
| **캘린더** | 월별 달력에서 근무일·공휴일·추가 수당 시각적 확인 |
| **근무 내역** | 기록된 근무 목록 조회·삭제 |
| **통계** | 차트 기반 월별·누적 통계, PDF 리포트 생성 |
| **설정** | 시급·세율·근무 프리셋·알림 설정 |
| **패턴 생성기** _(Premium)_ | D→E→N→OFF 같은 교대 패턴으로 한 달 일정 자동 생성 |
| **CSV 내보내기** _(Premium)_ | 엑셀 파일로 급여 데이터 추출 |
| **클라우드 백업** _(Premium)_ | Google Drive에 데이터 백업·복원 |

---

## 기능 목록

### 무료 기능

#### 근무 기록 관리
- 날짜, 시작/종료 시간, 휴게 시간 입력으로 근무 등록
- 근무 타입 지정 (주간/야간/이브닝 등 커스텀 프리셋)
- 추가 수입(팁·성과금 등 비정기 소득) 별도 기록

#### 자동 급여 계산
- 시급 기반 기본급 자동 산출
- 연장·야간·휴일수당 자동 적용 ([계산 방식 상세](#급여-계산-방식) 참고)
- 세금 공제율 선택: 없음 / 3.3% (프리랜서) / 4.6% (4대보험 기준)
- 세후 예상 급여 실시간 표시

#### 목표 급여 관리
- 이번 달 목표 금액 설정
- 현재 누적 급여·달성률·남은 금액 표시

#### 캘린더 뷰
- 대한민국 공휴일 자동 반영 (공공데이터포털 OpenAPI + 하드코딩 폴백)
- 대체 공휴일 포함

#### 통계 & 리포트
- 월별 총 근무 시간·급여 차트 (fl_chart)
- PDF 리포트 생성 (무료는 월 1회 제한)

#### 알림
- 근무 시작 30분 전 알림
- 월말 정산 알림
- 주 15시간 초과 주휴수당 충족 알림
- 목표 급여 달성 알림

---

### Premium 기능

| 기능 | 설명 |
|---|---|
| **교대 패턴 자동 생성** | D→E→N→OFF 등 패턴 입력 시 한 달치 근무 일정 자동 생성 |
| **직장 프리셋 관리** | 여러 사업장의 시급·규정·세율을 저장해 빠르게 전환 |
| **클라우드 백업** | Google Drive에 전체 데이터 백업·기기 간 복원 |
| **CSV / 엑셀 내보내기** | 월 급여 데이터를 스프레드시트로 저장·공유 |
| **PDF 무제한 출력** | 매달 리포트 무제한 생성 |
| **스마트 알림 강화** | 더 세부적인 알림 설정 옵션 제공 |

---

## 급여 계산 방식

WorkWage는 **근로기준법**을 기반으로 수당을 계산합니다.

### 기본 구조

```
총 급여 = 기본급 + 연장수당 + 야간수당 + 휴일수당 + 주휴수당
세후 급여 = 총 급여 × (1 - 공제율)
```

### 연장근로 수당

| 기준 | 조건 | 가산율 |
|---|---|---|
| 일 연장 | 하루 8시간 초과분 | +50% |
| 주 연장 | 주 40시간 초과분 (일 연장과 중복 없이 Max 적용) | +50% |

### 야간 수당

- 야간 시간대: **22:00 ~ 06:00**
- 해당 시간대에 근무한 시간에 **+50%** 가산
- 자정을 넘는 교대 근무도 정확히 분할 계산

### 휴일 수당

| 조건 | 가산율 |
|---|---|
| 휴일 근무 8시간 이하 | +50% (시급의 1.5배) |
| 휴일 근무 8시간 초과분 | +100% (시급의 2.0배) |

### 주휴수당

- 주 **15시간 이상** 근무 시 자동 산정
- 1주 근무 시간 ÷ 40 × 8시간 × 시급 으로 계산

> **참고:** 일 연장과 주 연장이 겹칠 경우 이중 계산 없이 **Max 원칙**을 적용합니다.

---

## 기술 스택

| 분류 | 사용 기술 |
|---|---|
| **프레임워크** | Flutter (Dart 3.0+) |
| **상태 관리** | Provider 6 (ChangeNotifier) |
| **로컬 저장소** | SharedPreferences |
| **캘린더 UI** | table_calendar |
| **차트** | fl_chart |
| **알림** | flutter_local_notifications + timezone |
| **PDF 생성** | pdf + printing |
| **파일 공유** | share_plus |
| **CSV 내보내기** | 자체 구현 (csv_generator) |
| **클라우드 백업** | Google Sign-In + googleapis (Drive API) |
| **인앱 결제** | in_app_purchase (Google Play / App Store) |
| **공휴일 데이터** | 공공데이터포털 OpenAPI + 하드코딩 폴백 (2024–2026) |
| **국제화** | intl |

---

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점, Provider 초기화
├── models/
│   ├── shift_entry.dart               # 근무 기록 데이터 모델
│   ├── bonus_entry.dart               # 추가 수입 모델
│   ├── shift_preset.dart              # 근무 타입 프리셋 모델
│   └── workplace_preset.dart          # 직장 프리셋 모델
├── providers/
│   ├── salary_provider.dart           # 핵심 상태 관리 (급여·근무 데이터)
│   └── notification_settings_provider.dart
├── screens/                           # 화면 (16개)
│   ├── home_page.dart                 # 대시보드
│   ├── add_shift_page.dart            # 근무 추가
│   ├── calendar_page.dart             # 캘린더 뷰
│   ├── shift_history_page.dart        # 근무 내역
│   ├── statistics_page.dart           # 통계 & 리포트
│   ├── settings_page.dart             # 설정
│   ├── paywall_page.dart              # Premium 구독 화면
│   ├── pattern_generator_page.dart    # 교대 패턴 생성 (Premium)
│   ├── workplace_preset_page.dart     # 직장 프리셋 관리 (Premium)
│   ├── csv_export_page.dart           # CSV 내보내기 (Premium)
│   ├── cloud_backup_page.dart         # 클라우드 백업 (Premium)
│   ├── notification_settings_page.dart
│   ├── onboarding_page.dart
│   └── legal_onboarding_page.dart
├── services/
│   ├── notification_service.dart
│   ├── google_drive_service.dart
│   └── holiday_repository.dart        # 공휴일 API 호출·캐시
├── utils/
│   ├── shift_calculator.dart          # 급여 계산 핵심 로직
│   ├── holiday_utils.dart             # 공휴일 판별
│   ├── csv_generator.dart
│   ├── report_generator.dart          # PDF 리포트
│   └── constants.dart                 # 법정 기준 상수 (8시간, 야간 시간 등)
├── widgets/
│   ├── add_shift/                     # 근무 입력 위젯
│   ├── settings/                      # 설정 위젯
│   └── main_bottom_nav.dart           # 하단 내비게이션
└── premium/
    ├── premium_state.dart             # 구독 상태 관리
    ├── premium_features.dart          # 기능 플래그 enum
    └── iap/                           # 인앱 결제 서비스
```

---

## 개발 환경 설정

### 필수 요건

- Flutter SDK 3.0.0 이상
- Dart SDK 3.0.0 이상
- Android Studio / Xcode (빌드 대상에 맞게)

### 실행 방법

```bash
# 의존성 설치
flutter pub get

# 앱 실행 (디버그)
flutter run

# Release 빌드 (Android)
flutter build appbundle --release

# Release 빌드 (iOS)
flutter build ipa --release
```

### 환경 변수 설정

`.env` 파일을 프로젝트 루트에 생성하고 아래 키를 설정하세요:

```
# 공공데이터포털 공휴일 API 키
HOLIDAY_API_KEY=your_api_key_here
```

> **공휴일 API 없이도 동작합니다.** API 키가 없으면 하드코딩된 2024–2026년 한국 공휴일 데이터를 폴백으로 사용합니다.

---

## 구독 모델

| 플랜 | 가격 | 특이사항 |
|---|---|---|
| **월 구독** | ₩2,000 / 월 | — |
| **연 구독** | ₩19,900 / 년 | 3일 무료 체험 제공 |

- Google Play Billing / Apple App Store 결제 지원
- 기기 변경 시 **구매 복원** 기능으로 Premium 기능 재활성화 가능
- Premium 상태는 로컬에 24시간 캐시되어 오프라인에서도 이용 가능

**상품 ID (앱 스토어 등록용):**
```
premium_monthly
premium_yearly
```

---

## 향후 계획

- [ ] 근무 캘린더 공유 기능
- [ ] 교대 패턴 자동 생성 고도화
- [ ] 데이터 백업 기능 강화
- [ ] 글로벌 버전 출시 (다국어 지원)

---

## 라이선스 및 개발자

**라이선스:** MIT License

**개발자:** Evan Yoon

# 공휴일 수당 계산기 (Shift Salary Calculator)

본 애플리케이션은 교대 근무자 및 고정 시간 근무자를 위한 실시간 급여 및 수당 계산 앱입니다. 기능별 수당(종합, 야간, 연장, 휴일)과 공휴일 연동 기능을 갖추고 있습니다.

## 주요 기능 (Features)

- 교대 및 고정 근무 시간 관리
- 주휴수당, 야간, 연장 근무 실시간 계산
- 대한민국 공공데이터포털 공휴일 연동 (OpenAPI)
- 월별 급여 명세표 생성 및 PDF 내보내기

## Versioning & Build Policy (릴리즈 정책)

- **Version (버전명):** `MAJOR.MINOR.PATCH` 아키텍처를 따릅니다.
  - `MAJOR`: 대규모 기능 개편, 법률 기준 대거 수정(연도 변경에 의한 노동법 적용 등) 발생 시 증가
  - `MINOR`: 신규 기능(PDF 내보내기, 세금 알고리즘 추가 등) 추가 및 UI 개편 시 증가
  - `PATCH`: 작은 버그 수정, 폰트 조절, 핫픽스 시 증가
  - 예시: `1.2.0`
- **Build Number (빌드 번호):** CI/CD 환경에서 배포될 때마다 `1` 씩 단조 증가. Play Store 및 App Store 등록 버전 관리를 위해 사용됩니다.
  - 빌드 번호 규칙: (배포순번) 예: `+12`, `+13`

## CI/CD Pipeline

GitHub Actions를 통한 `main` 및 `master` 브랜치 자동화 파이프라인 구성이 적용되어 있습니다.

- Pull Request 시 `flutter analyze` 및 `flutter test`가 강제 실행됩니다.
- 본 저장소를 Fork 하거나 사용할 시 `.github/workflows/flutter_ci.yml` 을 확인하세요.

## Data Privacy (개인정보보호 및 권리)

- 본 앱은 서버 데이터 전송 없이 사용자의 기기(로컬) 내부 SharedPreferences 영역에만 급여/근무 데이터를 보관합니다 (Zero-data policy).
- 제공되는 통계와 실효 급여는 참조용으로, 법적 증빙 효력이 없습니다.

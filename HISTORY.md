Salary Calculator App — Development Overview

1. 프로젝트 개요

본 프로젝트는 근무 시간 기반 급여 계산 및 관리 앱으로, 다음 사용자들을 주요 타겟으로 한다.

주요 타겟 사용자

간호사 (약 60%)

알바 근무자 (약 20%)

교대 근무자 (약 10%)

일반 근무자 (약 10%)

앱의 목적은 다음과 같다.

근무 기록 관리

급여 자동 계산

월별 급여 통계

근무 일정 관리

Premium 기능을 통한 고급 분석 제공

2. 기술 스택
   Framework

Flutter

상태 관리

Provider

로컬 저장

SharedPreferences

인앱결제

in_app_purchase

알림

flutter_local_notifications

timezone

공유 기능 (추가 예정)

share_plus

screenshot

pdf

3. 기능 구조
   무료 기능 (Free)
1. 근무 입력

사용자가 하루 단위로 근무를 입력한다.

입력 정보

날짜

근무 시작 시간

근무 종료 시간

휴게 시간

근무 타입

2. 월 총 근무시간 계산

자동 계산

총 근무 시간

총 급여 (세전)

3. PDF 리포트

무료 사용자는

월 1회 PDF 리포트 생성 가능

Premium 사용자는

무제한 PDF

4. 목표 금액 설정 (무료)

사용자가 월 목표 금액을 설정할 수 있다.

예

이번 달 목표
2,000,000원

표시

현재 누적 급여

목표 달성률

남은 금액

예

현재 62% 달성
목표까지 380,000원 남음

저장 방식

SharedPreferences
key: monthly_target_amount
Premium 기능

Premium은 구독 모델로 제공된다.

가격 정책
월 구독: 2,000원
연 구독: 19,900원
연 구독 3일 무료 체험
Premium 기능 목록

1. 교대 패턴 자동 생성

예

D → E → N → OFF

한 번 설정하면 자동으로 근무 일정 생성.

2. 병원 규정 커스터마이즈

설정 가능

야간 시작 시간

연장 근무 기준

휴게 시간 규칙

공휴일 규정

3. 백업 / 동기화

기기 변경 시 데이터 복구.

4. Excel Export

월 급여 데이터를 Excel로 export.

5. 스마트 알림 (Smart Notification)

알림 종류

근무 시작 알림

월말 정산 알림

주휴 충족 알림

목표 급여 달성 알림

각 알림은 토글 ON/OFF 가능.

6. 이번 달 예상 급여 (세후)

현재 근무 데이터를 기반으로 예상 세후 급여 계산.

주의

실제 급여와 다를 수 있음
추정치

계산 방식

현재 누적 세전 급여
/
월 진행률
=
예상 세전 급여

# 세율 적용

예상 세후 급여 4. 제거된 기능
allowanceTemplates

기존 계획

야간수당
콜수당
교육수당

수당 템플릿 기능

하지만 사용자 체감 가치가 낮다고 판단되어 완전히 제거됨.

5. Smart Notification
   알림 종류
   근무 시작 알림

근무 시작 30분 전

근무 알림
30분 후 근무가 시작됩니다
월말 정산 알림

매월 마지막 날

이번 달 급여 정산을 확인하세요
주휴 충족 알림

조건

weeklyHours ≥ 15
목표 급여 달성 알림

조건

currentSalary ≥ targetSalary
알림 설정

설정 화면에서 토글 가능

근무 시작 알림
월말 정산 알림
주휴 알림
목표 급여 알림

저장

SharedPreferences 6. 공휴일 API

공휴일 정보는 대한민국 공공데이터포털 API 사용.

API

SpcdeInfoService/getRestDeInfo

Repository

RemoteHolidayRepository

기능

공휴일 자동 로드

JSON 파싱

날짜 → 공휴일명 매핑

7. 인앱결제 구조

패키지

in_app_purchase

구독 상품

premium_monthly
premium_yearly
결제 흐름

앱 시작

상품 조회

purchaseStream 구독

구매 처리

Premium 활성화

구매 복원

사용자가

구매 복원

버튼 클릭 시

restorePurchases()

실행

Premium 상태

enum

unknown
active
inactive 8. Paywall 정책

Free 사용자

Premium 기능 클릭 시

PaywallPage 이동

Paywall 메시지

복잡한 근무 스케줄과 급여 관리를
한 번에 해결하세요

Premium 기능 강조

교대 패턴 자동 생성

병원 규정 설정

Excel 리포트

스마트 알림

예상 세후 급여

9. 향후 추가 예정 기능
1. 근무 캘린더 공유

공유 방식

PNG
PDF

공유 대상

카카오톡
메신저
이메일 2. 교대 근무 자동 생성

사용자가

D E N OFF

패턴 입력

→ 자동 생성

10. 출시 준비
    Google Play

필요 작업

subscription 상품 생성

테스트 계정 등록

무료 체험 설정

App Store

필요 작업

auto renewable subscription 생성

sandbox tester 등록

11. 테스트 체크리스트

출시 전 테스트

월 구독 구매

연 구독 구매

무료 체험

구매 복원

구독 취소

Premium 기능 잠금 확인

12. 현재 프로젝트 상태

현재 상태

MVP 개발 완료

진행 단계

Release 준비

다음 작업

1. Smart Notification 안정화
2. 근무 캘린더 공유 기능
3. Play Store / App Store 출시

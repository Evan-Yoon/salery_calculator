import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/shift_entry.dart';

/// [STUDY NOTE]: NotificationService는 앱의 로컬 알림(Local Notification)을
/// 한 곳에서 관리하는 싱글톤 서비스 클래스입니다.
/// 싱글톤 = 앱 전체에서 단 하나의 인스턴스만 존재하도록 보장합니다.
class NotificationService {
  // ─── 싱글톤 ──────────────────────────────────
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  // ─── flutter_local_notifications 핵심 객체 ────
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Android 알림 채널 ─────────────────────────
  static const _androidChannel = AndroidNotificationChannel(
    'work_notifications', // channelId
    'Work Notifications', // channelName
    description: '근무 일정 및 급여 관련 알림',
    importance: Importance.high,
  );

  // ─── 알림 ID 상수 ─────────────────────────────
  static const int _monthlySummaryId = 9000;
  static const int _weeklyHolidayId = 9001;
  static const int _salaryGoalId = 9002;

  // 근무 ID 기반 알림 ID 생성 (해시 → 양수 int 범위 보장)
  int _shiftNotificationId(String shiftId) => shiftId.hashCode.abs() % 100000;

  // ─────────────────────────────────────────────
  // 초기화
  // ─────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    // 1. timezone 초기화
    tz.initializeTimeZones();
    // 한국 시간대 고정
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // 2. 플랫폼별 초기화 설정
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(initSettings);

    // 3. Android 채널 생성
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 4. Android 알림 권한 요청 (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 5. Android 정확한 알람 권한 요청
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
    debugPrint('[NotificationService] initialized');
  }

  // ─────────────────────────────────────────────
  // 공통 알림 디테일
  // ─────────────────────────────────────────────
  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  // ─────────────────────────────────────────────
  // 6. 근무 시작 30분 전 알림 예약
  // ─────────────────────────────────────────────
  Future<void> scheduleShiftReminder(ShiftEntry shift) async {
    if (!_initialized) await init();
    final notifTime = shift.startTime.subtract(const Duration(minutes: 30));

    // 이미 지난 시간이면 등록하지 않음
    if (notifTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(notifTime, tz.local);

    await _plugin.zonedSchedule(
      _shiftNotificationId(shift.id),
      '근무 알림',
      '30분 후 근무가 시작됩니다.',
      scheduledDate,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
    debugPrint('[NotificationService] shift reminder scheduled: ${shift.id}');
  }

  // 특정 근무 알림 취소
  Future<void> cancelShiftReminder(String shiftId) async {
    if (!_initialized) return;
    await _plugin.cancel(_shiftNotificationId(shiftId));
    debugPrint('[NotificationService] shift reminder cancelled: $shiftId');
  }

  // ─────────────────────────────────────────────
  // 7. 월말 정산 알림 (매달 말일 20:00)
  // ─────────────────────────────────────────────
  Future<void> scheduleMonthlySummary() async {
    if (!_initialized) await init();

    // 이번 달 마지막 날 계산
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0, 20, 0); // 말일 20:00

    final scheduledDate = tz.TZDateTime.from(lastDay, tz.local);
    // 이미 지난 경우 다음 달 말일로
    final target = scheduledDate.isBefore(tz.TZDateTime.now(tz.local))
        ? tz.TZDateTime.from(
            DateTime(now.year, now.month + 2, 0, 20, 0), tz.local)
        : scheduledDate;

    await _plugin.zonedSchedule(
      _monthlySummaryId,
      '월말 정산 알림',
      '이번 달 급여 정산을 확인하세요.',
      target,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
    debugPrint('[NotificationService] monthly summary scheduled');
  }

  Future<void> cancelMonthlySummary() async {
    if (!_initialized) return;
    await _plugin.cancel(_monthlySummaryId);
  }

  // ─────────────────────────────────────────────
  // 8. 주휴 충족 즉시 알림
  // ─────────────────────────────────────────────
  Future<void> showWeeklyHolidayNotification() async {
    if (!_initialized) await init();
    await _plugin.show(
      _weeklyHolidayId,
      '주휴수당 알림',
      '주휴수당 조건(주 15시간)을 충족했습니다! 🎉',
      _details,
    );
    debugPrint('[NotificationService] weekly holiday notification shown');
  }

  // ─────────────────────────────────────────────
  // 9. 목표 급여 달성 즉시 알림
  // ─────────────────────────────────────────────
  Future<void> showSalaryGoalNotification() async {
    if (!_initialized) await init();
    await _plugin.show(
      _salaryGoalId,
      '목표 급여 달성! 🏆',
      '이번 달 목표 급여를 달성했습니다.',
      _details,
    );
    debugPrint('[NotificationService] salary goal notification shown');
  }

  // ─────────────────────────────────────────────
  // 전체 취소
  // ─────────────────────────────────────────────
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    debugPrint('[NotificationService] all notifications cancelled');
  }
}

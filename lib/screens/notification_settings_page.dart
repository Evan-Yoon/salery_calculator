import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_settings_provider.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('스마트 알림', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<NotificationSettingsProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(context),
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: '근무 알림',
                children: [
                  _buildNotifTile(
                    context,
                    icon: Icons.work_outline,
                    title: '근무 시작 알림',
                    subtitle: '근무 시작 30분 전에 알림을 보냅니다.',
                    value: provider.shiftReminderEnabled,
                    onChanged: (_) => provider.toggleShiftReminder(),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildNotifTile(
                    context,
                    icon: Icons.event_available,
                    title: '주휴 충족 알림',
                    subtitle: '주 15시간 이상 근무 시 알림을 보냅니다.',
                    value: provider.weeklyHolidayEnabled,
                    onChanged: (_) => provider.toggleWeeklyHoliday(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: '급여 알림',
                children: [
                  _buildNotifTile(
                    context,
                    icon: Icons.calendar_month,
                    title: '월말 정산 알림',
                    subtitle: '매달 마지막 날 오후 8시에 알림을 보냅니다.',
                    value: provider.monthlySummaryEnabled,
                    onChanged: (_) => provider.toggleMonthlySummary(),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildNotifTile(
                    context,
                    icon: Icons.emoji_events_outlined,
                    title: '목표 급여 달성 알림',
                    subtitle: provider.salaryGoalAmount > 0
                        ? '목표: ₩${NumberFormat("#,###").format(provider.salaryGoalAmount.toInt())} 달성 시 알림'
                        : '목표 금액을 설정하면 달성 시 알림을 보냅니다.',
                    value: provider.salaryGoalEnabled,
                    onChanged: (_) => provider.toggleSalaryGoal(),
                    trailing2: IconButton(
                      icon:
                          const Icon(Icons.edit, size: 18, color: Colors.grey),
                      onPressed: () => _showGoalAmountDialog(context, provider),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildNoticeCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '원하는 알림을 켜두면 근무·급여 관련 정보를 놓치지 않을 수 있습니다.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNotifTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing2,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing2 != null) trailing2,
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary;
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '기기 설정에서 앱 알림이 허용되어 있어야 알림을 받을 수 있습니다.\n'
              '알림 권한이 없을 경우 기기 설정 > 앱 > 알림에서 허용해 주세요.',
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalAmountDialog(
      BuildContext context, NotificationSettingsProvider provider) {
    final fmt = NumberFormat('#,###');
    final ctrl = TextEditingController(
      text: provider.salaryGoalAmount > 0
          ? fmt.format(provider.salaryGoalAmount.toInt())
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('목표 급여 설정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '예: 2,000,000',
            prefixText: '₩ ',
          ),
          onChanged: (text) {
            final raw = text.replaceAll(RegExp(r'[^0-9]'), '');
            if (raw.isEmpty) {
              ctrl.value = const TextEditingValue(text: '');
              return;
            }
            final formatted = fmt.format(int.parse(raw));
            ctrl.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              final amount = double.tryParse(raw) ?? 0;
              if (amount > 0) {
                provider.setSalaryGoalAmount(amount);
                if (!provider.salaryGoalEnabled) {
                  provider.toggleSalaryGoal();
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

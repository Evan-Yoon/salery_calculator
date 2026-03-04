import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// [STUDY NOTE]: 날짜 및 시작/종료 시간을 선택하는 UI 카드 요소입니다.
class DateTimeCard extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onPickDate;
  final Function(bool isStart) onPickTime;

  const DateTimeCard({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // 날짜 선택기
          InkWell(
            onTap: onPickDate,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('날짜 선택', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      Text(
                        DateFormat('yyyy.MM.dd (E)', 'ko_KR')
                            .format(selectedDate),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_month,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // 시간 선택기
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onPickTime(true),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('시작 시간',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          startTime.format(context),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white10),
              Expanded(
                child: InkWell(
                  onTap: () => onPickTime(false),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('종료 시간',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          endTime.format(context),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

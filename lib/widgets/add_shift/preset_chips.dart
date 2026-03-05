import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salary_provider.dart';

// [STUDY NOTE]: 근무 추가 화면 상단에 표시되는 '빠른 프리셋 칩' UI를 분리한 위젯입니다.
class PresetChips extends StatelessWidget {
  final Function(TimeOfDay start, TimeOfDay end, int breakMins,
      double multiplier, String iconType) onPresetSelected;

  const PresetChips({
    super.key,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final presets = provider.shiftPresets;

    // [STUDY NOTE]: 고정 근무자이거나 프리셋이 없으면 아무것도 보여주지 않습니다.
    if (!provider.isShiftWorker || presets.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        return ActionChip(
          label: Text(preset.name,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          side: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          onPressed: () {
            final partsStart = preset.startTime.split(':');
            final partsEnd = preset.endTime.split(':');

            onPresetSelected(
              TimeOfDay(
                  hour: int.parse(partsStart[0]),
                  minute: int.parse(partsStart[1])),
              TimeOfDay(
                  hour: int.parse(partsEnd[0]), minute: int.parse(partsEnd[1])),
              preset.breakTimeMinutes,
              preset.multiplier,
              preset.iconType,
            );
          },
        );
      }).toList(),
    );
  }
}

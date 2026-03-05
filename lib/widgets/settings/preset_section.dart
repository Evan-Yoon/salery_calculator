import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salary_provider.dart';
import '../../models/shift_preset.dart';

class PresetSection extends StatelessWidget {
  const PresetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final presets = provider.shiftPresets;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: presets.map((preset) {
          final isLast = preset == presets.last;
          return Column(
            children: [
              ListTile(
                title: Text(preset.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${preset.startTime.format(context)} ~ ${preset.endTime.format(context)} (휴게 ${preset.breakTimeMinutes}분)\n수당 배율: ${preset.payMultiplier.toStringAsFixed(2)}배',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey, height: 1.5),
                ),
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onTap: () => _showEditPresetDialog(context, preset),
              ),
              if (!isLast) const Divider(height: 1, color: Colors.white10),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showEditPresetDialog(BuildContext context, ShiftPreset preset) {
    TimeOfDay tempStartTime = preset.startTime;
    TimeOfDay tempEndTime = preset.endTime;
    int tempBreakTime = preset.breakTimeMinutes;
    double tempMultiplier = preset.payMultiplier;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${preset.name} 설정 변경',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // 시간 선택 부분
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                                context: ctx, initialTime: tempStartTime);
                            if (picked != null) {
                              setModalState(() => tempStartTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                                color: Colors.white10,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                            child: Column(
                              children: [
                                const Text('시작 시간',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(tempStartTime.format(ctx),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                                context: ctx, initialTime: tempEndTime);
                            if (picked != null) {
                              setModalState(() => tempEndTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                                color: Colors.white10,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                            child: Column(
                              children: [
                                const Text('종료 시간',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(tempEndTime.format(ctx),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 휴게시간 선택 부분
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('휴게 시간', style: TextStyle(fontSize: 16)),
                      Container(
                        decoration: const BoxDecoration(
                            color: Colors.white10,
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () => setModalState(() {
                                if (tempBreakTime >= 30) tempBreakTime -= 30;
                              }),
                            ),
                            Text('$tempBreakTime분',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => setModalState(() {
                                tempBreakTime += 30;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 수당 배율 선택 부분
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('수당 배율', style: TextStyle(fontSize: 16)),
                          Text('1.0배 = 기본 시급',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(
                        decoration: const BoxDecoration(
                            color: Colors.white10,
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () => setModalState(() {
                                if (tempMultiplier > 1.0) {
                                  tempMultiplier -= 0.05;
                                }
                              }),
                            ),
                            Text('${tempMultiplier.toStringAsFixed(2)}배',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => setModalState(() {
                                tempMultiplier += 0.05;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final updatedPreset = ShiftPreset(
                        id: preset.id,
                        name: preset.name,
                        startTime: tempStartTime,
                        endTime: tempEndTime,
                        breakTimeMinutes: tempBreakTime,
                        payMultiplier: tempMultiplier,
                      );
                      Provider.of<SalaryProvider>(context, listen: false)
                          .updateShiftPreset(updatedPreset);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('저장하기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

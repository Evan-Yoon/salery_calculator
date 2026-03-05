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

    return Column(
      children: [
        Container(
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
                    leading: Icon(_getIconData(preset.iconType),
                        color: Theme.of(context).primaryColor),
                    title: Text(preset.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${preset.startTime} ~ ${preset.endTime} (휴게 ${preset.breakTimeMinutes}분)\n수당 배율: ${preset.multiplier.toStringAsFixed(2)}배',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey, height: 1.5),
                    ),
                    trailing:
                        const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onTap: () =>
                        _showEditPresetDialog(context, provider, preset),
                  ),
                  if (!isLast) const Divider(height: 1, color: Colors.white10),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showAddPresetDialog(context, provider),
          icon: const Icon(Icons.add),
          label: const Text('근무 프리셋 추가하기'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'night':
        return Icons.nightlight_round;
      case 'star':
        return Icons.star_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'home':
        return Icons.home_rounded;
      default:
        return Icons.circle;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  void _showEditPresetDialog(
      BuildContext context, SalaryProvider provider, ShiftPreset preset) {
    final nameController = TextEditingController(text: preset.name);
    TimeOfDay tempStartTime = _parseTime(preset.startTime);
    TimeOfDay tempEndTime = _parseTime(preset.endTime);
    int tempBreakTime = preset.breakTimeMinutes;
    double tempMultiplier = preset.multiplier;
    String tempIconType = preset.iconType;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${preset.name} 설정 변경',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '프리셋 이름',
                        hintText: '예: 데이, 야간, 파트타임',
                        counterText: "",
                      ),
                      maxLength: 10,
                    ),
                    const SizedBox(height: 24),
                    const Text('아이콘 선택',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        'sunny',
                        'cloud',
                        'night',
                        'star',
                        'heart',
                        'work',
                        'coffee',
                        'home'
                      ].map((iconType) {
                        final isSelected = tempIconType == iconType;
                        return ChoiceChip(
                          label: Icon(_getIconData(iconType),
                              size: 20,
                              color:
                                  isSelected ? Colors.white : Colors.white54),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => tempIconType = iconType);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
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
                        const SizedBox(width: 12),
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberInput('휴게 시간(분)', tempBreakTime,
                              (val) {
                            setModalState(() => tempBreakTime = val.toInt());
                          }, step: 10),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              _buildNumberInput('수당 배율', tempMultiplier, (val) {
                            setModalState(() => tempMultiplier = val);
                          }, step: 0.05, isDecimal: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        if (provider.shiftPresets.length > 1)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                provider.removePreset(preset.id);
                                Navigator.pop(ctx);
                              },
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('삭제'),
                            ),
                          ),
                        if (provider.shiftPresets.length > 1)
                          const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final updated = ShiftPreset(
                                id: preset.id,
                                name: nameController.text.isEmpty
                                    ? '새 프리셋'
                                    : nameController.text,
                                startTime: _formatTime(tempStartTime),
                                endTime: _formatTime(tempEndTime),
                                breakTimeMinutes: tempBreakTime,
                                multiplier: tempMultiplier,
                                iconType: tempIconType,
                              );
                              provider.updatePreset(updated);
                              Navigator.pop(ctx);
                            },
                            child: const Text('저장하기'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPresetDialog(BuildContext context, SalaryProvider provider) {
    final nameController = TextEditingController();
    TimeOfDay tempStartTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay tempEndTime = const TimeOfDay(hour: 18, minute: 0);
    int tempBreakTime = 60;
    double tempMultiplier = 1.0;
    String tempIconType = 'sunny';

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('새 근무 프리셋 추가',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '프리셋 이름',
                        hintText: '예: 데이, 야간, 파트타임',
                        counterText: "",
                      ),
                      maxLength: 10,
                    ),
                    const SizedBox(height: 24),
                    const Text('아이콘 선택',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        'sunny',
                        'cloud',
                        'night',
                        'star',
                        'heart',
                        'work',
                        'coffee',
                        'home'
                      ].map((iconType) {
                        final isSelected = tempIconType == iconType;
                        return ChoiceChip(
                          label: Icon(_getIconData(iconType),
                              size: 20,
                              color:
                                  isSelected ? Colors.white : Colors.white54),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => tempIconType = iconType);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
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
                        const SizedBox(width: 12),
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberInput('휴게 시간(분)', tempBreakTime,
                              (val) {
                            setModalState(() => tempBreakTime = val.toInt());
                          }, step: 10),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              _buildNumberInput('수당 배율', tempMultiplier, (val) {
                            setModalState(() => tempMultiplier = val);
                          }, step: 0.05, isDecimal: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        final newPreset = ShiftPreset(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.isEmpty
                              ? '새 프리셋'
                              : nameController.text,
                          startTime: _formatTime(tempStartTime),
                          endTime: _formatTime(tempEndTime),
                          breakTimeMinutes: tempBreakTime,
                          multiplier: tempMultiplier,
                          iconType: tempIconType,
                        );
                        provider.addPreset(newPreset);
                        Navigator.pop(ctx);
                      },
                      child: const Text('추가하기'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNumberInput(
      String label, dynamic value, Function(double) onChanged,
      {double step = 1.0, bool isDecimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildCircleButton(Icons.remove, () {
              onChanged((value - step).clamp(0.0, 999.0));
            }),
            Expanded(
              child: Text(
                isDecimal ? value.toStringAsFixed(2) : value.toString(),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildCircleButton(Icons.add, () {
              onChanged((value + step).clamp(0.0, 999.0));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

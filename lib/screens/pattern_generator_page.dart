import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/shift_preset.dart';

class PatternGeneratorPage extends StatefulWidget {
  const PatternGeneratorPage({super.key});

  @override
  State<PatternGeneratorPage> createState() => _PatternGeneratorPageState();
}

class _PatternGeneratorPageState extends State<PatternGeneratorPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _startFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final List<ShiftPreset?> _pattern = [];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final presets = provider.shiftPresets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('패턴 자동 생성',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildMonthPicker(),
          const SizedBox(height: 16),
          _buildStartDatePicker(),
          const SizedBox(height: 24),
          _buildPatternEditor(presets),
          const SizedBox(height: 32),
          _buildActionButtons(provider),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '교대 근무 규칙을 설정하면 한 달 치 기록을 한 번에 생성합니다. (예: 데이-이브-나이트-휴무)',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    return ListTile(
      title:
          const Text('적용할 달 선택', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat('yyyy년 MM월').format(_selectedMonth)),
      trailing: const Icon(Icons.calendar_month),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      tileColor: Theme.of(context).cardTheme.color,
      onTap: () async {
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: _selectedMonth,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (selected != null) {
          setState(() {
            _selectedMonth = DateTime(selected.year, selected.month);
            // 시작일이 해당 달 범위를 벗어나지 않게 조정
            if (_startFrom.year != _selectedMonth.year ||
                _startFrom.month != _selectedMonth.month) {
              _startFrom =
                  DateTime(_selectedMonth.year, _selectedMonth.month, 1);
            }
          });
        }
      },
    );
  }

  Widget _buildStartDatePicker() {
    return ListTile(
      title: const Text('시작 날짜', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat('yyyy년 MM월 dd일').format(_startFrom)),
      trailing: const Icon(Icons.event),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      tileColor: Theme.of(context).cardTheme.color,
      onTap: () async {
        final lastDay =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        final selected = await showDatePicker(
          context: context,
          initialDate: _startFrom,
          firstDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
          lastDate: lastDay,
        );
        if (selected != null) {
          setState(() {
            _startFrom = selected;
          });
        }
      },
    );
  }

  Widget _buildPatternEditor(List<ShiftPreset> presets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('근무 순서 (패턴)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('아래 버튼을 눌러 패턴을 구성하세요. (길게 눌러서 삭제)',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._pattern.asMap().entries.map((entry) {
              final idx = entry.key;
              final preset = entry.value;
              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    _pattern.removeAt(idx);
                  });
                },
                child: Chip(
                  label: Text(preset?.name ?? '휴무'),
                  backgroundColor: preset == null
                      ? Colors.grey.withValues(alpha: 0.2)
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                  side: BorderSide(
                      color: preset == null
                          ? Colors.grey.withValues(alpha: 0.5)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5)),
                ),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('추가'),
              onPressed: () => _showPresetSelector(presets),
            ),
          ],
        ),
        if (_pattern.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('패턴이 비어있습니다.',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
          ),
      ],
    );
  }

  void _showPresetSelector(List<ShiftPreset> presets) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('근무 선택',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              ListTile(
                leading: const Icon(Icons.beach_access, color: Colors.grey),
                title: const Text('휴무 (Off)'),
                onTap: () {
                  setState(() => _pattern.add(null));
                  Navigator.pop(context);
                },
              ),
              ...presets.map((p) => ListTile(
                    leading: Icon(_getIconData(p.iconType),
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(p.name),
                    subtitle: Text('${p.startTime} ~ ${p.endTime}'),
                    onTap: () {
                      setState(() => _pattern.add(p));
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconData(String? type) {
    switch (type) {
      case 'sunny':
      case 'day':
        return Icons.wb_sunny;
      case 'cloud':
        return Icons.wb_cloudy;
      case 'night':
        return Icons.nightlight_round;
      case 'star':
        return Icons.star;
      case 'heart':
        return Icons.favorite;
      default:
        return Icons.work;
    }
  }

  Widget _buildActionButtons(SalaryProvider provider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
                _pattern.isEmpty ? null : () => _handleGenerate(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('패턴 일괄 생성하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _handleClear(provider),
          child: const Text('해당 달 기록 모두 지우기',
              style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Future<void> _handleGenerate(SalaryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('패턴 생성'),
        content: Text(
            '${DateFormat('yyyy년 MM월').format(_selectedMonth)}에 ${_pattern.length}개 주기의 패턴을 적용하시겠습니까?\n(기존에 동일한 날짜에 등록된 기록은 유지됩니다)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('생성')),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.generatePatternShifts(
        month: _selectedMonth,
        pattern: _pattern,
        startFrom: _startFrom,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('패턴 생성이 완료되었습니다.')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleClear(SalaryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text(
            '${DateFormat('yyyy년 MM월').format(_selectedMonth)}의 모든 근무 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제')),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearShiftsForMonth(_selectedMonth);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('해당 달의 기록이 삭제되었습니다.')));
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/workplace_preset.dart';

class WorkplacePresetPage extends StatelessWidget {
  const WorkplacePresetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('N잡 관리', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<SalaryProvider>(
        builder: (context, provider, _) {
          final presets = provider.workplacePresets;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(context),
              const SizedBox(height: 20),
              if (presets.isEmpty)
                _buildEmptyState()
              else ...[
                ...presets.map((p) => _buildPresetCard(context, p, provider)),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditSheet(context, null),
        icon: const Icon(Icons.add),
        label: const Text('잡 추가'),
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
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '본업, 알바 등 각 직장의 급여 규정을 저장하고 탭 하나로 전환하세요.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('저장된 직장이 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('+ 버튼을 눌러 첫 번째 직장을 추가하세요.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(
      BuildContext context, WorkplacePreset preset, SalaryProvider provider) {
    final isActive = provider.activeWorkplacePresetId == preset.id;
    final fmt = NumberFormat('#,###');
    final taxLabel = preset.taxRate == 0
        ? '없음'
        : '${(preset.taxRate * 100).toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive ? Theme.of(context).colorScheme.primary : Colors.white10,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.business_center,
                  color: Theme.of(context).colorScheme.primary),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(preset.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (isActive) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('적용 중',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            subtitle: Text('시급 ₩${fmt.format(preset.hourlyWage.toInt())}',
                style: const TextStyle(fontSize: 13)),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showEditSheet(context, preset);
                if (value == 'delete') {
                  _confirmDelete(context, preset, provider);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('삭제', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(
                    context,
                    '5인 ${preset.isFiveOrMoreEmployees ? "이상" : "미만"}',
                    Icons.groups),
                _chip(context, '세율 $taxLabel', Icons.receipt_long),
                _chip(
                    context,
                    '야간 ×${(1 + preset.nightShiftMultiplier).toStringAsFixed(1)}',
                    Icons.nightlight),
                _chip(
                    context,
                    '휴일 ×${(1 + preset.holidayMultiplier).toStringAsFixed(1)}',
                    Icons.celebration),
                if (preset.assumeFullAttendance)
                  _chip(context, '주휴수당', Icons.check_circle_outline),
              ],
            ),
          ),
          if (!isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    provider.applyWorkplacePreset(preset.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("'${preset.name}' 설정이 적용되었습니다.")),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('이 근무지로 전환',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WorkplacePreset preset,
      SalaryProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('프리셋 삭제'),
        content: Text("'${preset.name}' 프리셋을 삭제하시겠습니까?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) provider.removeWorkplacePreset(preset.id);
  }

  void _showEditSheet(BuildContext context, WorkplacePreset? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PresetEditSheet(existing: existing),
    );
  }
}

class _PresetEditSheet extends StatefulWidget {
  final WorkplacePreset? existing;
  const _PresetEditSheet({this.existing});

  @override
  State<_PresetEditSheet> createState() => _PresetEditSheetState();
}

class _PresetEditSheetState extends State<_PresetEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _wageCtrl;
  late bool _isFive;
  late double _taxRate;
  late bool _fullAttendance;
  late double _nightMult;
  late double _holidayMult;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _wageCtrl = TextEditingController(
        text: p != null ? p.hourlyWage.toInt().toString() : '');
    _isFive = p?.isFiveOrMoreEmployees ?? false;
    _taxRate = p?.taxRate ?? 0.0;
    _fullAttendance = p?.assumeFullAttendance ?? false;
    _nightMult = p?.nightShiftMultiplier ?? 0.5;
    _holidayMult = p?.holidayMultiplier ?? 0.5;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? '직장 수정' : '직장 추가',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _label('직장 이름'),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecor('예: 본업, 편의점 알바, 과외'),
            ),
            const SizedBox(height: 16),
            _label('시급 (원)'),
            TextField(
              controller: _wageCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecor('예: 12000'),
            ),
            const SizedBox(height: 16),
            _label('사업장 규모'),
            _toggleRow(
                '5인 이상', '5인 미만', _isFive, (v) => setState(() => _isFive = v)),
            const SizedBox(height: 16),
            _label('세율'),
            Wrap(
              spacing: 8,
              children: [
                _taxChip('없음', 0.0),
                _taxChip('프리랜서 3.3%', 0.033),
                _taxChip('4대보험 9.4%', 0.094),
              ],
            ),
            const SizedBox(height: 16),
            _label('야간 수당 배율'),
            _sliderRow(
                _nightMult, 0.0, 1.0, (v) => setState(() => _nightMult = v),
                label: '×${(1 + _nightMult).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _label('공휴일 수당 배율'),
            _sliderRow(
                _holidayMult, 0.0, 1.0, (v) => setState(() => _holidayMult = v),
                label: '×${(1 + _holidayMult).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _fullAttendance,
              onChanged: (v) => setState(() => _fullAttendance = v),
              title: const Text('주휴수당 개근 가정'),
              subtitle: const Text('주 15시간 이상 개근 시 주휴수당 포함 계산'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEdit ? '수정 완료' : '저장',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );

  Widget _toggleRow(
      String labelA, String labelB, bool value, void Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: _toggleOption(labelA, selected: value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: _toggleOption(labelB, selected: !value),
          ),
        ),
      ],
    );
  }

  Widget _toggleOption(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.grey)),
    );
  }

  Widget _taxChip(String label, double value) {
    final selected = _taxRate == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _taxRate = value),
      selectedColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
    );
  }

  Widget _sliderRow(
      double value, double min, double max, ValueChanged<double> onChanged,
      {required String label}) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final wage = double.tryParse(_wageCtrl.text.trim()) ?? 0;
    if (name.isEmpty || wage <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 시급을 올바르게 입력해주세요.')),
      );
      return;
    }

    final provider = Provider.of<SalaryProvider>(context, listen: false);
    if (widget.existing != null) {
      provider.updateWorkplacePreset(widget.existing!.copyWith(
        name: name,
        hourlyWage: wage,
        isFiveOrMoreEmployees: _isFive,
        taxRate: _taxRate,
        assumeFullAttendance: _fullAttendance,
        nightShiftMultiplier: _nightMult,
        holidayMultiplier: _holidayMult,
      ));
    } else {
      provider.addWorkplacePreset(WorkplacePreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        hourlyWage: wage,
        isFiveOrMoreEmployees: _isFive,
        taxRate: _taxRate,
        assumeFullAttendance: _fullAttendance,
        nightShiftMultiplier: _nightMult,
        holidayMultiplier: _holidayMult,
      ));
    }
    Navigator.pop(context);
  }
}

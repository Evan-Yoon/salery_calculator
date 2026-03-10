import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/allowance_template.dart';

class AllowanceTemplateFormPage extends StatefulWidget {
  final AllowanceTemplate? existing;
  const AllowanceTemplateFormPage({super.key, this.existing});

  @override
  State<AllowanceTemplateFormPage> createState() =>
      _AllowanceTemplateFormPageState();
}

class _AllowanceTemplateFormPageState extends State<AllowanceTemplateFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late bool _isPerHour;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    // 천 단위 콤마 포맷
    final fmt = NumberFormat('#,###');
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _amountCtrl = TextEditingController(
        text: t != null ? fmt.format(t.amount.toInt()) : '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _isPerHour = t?.isPerHour ?? false;
    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '템플릿 수정' : '템플릿 추가',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('템플릿 이름 *'),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecor('예: 야간수당, 콜수당, 특근수당'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            _label('금액 (원) *'),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecor('예: 5000'),
              onChanged: _formatAmount,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            _label('수당 유형'),
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _label('설명 (선택)'),
            TextField(
              controller: _noteCtrl,
              decoration: _inputDecor('예: 22:00~06:00 야간 근무 시 시간당 추가'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('활성화',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('비활성화 시 근무 입력에서 표시되지 않습니다.',
                  style: TextStyle(fontSize: 12)),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 36),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );

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

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _typeOption('고정 금액', false)),
        const SizedBox(width: 8),
        Expanded(child: _typeOption('시간당 수당', true)),
      ],
    );
  }

  Widget _typeOption(String label, bool value) {
    final selected = _isPerHour == value;
    return GestureDetector(
      onTap: () => setState(() => _isPerHour = value),
      child: Container(
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
      ),
    );
  }

  void _formatAmount(String text) {
    final raw = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _amountCtrl.value = const TextEditingValue(text: '');
      return;
    }
    final number = int.tryParse(raw) ?? 0;
    final formatted = NumberFormat('#,###').format(number);
    _amountCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final amountRaw = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountRaw) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('템플릿 이름을 입력해주세요.')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액은 0보다 크게 입력해주세요.')),
      );
      return;
    }

    final provider = Provider.of<SalaryProvider>(context, listen: false);
    final now = DateTime.now();

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: name,
        amount: amount,
        isFixedAmount: !_isPerHour,
        isPerHour: _isPerHour,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        isActive: _isActive,
        updatedAt: now,
      );
      provider.updateAllowanceTemplate(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('템플릿이 수정되었습니다.')),
        );
      }
    } else {
      final newTemplate = AllowanceTemplate(
        id: now.millisecondsSinceEpoch.toString(),
        name: name,
        amount: amount,
        isFixedAmount: !_isPerHour,
        isPerHour: _isPerHour,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
      );
      provider.addAllowanceTemplate(newTemplate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('템플릿이 추가되었습니다.')),
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }
}

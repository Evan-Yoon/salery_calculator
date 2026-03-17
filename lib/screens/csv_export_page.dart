import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/salary_provider.dart';
import '../utils/csv_generator.dart';

class CsvExportPage extends StatefulWidget {
  const CsvExportPage({super.key});

  @override
  State<CsvExportPage> createState() => _CsvExportPageState();
}

class _CsvExportPageState extends State<CsvExportPage> {
  // null = 전체 기간
  DateTime? _selectedMonth;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('엑셀 리포트 (CSV)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('기간 선택'),
          _buildPeriodSelector(now),
          const SizedBox(height: 32),
          _buildPreviewCard(context),
          const SizedBox(height: 32),
          _buildExportButton(context),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '📊 내보낸 .csv 파일은 엑셀, 구글 시트, 숫자(Numbers) 등에서 바로 열 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.table_chart, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '근무 기록과 비정기 수입을 스프레드시트(.csv) 파일로 내보냅니다.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildPeriodSelector(DateTime now) {
    final months = <DateTime?>[null];
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month - i));
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: months.asMap().entries.map((entry) {
          final m = entry.value;
          final isSelected = m == null
              ? _selectedMonth == null
              : (_selectedMonth?.year == m.year &&
                  _selectedMonth?.month == m.month);
          final label = m == null ? '전체 기간' : DateFormat('yyyy년 MM월').format(m);

          return Column(
            children: [
              ListTile(
                title: Text(label,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
                    : const Icon(Icons.radio_button_unchecked,
                        color: Colors.grey),
                onTap: () => setState(() => _selectedMonth = m),
              ),
              if (entry.key < months.length - 1)
                const Divider(height: 1, color: Colors.white10),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    var shifts = provider.shifts;
    var bonuses = provider.bonuses;

    if (_selectedMonth != null) {
      shifts = shifts
          .where((s) =>
              s.startTime.year == _selectedMonth!.year &&
              s.startTime.month == _selectedMonth!.month)
          .toList();
      bonuses = bonuses
          .where((b) =>
              b.date.year == _selectedMonth!.year &&
              b.date.month == _selectedMonth!.month)
          .toList();
    }

    final shiftTotal = shifts.fold(0.0, (sum, s) => sum + s.totalPay);
    final bonusTotal = bonuses.fold(0.0, (sum, b) => sum + b.amount);
    final net = (shiftTotal + bonusTotal) * (1 - provider.taxRate);
    final fmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('내보낼 데이터 미리보기',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _previewRow('근무 기록', '${shifts.length}건'),
          const Divider(height: 20, color: Colors.white10),
          _previewRow('비정기 수입', '${bonuses.length}건'),
          const Divider(height: 20, color: Colors.white10),
          _previewRow('실수령 추정액', '₩${fmt.format(net.toInt())}',
              highlight: true),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Theme.of(context).colorScheme.primary : null,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(BuildContext context) {
    final periodLabel = _selectedMonth == null
        ? '전체 기간'
        : DateFormat('yyyy년 MM월').format(_selectedMonth!);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _export,
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download, color: Colors.white),
        label: Text(
          _isExporting ? '내보내는 중...' : '$periodLabel CSV 내보내기',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final provider = Provider.of<SalaryProvider>(context, listen: false);
      final csvString =
          CsvGenerator.generateShiftsCsv(provider, _selectedMonth);

      // UTF-8 BOM 추가 (엑셀에서 한글 깨짐 방지)
      const bom = '\uFEFF';
      final csvWithBom = bom + csvString;

      final tempDir = await getTemporaryDirectory();
      final periodStr = _selectedMonth == null
          ? 'all'
          : DateFormat('yyyyMM').format(_selectedMonth!);
      final file = File('${tempDir.path}/salary_report_$periodStr.csv');
      await file.writeAsBytes(utf8.encode(csvWithBom));

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: '급여 기록 리포트 (.csv)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

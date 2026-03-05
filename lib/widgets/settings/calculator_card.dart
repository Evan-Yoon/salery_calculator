import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salary_provider.dart';

class CalculatorCard extends StatefulWidget {
  const CalculatorCard({super.key});

  @override
  State<CalculatorCard> createState() => _CalculatorCardState();
}

class _CalculatorCardState extends State<CalculatorCard> {
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);
    final double baseWage = provider.hourlyWage;
    final bool isFiveOrMoreEmployees = provider.isFiveOrMoreEmployees;
    final bool assumeFullAttendance = provider.assumeFullAttendance;
    final double taxRate = provider.taxRate;

    final double effectiveHourlyWage =
        assumeFullAttendance ? baseWage * 1.2 : baseWage;
    final double appliedMonthlyHours = assumeFullAttendance ? 209.0 : 174.0;
    final double monthlyWage = baseWage * appliedMonthlyHours;

    final double insurance = monthlyWage * taxRate;
    final double netMonthlyWage = monthlyWage - insurance;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('조건 설정',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          _buildToggleRow('주휴수당 포함 (개근 가정)', assumeFullAttendance,
              (v) => provider.setAssumeFullAttendance(v)),
          _buildToggleRow('5인 이상 사업장 (연장/야간 가산)', isFiveOrMoreEmployees,
              (v) => provider.setIsFiveOrMoreEmployees(v)),
          const SizedBox(height: 8),
          const Text('세금 계산 모드',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'simple',
                label: Text('간편 (추정치)', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment<String>(
                value: 'precision',
                label: Text('정밀 (준비중)', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: const {'simple'},
            onSelectionChanged: (Set<String> newSelection) {
              if (newSelection.first == 'precision') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('정밀 세금 계산 모드는 고도화 예정입니다.')),
                );
              }
            },
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('간편 세율 적용', style: TextStyle(fontSize: 13)),
              DropdownButton<double>(
                value: taxRate,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                      value: 0.0,
                      child:
                          Text('적용 안함 (0%)', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(
                      value: 0.033,
                      child:
                          Text('프리랜서 (3.3%)', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(
                      value: 0.094,
                      child: Text('4대보험 (26년 예상 약 9.4%)',
                          style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) provider.setTaxRate(val);
                },
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.white10),
          ),
          const Text('예상 월급 계산 결과 (주 40시간 기준)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 12),
          _buildResultRow('기본 시급', '${_formatCurrency(baseWage)}원'),
          if (assumeFullAttendance)
            _buildResultRow(
                '주휴수당 포함 시급 (1.2배)', '${_formatCurrency(effectiveHourlyWage)}원',
                valueColor: Colors.greenAccent),
          _buildResultRow('월 예상 급여 (세전)',
              '${_formatCurrency(monthlyWage)}원 (${assumeFullAttendance ? "209시간" : "174시간"})'),
          if (taxRate > 0)
            _buildResultRow('세금 공제 (${(taxRate * 100).toStringAsFixed(1)}%)',
                '-${_formatCurrency(insurance)}원',
                valueColor: Colors.redAccent),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('월 예상 실수령액',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_formatCurrency(netMonthlyWage)}원',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
          if (isFiveOrMoreEmployees)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text(
                    '💡 5인 이상 고용 사업장 추가수당 안내\n• 연장근로: 하루 8시간 초과시 1.5배 (자동 계산)\n• 야간근로: 22:00~06:00 근무시 0.5배 가산 (자동 계산)\n• 휴일근로: 8시간 이내 1.5배, 초과시 2.0배',
                    style: TextStyle(
                        fontSize: 12, color: Colors.amber, height: 1.4)),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
        ],
      ),
    );
  }
}

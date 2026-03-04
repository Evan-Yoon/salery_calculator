import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import '../widgets/main_bottom_nav.dart';

// [STUDY NOTE]: 앱 하단바에서 '설정' 탭을 눌렀을 때 보이는 화면입니다. 시급 설정 변경 기능이 있습니다.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _wageController = TextEditingController();

  String _wageType = '시급';
  bool _includeWeeklyHoliday = true;
  bool _isFiveOrMoreEmployees = false;
  bool _applyInsurance = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    _wageController.text = provider.hourlyWage.toInt().toString();
  }

  @override
  void dispose() {
    _wageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, // 탭 화면이므로 뒤로가기 버튼 숨김
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('급여 기준'),
          _buildWageCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('나의 시급/월급 계산기 (2026년 기준)'),
          _buildCalculatorCard(),
          const SizedBox(height: 24),
          _buildResetButton(),
          const SizedBox(height: 24),
          const Center(
              child: Text('버전 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title,
          style:
              const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

  // [STUDY NOTE]: 기본 시급을 입력하고 보여주는 카드 형태의 UI 위젯입니다.
  Widget _buildWageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: _wageType,
                      underline: const SizedBox(),
                      icon:
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                      items: ['시급', '월급', '연봉'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _onWageTypeChanged,
                    ),
                    const Text('금액을 입력하세요',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _wageController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: '10320',
                        ),
                        onChanged: (val) => _saveWage(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('원', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return TextButton.icon(
      onPressed: () {
        // 초기화 로직이 들어갈 자리
      },
      icon: const Icon(Icons.restart_alt, color: Colors.red),
      label: const Text('데이터 초기화',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _onWageTypeChanged(String? newValue) {
    if (newValue == null || newValue == _wageType) return;

    final provider = Provider.of<SalaryProvider>(context, listen: false);
    final currentHourlyWage = provider.hourlyWage;

    double displayValue = currentHourlyWage;
    if (newValue == '월급') {
      displayValue = currentHourlyWage * 209.0;
    } else if (newValue == '연봉') {
      displayValue = currentHourlyWage * 209.0 * 12.0;
    }

    setState(() {
      _wageType = newValue;
      _wageController.text = displayValue.toInt().toString();
    });
  }

  // [STUDY NOTE]: 사용자가 텍스트 필드에 시급을 입력할 때마다 호출되어, Provider에 새 시급을 저장하는 함수입니다.
  void _saveWage() {
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    final double? inputValue =
        double.tryParse(_wageController.text.replaceAll(',', ''));
    if (inputValue != null) {
      double hourlyWage = inputValue;
      if (_wageType == '월급') {
        hourlyWage = inputValue / 209.0;
      } else if (_wageType == '연봉') {
        hourlyWage = inputValue / (209.0 * 12.0);
      }
      provider.setHourlyWage(hourlyWage);
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildCalculatorCard() {
    final provider = Provider.of<SalaryProvider>(context);
    final double baseWage = provider.hourlyWage;

    final double effectiveHourlyWage =
        _includeWeeklyHoliday ? baseWage * 1.2 : baseWage;
    final double appliedMonthlyHours = _includeWeeklyHoliday ? 209.0 : 174.0;
    final double monthlyWage = baseWage * appliedMonthlyHours;

    final double insurance = _applyInsurance ? monthlyWage * 0.094 : 0.0;
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
          _buildToggleRow('주 15시간 이상 근무 (주휴수당 적용)', _includeWeeklyHoliday,
              (v) => setState(() => _includeWeeklyHoliday = v)),
          _buildToggleRow('5인 이상 사업장 (수당 1.5배 가산)', _isFiveOrMoreEmployees,
              (v) => setState(() => _isFiveOrMoreEmployees = v)),
          _buildToggleRow('4대보험 가입 (약 9.4% 공제)', _applyInsurance,
              (v) => setState(() => _applyInsurance = v)),
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
          if (_includeWeeklyHoliday)
            _buildResultRow(
                '주휴수당 포함 시급 (1.2배)', '${_formatCurrency(effectiveHourlyWage)}원',
                valueColor: Colors.greenAccent),
          _buildResultRow('월 예상 급여 (세전)',
              '${_formatCurrency(monthlyWage)}원 (${_includeWeeklyHoliday ? "209시간" : "174시간"})'),
          if (_applyInsurance)
            _buildResultRow('4대보험 공제 (9.4%)', '-${_formatCurrency(insurance)}원',
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
          if (_isFiveOrMoreEmployees)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text(
                    '💡 5인 이상 고용 사업장 추가수당 안내\n• 연장근로: 시급의 1.5배 (1시간 근무 ➔ 1.5시간 급여)\n• 야간근로(22:00~06:00): 시급의 0.5배 가산\n• 휴일근로: 8시간 이내 1.5배, 8시간 초과 2배',
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

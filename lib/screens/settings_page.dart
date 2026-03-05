import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/settings/preset_section.dart';
import '../widgets/settings/legal_section.dart';
import '../widgets/settings/calculator_card.dart';

// [STUDY NOTE]: 앱 하단바에서 '설정' 탭을 눌렀을 때 보이는 화면입니다. 시급 설정 변경 기능이 있습니다.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _wageController = TextEditingController();

  String _wageType = '시급';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    _wageController.text =
        _formatWithComma(provider.hourlyWage.toInt().toString());
  }

  String _formatWithComma(String numStr) {
    if (numStr.isEmpty) return '';
    final number = int.tryParse(numStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  void dispose() {
    _wageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalaryProvider>(context);

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

          // [STUDY NOTE]: 교대 근무자에게만 프리셋 시간 설정 메뉴를 보여줍니다.
          if (provider.isShiftWorker) ...[
            _buildSectionHeader('근무 프리셋 시간 설정 (데이/이브/나이트)'),
            const PresetSection(),
            const SizedBox(height: 24),
          ],

          _buildSectionHeader('나의 시급/월급 계산기 (2026년 기준)'),
          const CalculatorCard(),
          const SizedBox(height: 24),
          const DisclaimerCard(),
          const SizedBox(height: 24),
          const LegalSection(),
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
                        onChanged: (text) {
                          final numericString =
                              text.replaceAll(RegExp(r'[^0-9]'), '');
                          if (numericString.isEmpty) {
                            _wageController.value =
                                const TextEditingValue(text: '');
                          } else {
                            final number = int.parse(numericString);
                            final formatted = number
                                .toString()
                                .replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},');
                            _wageController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          }
                          _saveWage();
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(_wageType == '시급' ? '원' : '만원',
                        style: const TextStyle(fontSize: 16)),
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
      displayValue = (currentHourlyWage * 209.0) / 10000.0;
    } else if (newValue == '연봉') {
      displayValue = (currentHourlyWage * 209.0 * 12.0) / 10000.0;
    }

    setState(() {
      _wageType = newValue;
      _wageController.text = _formatWithComma(displayValue.toInt().toString());
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
        hourlyWage = (inputValue * 10000) / 209.0;
      } else if (_wageType == '연봉') {
        hourlyWage = (inputValue * 10000) / (209.0 * 12.0);
      }
      provider.setHourlyWage(hourlyWage);
    }
  }
}

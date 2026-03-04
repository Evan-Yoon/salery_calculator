import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import '../models/shift_preset.dart';
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
          _buildSectionHeader('근무 프리셋 시간 설정 (데이/이브/나이트)'),
          _buildPresetsSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('나의 시급/월급 계산기 (2026년 기준)'),
          _buildCalculatorCard(),
          const SizedBox(height: 24),
          _buildDisclaimerCard(),
          const SizedBox(height: 24),
          _buildLegalSection(),
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

  // [STUDY NOTE]: 저장된 프리셋(데이, 이브, 나이트 등)의 시간을 변경할 수 있는 UI 영역입니다.
  Widget _buildPresetsSection() {
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
                onTap: () => _showEditPresetDialog(preset),
              ),
              if (!isLast) const Divider(height: 1, color: Colors.white10),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showEditPresetDialog(ShiftPreset preset) {
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
                            decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12)),
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
                            decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12)),
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
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12)),
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
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12)),
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
    final bool isFiveOrMoreEmployees = provider.isFiveOrMoreEmployees;
    final double taxRate = provider.taxRate;

    final double effectiveHourlyWage =
        _includeWeeklyHoliday ? baseWage * 1.2 : baseWage;
    final double appliedMonthlyHours = _includeWeeklyHoliday ? 209.0 : 174.0;
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
          _buildToggleRow('주 15시간 이상 근무 (주휴수당 적용)', _includeWeeklyHoliday,
              (v) => setState(() => _includeWeeklyHoliday = v)),
          _buildToggleRow('5인 이상 사업장 (연장/야간 가산)', isFiveOrMoreEmployees,
              (v) => provider.setIsFiveOrMoreEmployees(v)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('세금 공제 항목', style: TextStyle(fontSize: 13)),
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
                      child: Text('4대보험 (약 9.4%)',
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
          if (_includeWeeklyHoliday)
            _buildResultRow(
                '주휴수당 포함 시급 (1.2배)', '${_formatCurrency(effectiveHourlyWage)}원',
                valueColor: Colors.greenAccent),
          _buildResultRow('월 예상 급여 (세전)',
              '${_formatCurrency(monthlyWage)}원 (${_includeWeeklyHoliday ? "209시간" : "174시간"})'),
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

  // [STUDY NOTE]: 법적 분쟁 시 증거로 사용될 수 없다는 면책 조항(안내문)을 보여주는 위젯입니다.
  Widget _buildDisclaimerCard() {
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
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                '안내 및 면책 조항',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '본 앱에서 제공하는 급여 및 통계 계산 결과는 사용자가 입력한 데이터를 바탕으로 한 단순 참고용입니다.\n\n'
            '실제 수령액과 차이가 있을 수 있으며, 어떠한 경우에도 노사 갈등이나 법적 분쟁 상황에서 증거 자료로 활용되거나 법적 효력을 가질 수 없습니다.\n\n'
            '정확한 급여 산정 및 법적 자문이 필요하신 경우, 고용노동부 또는 공인노무사 등 전문가에게 문의하시기 바랍니다.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('약관 및 정책'),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text('서비스 이용약관', style: TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showLegalText('서비스 이용약관',
                    '제 1 장 총칙\n\n여러분의 급여자 계산기 앱 이용을 환영합니다. 본 약관은 사용자가 서비스를 이용함에 있어 필요한 제반 사항을 규정합니다.\n\n앱에서 제공하는 모든 계산 결과는 참고용이며, 법적 효력이 없습니다. 자세한 법적 자문은 노무사와 상담하시기 바랍니다.'),
              ),
              const Divider(height: 1, color: Colors.white10),
              ListTile(
                title: const Text('개인정보처리방침', style: TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showLegalText('개인정보처리방침',
                    '본 앱은 회원가입이나 로그인을 요구하지 않으며, 사용자가 입력한 근무 기록 및 모든 개인정보는 서버로 전송되지 않고 사용자의 스마트폰 내부 저장소에만 안전하게 저장됩니다.\n\n따라서 앱을 삭제하시면 모든 데이터가 지워집니다.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLegalText(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
            child: Text(content,
                style: const TextStyle(fontSize: 13, height: 1.5))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
        ],
      ),
    );
  }
}

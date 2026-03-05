import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import 'home_page.dart';

// [STUDY NOTE]: 온보딩의 두 번째 단계로, 사용자가 시급/월급/연봉을 입력하는 화면입니다.
class SalaryInputPage extends StatefulWidget {
  const SalaryInputPage({super.key});

  @override
  State<SalaryInputPage> createState() => _SalaryInputPageState();
}

class _SalaryInputPageState extends State<SalaryInputPage> {
  final TextEditingController _wageController = TextEditingController();
  String _wageType = '시급';
  bool _isSaving = false;

  @override
  void dispose() {
    _wageController.dispose();
    super.dispose();
  }

  void _completeOnboarding(BuildContext context, {bool skip = false}) async {
    setState(() => _isSaving = true);

    final provider = Provider.of<SalaryProvider>(context, listen: false);

    if (!skip && _wageController.text.isNotEmpty) {
      final double? inputValue =
          double.tryParse(_wageController.text.replaceAll(',', ''));

      if (inputValue != null) {
        double hourlyWage = inputValue;
        // 월정산/연봉의 경우 주 40시간(209시간) 기준으로 시급 역산 (단위: 만원 -> 원)
        if (_wageType == '월급') {
          hourlyWage = (inputValue * 10000) / 209.0;
        } else if (_wageType == '연봉') {
          hourlyWage = (inputValue * 10000) / (209.0 * 12.0);
        }
        provider.setHourlyWage(hourlyWage);
      }
    }

    // 온보딩 완료 처리
    await provider.completeOnboarding();

    if (!mounted) return;

    // 메인 화면으로 이동
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('급여 정보 입력 (선택)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _completeOnboarding(context, skip: true),
            child: const Text('건너뛰기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.monetization_on,
                  size: 64, color: Color(0xFF2B8CEE)),
              const SizedBox(height: 24),
              const Text(
                '현재 급여 정보를\n입력해 주세요',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '정확한 급여 예측과 통계 제공을 위해 활용됩니다.\n입력하신 모든 정보는 기기 내부에만 안전하게 저장되며\n외부로 전송되지 않습니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 입력 폼
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _wageType,
                      underline: const SizedBox(),
                      items: ['시급', '월급', '연봉']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _wageType = val);
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _wageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '금액을 입력하세요',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          suffixIcon: _wageController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _wageController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        onChanged: (text) {
                          // 숫자만 남기고 필터링 후 컴마(_) 표기 로직 (간단한 형태)
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
                          setState(() {});
                        },
                      ),
                    ),
                    Text(_wageType == '시급' ? '원' : '만원',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('설정 탭에서 언제든지 금액을 수정할 수 있습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),

              const Spacer(),

              ElevatedButton(
                onPressed:
                    _isSaving ? null : () => _completeOnboarding(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        '시작하기',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16), // SafeArea bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/settings/preset_section.dart';
import '../widgets/settings/legal_section.dart';
import '../widgets/settings/calculator_card.dart';
import '../premium/premium_guard.dart';
import '../premium/premium_features.dart';
import '../premium/premium_state.dart';
import '../screens/paywall_page.dart';
import '../screens/pattern_generator_page.dart';
import '../screens/workplace_preset_page.dart';
import '../screens/csv_export_page.dart';
import '../screens/cloud_backup_page.dart';

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
    final premiumProvider = Provider.of<PremiumProvider>(context);

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

          _buildSectionHeader('프리미엄 전용 기능 (Premium)'),
          if (!premiumProvider.isPremium) ...[
            _buildUpgradeBanner(),
            const SizedBox(height: 16),
          ],
          _buildPremiumSection(),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "구독은 스토어 계정에서 관리됩니다.\n기기 변경 시 '구매 복원'을 눌러 Premium 상태를 복구할 수 있습니다.",
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
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
          // 최저임금 알림 UI 추가
          if (_wageType == '시급' && _wageController.text.isNotEmpty)
            Builder(
              builder: (context) {
                final parsed =
                    int.tryParse(_wageController.text.replaceAll(',', '')) ?? 0;
                if (parsed > 0 && parsed < 10320) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '⚠️ 2026년 최저임금(10,320원)보다 낮게 설정되어 있습니다.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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

  Widget _buildUpgradeBanner() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PaywallPage(entryPoint: "settings_upgrade_button"),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.amber, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium 업그레이드',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text('모든 프리미엄 기능을 무제한으로 사용하세요!',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildPremiumTile(
            title: '패턴 자동 생성',
            icon: Icons.auto_awesome,
            feature: PremiumFeature.shiftPatternGenerator,
            featureHint: '교대 패턴 자동 생성',
            onTapAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PatternGeneratorPage())),
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildPremiumTile(
            title: 'N잡 관리',
            icon: Icons.business_center,
            feature: PremiumFeature.workplacePresets,
            featureHint: '근무지별 급여 규정 저장',
            onTapAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WorkplacePresetPage())),
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildPremiumTile(
            title: '엑셀 리포트 (CSV)',
            icon: Icons.table_chart,
            feature: PremiumFeature.excelExport,
            featureHint: '엑셀 리포트',
            onTapAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CsvExportPage())),
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildPremiumTile(
            title: '백업 / 동기화',
            icon: Icons.cloud_sync,
            feature: PremiumFeature.cloudBackup,
            featureHint: 'Google Drive 백업',
            onTapAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CloudBackupPage())),
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildPremiumTile(
            title: '수당 템플릿',
            icon: Icons.payments,
            feature: PremiumFeature.allowanceTemplates,
            featureHint: '수당 템플릿',
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildPremiumTile(
            title: '스마트 알림',
            icon: Icons.notifications_active,
            feature: PremiumFeature.smartNotifications,
            featureHint: '근무/월말 알림',
          ),
          const Divider(height: 1, color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.grey),
            title: const Text('구독 상태 다시 확인 (구매 복원)'),
            subtitle: const Text('구독 상태가 반영되지 않거나 기기 변경 후 복원 시 눌러주세요',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            onTap: () async {
              final premiumProvider =
                  Provider.of<PremiumProvider>(context, listen: false);
              await premiumProvider.iapService.restore();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('스토어에서 구독 상태를 확인하고 있습니다.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTile({
    required String title,
    required IconData icon,
    required PremiumFeature feature,
    required String featureHint,
    VoidCallback? onTapAction,
  }) {
    return PremiumGuard(
      feature: feature,
      lockedBuilder: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Row(
          children: [
            Text('$title 🔒', style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            const Text('Premium',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: const Text('Premium 기능',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          final premiumProvider =
              Provider.of<PremiumProvider>(context, listen: false);
          if (premiumProvider.status == PremiumStatus.unknown) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('결제 및 구독 상태를 확인 중입니다. 잠시만 기다려주세요.')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaywallPage(
                entryPoint: "settings_locked",
                featureHint: featureHint,
              ),
            ),
          );
        },
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTapAction ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('준비 중입니다.')),
              );
            },
      ),
    );
  }
}

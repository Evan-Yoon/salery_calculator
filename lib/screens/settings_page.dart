import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _wageController = TextEditingController();

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
        automaticallyImplyLeading: false, // Hide back button as it is a tab
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           _buildSectionHeader('급여 기준'),
           _buildWageCard(),
           const SizedBox(height: 24),
           _buildResetButton(),
           const SizedBox(height: 24),
           const Center(
             child: Text('버전 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12))
           ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('시급 설정', style: TextStyle(fontSize: 16)),
                    Text('기본 시급을 입력하세요', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _wageController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary
                        ),
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
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주휴수당 포함', style: TextStyle(fontSize: 16)),
                    Text('주 15시간 이상 근무 시 적용 (미구현)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(value: false, onChanged: (v){}, activeColor: Theme.of(context).colorScheme.primary),
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
         // Reset logic placeholder
       },
       icon: const Icon(Icons.restart_alt, color: Colors.red),
       label: const Text('데이터 초기화', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
       style: TextButton.styleFrom(
         backgroundColor: Colors.red.withOpacity(0.1),
         padding: const EdgeInsets.symmetric(vertical: 16),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       ),
     );
  }

  void _saveWage() {
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    final double? wage = double.tryParse(_wageController.text.replaceAll(',', ''));
    if (wage != null) {
      provider.setHourlyWage(wage);
    }
  }
}

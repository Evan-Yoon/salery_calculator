import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../models/allowance_template.dart';
import '../premium/premium_state.dart';
import '../premium/premium_features.dart';
import '../screens/paywall_page.dart';
import '../screens/allowance_template_form_page.dart';

class AllowanceTemplatesPage extends StatelessWidget {
  const AllowanceTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final isPremium =
        premiumProvider.hasFeature(PremiumFeature.allowanceTemplates);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('수당 템플릿', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<SalaryProvider>(
        builder: (context, provider, _) {
          final templates = provider.allowanceTemplates;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(context),
              const SizedBox(height: 20),
              if (!isPremium) _buildPreviewBanner(context),
              if (!isPremium) const SizedBox(height: 16),
              if (templates.isEmpty)
                _buildEmptyState()
              else
                ...templates.map(
                    (t) => _buildTemplateCard(context, t, provider, isPremium)),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddTapped(context, isPremium),
        icon: const Icon(Icons.add),
        label: const Text('템플릿 추가'),
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
      child: const Row(
        children: [
          Icon(Icons.payments_outlined, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '자주 사용하는 수당 항목을 저장해 근무 입력 시 빠르게 적용할 수 있습니다.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBanner(BuildContext context) {
    return InkWell(
      onTap: () => _goPaywall(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium 전용 기능',
                      style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  SizedBox(height: 2),
                  Text(
                    '목록 미리보기만 가능합니다. 추가·수정·삭제·적용은 Premium으로 업그레이드하세요.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('저장된 수당 템플릿이 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              '야간수당, 특근수당, 교육수당 등을\n템플릿으로 저장해보세요.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, AllowanceTemplate template,
      SalaryProvider provider, bool isPremium) {
    final fmt = NumberFormat('#,###');
    final amountLabel = template.isPerHour
        ? '₩${fmt.format(template.amount.toInt())} / 시간'
        : '₩${fmt.format(template.amount.toInt())}';
    final typeLabel = template.isPerHour ? '시간당' : '고정';
    final typeColor = template.isPerHour ? Colors.blue : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: template.isActive ? Colors.white24 : Colors.white10,
        ),
      ),
      child: Opacity(
        opacity: template.isActive ? 1.0 : 0.5,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(Icons.payments,
                color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  template.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(typeLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: typeColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(amountLabel,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              if (template.note != null && template.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(template.note!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 활성화 스위치
              Switch(
                value: template.isActive,
                onChanged: isPremium
                    ? (_) => provider.toggleAllowanceTemplateActive(template.id)
                    : (_) => _goPaywall(context),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return null;
                }),
              ),
              // 수정/삭제 메뉴
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (!isPremium) {
                    _goPaywall(context);
                    return;
                  }
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AllowanceTemplateFormPage(existing: template),
                      ),
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(context, template, provider);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit,
                            size: 16, color: isPremium ? null : Colors.grey),
                        const SizedBox(width: 8),
                        Text('수정',
                            style: TextStyle(
                                color: isPremium ? null : Colors.grey)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            size: 16,
                            color: isPremium ? Colors.redAccent : Colors.grey),
                        const SizedBox(width: 8),
                        Text('삭제',
                            style: TextStyle(
                                color: isPremium
                                    ? Colors.redAccent
                                    : Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAddTapped(BuildContext context, bool isPremium) {
    if (!isPremium) {
      _goPaywall(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllowanceTemplateFormPage()),
    );
  }

  void _goPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaywallPage(
          entryPoint: 'allowance_templates',
          featureHint: '수당 템플릿',
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AllowanceTemplate template,
      SalaryProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text("'${template.name}' 템플릿을 삭제하시겠습니까?"),
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
    if (ok == true) {
      provider.deleteAllowanceTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'${template.name}' 템플릿이 삭제되었습니다.")),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          SizedBox(height: 12),
          Text(
            '본 앱에서 제공하는 급여 및 통계 계산 결과는 사용자가 입력한 데이터를 바탕으로 한 단순 참고용(일반 정보 제공 목적)입니다.\n\n'
            '실제 지급액은 개별 근로계약서, 취업규칙, 사업장 규모, 단체협약 등에 따라 크게 달라질 수 있습니다. 어떠한 경우에도 노사 갈등이나 법적 분쟁 상황에서 증거 자료로 활용되거나 법률적 효력을 가질 수 없습니다.\n\n'
            '정확한 급여 산정 및 노동법 관련 법적 자문이 필요하신 경우, 반드시 고용노동부(1350) 또는 공인노무사 등 전문가에게 사전 문의하시기 바랍니다.',
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
}

class LegalSection extends StatelessWidget {
  const LegalSection({super.key});

  @override
  Widget build(BuildContext context) {
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
                onTap: () => _showLegalText(context, '서비스 이용약관',
                    '제 1 장 총칙\n\n여러분의 급여자 계산기 앱 이용을 환영합니다. 본 약관은 사용자가 서비스를 이용함에 있어 필요한 제반 사항을 규정합니다.\n\n앱에서 제공하는 모든 계산 결과는 참고용이며, 법적 효력이 없습니다. 자세한 법적 자문은 노무사와 상담하시기 바랍니다.'),
              ),
              const Divider(height: 1, color: Colors.white10),
              ListTile(
                title: const Text('개인정보처리방침', style: TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showLegalText(
                    context,
                    '개인정보처리방침',
                    '본 앱은 어떠한 형태의 회원가입이나 로그인을 요구하지 않으며, 이름, 주민등록번호, 계좌번호 등 민감한 개인정보를 수집하지 않습니다.\n\n'
                        '사용자가 입력한 근무 시간, 급여 조건 등 모든 데이터는 외부 서버로 일체 전송되지 않고 사용자의 기기 내부(로컬 저장소)에만 안전하게 보관됩니다. (Zero-Data Collection Policy)\n\n'
                        '앱을 삭제하시거나 데이터 초기화를 진행하시면 기기 내에 보관된 모든 기록이 즉시 영구 삭제되며, 이는 복구될 수 없습니다.'),
              ),
            ],
          ),
        ),
      ],
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

  void _showLegalText(BuildContext context, String title, String content) {
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

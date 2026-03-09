import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/salary_provider.dart';
import '../services/google_drive_service.dart';

// [STUDY NOTE]: Google Drive 백업/복원 UI 페이지입니다.
class CloudBackupPage extends StatefulWidget {
  const CloudBackupPage({super.key});

  @override
  State<CloudBackupPage> createState() => _CloudBackupPageState();
}

class _CloudBackupPageState extends State<CloudBackupPage> {
  GoogleSignInAccount? _user;
  DateTime? _lastBackupTime;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initSignIn();
  }

  Future<void> _initSignIn() async {
    setState(() => _isLoading = true);
    // 자동 로그인 시도
    final user = await GoogleDriveService.signInSilently();
    DateTime? lastBackup;
    if (user != null) {
      lastBackup = await GoogleDriveService.getLastBackupTime();
    }
    if (mounted) {
      setState(() {
        _user = user;
        _lastBackupTime = lastBackup;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('백업 / 동기화',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _user == null ? _buildSignInSection() : _buildAccountSection(),
                const SizedBox(height: 24),
                if (_user != null) ...[
                  _buildBackupSection(),
                  const SizedBox(height: 16),
                  _buildRestoreSection(),
                ],
                if (_statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildStatusMessage(),
                ],
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_outlined, color: Colors.blue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '모든 근무 기록, 설정, 프리셋을 Google Drive에 안전하게 저장합니다. 기기를 바꿔도 복원할 수 있습니다.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_circle_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Google 계정 연결',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '백업하려면 Google 계정으로 로그인하세요.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signIn,
              icon: const Icon(Icons.login),
              label: const Text('Google로 로그인'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage:
                _user?.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
            child: _user?.photoUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_user!.displayName ?? '사용자',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_user!.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: _signOut,
            child:
                const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    final lastBackupStr = _lastBackupTime == null
        ? '백업 기록 없음'
        : '마지막 백업: ${DateFormat('yyyy.MM.dd HH:mm').format(_lastBackupTime!.toLocal())}';

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
              Icon(Icons.backup, size: 20),
              SizedBox(width: 8),
              Text('백업',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(lastBackupStr,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _backup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('지금 백업',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restore, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text('복원',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '⚠️ 복원하면 기존 데이터가 백업 데이터로 교체됩니다.',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _restore,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('백업에서 복원',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(_statusMessage,
              style: const TextStyle(color: Colors.green, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final user = await GoogleDriveService.signIn();
    DateTime? lastBackup;
    if (user != null) {
      lastBackup = await GoogleDriveService.getLastBackupTime();
    }
    if (mounted) {
      setState(() {
        _user = user;
        _lastBackupTime = lastBackup;
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await GoogleDriveService.signOut();
    if (mounted) {
      setState(() {
        _user = null;
        _lastBackupTime = null;
      });
    }
  }

  Future<void> _backup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    try {
      final provider = Provider.of<SalaryProvider>(context, listen: false);
      final json = provider.exportToJson();
      await GoogleDriveService.backupData(json);
      final backupTime = await GoogleDriveService.getLastBackupTime();
      if (mounted) {
        setState(() {
          _lastBackupTime = backupTime;
          _statusMessage = '백업이 완료되었습니다.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('복원 확인'),
        content: const Text('현재 저장된 모든 데이터가 백업 데이터로 교체됩니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    try {
      final jsonData = await GoogleDriveService.restoreData();
      if (jsonData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('복원할 백업 파일이 없습니다.')),
          );
        }
        return;
      }
      if (!mounted) return;
      final provider = Provider.of<SalaryProvider>(context, listen: false);
      await provider.importFromJson(jsonData);
      if (mounted) setState(() => _statusMessage = '복원이 완료되었습니다.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복원 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

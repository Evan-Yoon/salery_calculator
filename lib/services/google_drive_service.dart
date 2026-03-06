import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

// [STUDY NOTE]: Google Drive API와의 연동을 담당하는 서비스 클래스입니다.
// 사용자의 Google Drive 앱 전용 폴더(appDataFolder)에 백업 파일을 저장합니다.
// 앱 전용 폴더는 해당 앱만 접근 가능하므로 보안 측면에서 안전합니다.
class GoogleDriveService {
  static const _backupFileName = 'salary_backup.json';

  static final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  // ── 인증 ──

  /// 현재 로그인된 사용자를 반환합니다. 없으면 null.
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// 로그인 상태 스트림
  static Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Google 로그인 (UI 표시)
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google SignIn error: $e');
      return null;
    }
  }

  /// 자동 로그인 시도 (앱 시작 시)
  static Future<GoogleSignInAccount?> signInSilently() async {
    return await _googleSignIn.signInSilently();
  }

  /// 로그아웃
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // ── Drive 클라이언트 ──

  static Future<drive.DriveApi?> _getDriveApi() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    final headers = await account.authHeaders;
    final client = _AuthClient(headers);
    return drive.DriveApi(client);
  }

  // ── 백업 ──

  /// 모든 앱 데이터를 JSON 문자열로 받아 Drive에 업로드합니다.
  /// 기존 백업이 있으면 덮어씁니다.
  static Future<void> backupData(String jsonData) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('로그인 필요');

    final bytes = utf8.encode(jsonData);
    final media = drive.Media(Stream.value(bytes), bytes.length,
        contentType: 'application/json');

    // 기존 백업 파일 검색
    final existing = await _findBackupFile(api);

    if (existing != null) {
      // 업데이트
      await api.files.update(drive.File(), existing.id!, uploadMedia: media);
    } else {
      // 새로 생성
      final file = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];
      await api.files.create(file, uploadMedia: media);
    }
  }

  // ── 복원 ──

  /// Drive의 백업 파일을 JSON 문자열로 반환합니다.
  static Future<String?> restoreData() async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('로그인 필요');

    final file = await _findBackupFile(api);
    if (file == null) return null;

    final response = await api.files.get(
      file.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = await response.stream.expand((b) => b).toList();
    return utf8.decode(bytes);
  }

  // ── 백업 정보 ──

  /// 마지막 백업 파일의 수정 시각을 반환합니다.
  static Future<DateTime?> getLastBackupTime() async {
    final api = await _getDriveApi();
    if (api == null) return null;
    final file = await _findBackupFile(api);
    return file?.modifiedTime;
  }

  static Future<drive.File?> _findBackupFile(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
      $fields: 'files(id, name, modifiedTime)',
    );
    return list.files?.isNotEmpty == true ? list.files!.first : null;
  }
}

/// Google 인증 헤더를 주입하는 HTTP 클라이언트 래퍼입니다.
class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

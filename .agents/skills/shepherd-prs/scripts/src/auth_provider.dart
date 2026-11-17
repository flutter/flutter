// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show ProcessResult;

import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import 'models.dart';

const int _tokenExpirySafetyMarginMs = 60000;
const int _defaultExpiresInSeconds = 3600;
const String _gcloudExecutable = 'gcloud';
const String _chmodExecutable = 'chmod';
const String _xdgConfigHomeEnvVar = 'XDG_CONFIG_HOME';
const String _homeEnvVar = 'HOME';
const String _userProfileEnvVar = 'USERPROFILE';

final RegExp _webFirebaseApiKeyPattern = RegExp(
  r"web\s*=\s*FirebaseOptions\([\s\S]*?apiKey:\s*'([^']+)'",
);

/// Resolves, refreshes, and persists (`0600`) `flutter-dashboard` Firebase ID
/// tokens from either Google OAuth (`@google.com`) or Firebase sessions
/// (including GitHub OAuth `flutter-hackers` tokens).
class DashboardAuthProvider {
  DashboardAuthProvider({
    required this._fileSystem,
    required this._hostEnvironment,
    required this._httpClient,
    required this._processManager,
    DateTime Function()? clock,
    this._credentialsFilePath,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final String? _credentialsFilePath;
  final FileSystem _fileSystem;
  final HostEnvironment _hostEnvironment;
  final http.Client _httpClient;
  final ProcessManager _processManager;

  String resolveCredentialsPath() {
    if (_credentialsFilePath != null && _credentialsFilePath.isNotEmpty) {
      return _credentialsFilePath;
    }
    final Map<String, String> env = _hostEnvironment.environment;
    final String? xdgConfig = env[_xdgConfigHomeEnvVar];
    if (xdgConfig != null && xdgConfig.isNotEmpty) {
      return path.join(
        xdgConfig,
        DashboardConstants.configDirName,
        DashboardConstants.credentialsFileName,
      );
    }
    final String? home = env[_homeEnvVar] ?? env[_userProfileEnvVar];
    if (home == null || home.isEmpty) {
      throw const DashboardAuthException(
        'Cannot determine home directory to store flutter-dashboard credentials. '
        'Pass --credentials-file or set HOME.',
      );
    }
    return path.join(
      home,
      '.config',
      DashboardConstants.configDirName,
      DashboardConstants.credentialsFileName,
    );
  }

  /// Resolves a valid Firebase `idToken` for `X-Flutter-IdToken`.
  Future<String> resolveIdToken({
    String? accountEmail,
    bool allowGcloudExchange = true,
    String? explicitAccessToken,
    String? explicitIdToken,
    bool forceRefresh = false,
  }) async {
    final String? providedIdToken =
        _nonEmpty(explicitIdToken) ??
        _nonEmpty(_hostEnvironment.environment[DashboardConstants.idTokenEnvVar]);
    if (providedIdToken != null && !forceRefresh) {
      _validateFirebaseJwtClaims(providedIdToken, requireGoogleEmail: false);
      return providedIdToken;
    }

    final StoredDashboardCredentials? stored = readStoredCredentials();
    if (stored != null) {
      final int nowMs = _clock().millisecondsSinceEpoch;
      final StoredDashboardCredentials(
        idToken: String? cachedIdToken,
        expiresAtEpochMs: int? expiresAtMs,
      ) = stored;
      if (!forceRefresh &&
          cachedIdToken != null &&
          cachedIdToken.isNotEmpty &&
          expiresAtMs != null &&
          nowMs + _tokenExpirySafetyMarginMs < expiresAtMs) {
        _validateFirebaseJwtClaims(cachedIdToken, requireGoogleEmail: false);
        return cachedIdToken;
      }
      final StoredDashboardCredentials refreshed = await _refreshIdToken(stored);
      await _writeCredentialsSecurely(refreshed);
      return refreshed.idToken!;
    }

    final String? accessToken =
        _nonEmpty(explicitAccessToken) ??
        _nonEmpty(_hostEnvironment.environment[DashboardConstants.accessTokenEnvVar]);
    if (accessToken != null) {
      final StoredDashboardCredentials exchanged = await loginWithAccessToken(accessToken);
      return exchanged.idToken!;
    }

    if (allowGcloudExchange) {
      final String? gcloudToken = await _tryReadGcloudGoogleAccessToken(accountEmail: accountEmail);
      if (gcloudToken != null) {
        final StoredDashboardCredentials exchanged = await loginWithAccessToken(gcloudToken);
        return exchanged.idToken!;
      }
    }

    throw const DashboardAuthException('No flutter-dashboard Firebase credentials configured.');
  }

  /// Bootstraps and persists Firebase credentials from an explicit Firebase
  /// [explicitRefreshToken], Google OAuth [explicitAccessToken], or `gcloud`.
  Future<StoredDashboardCredentials> login({
    String? accountEmail,
    String? explicitAccessToken,
    String? explicitRefreshToken,
  }) async {
    final String? refreshToken =
        _nonEmpty(explicitRefreshToken) ??
        _nonEmpty(_hostEnvironment.environment[DashboardConstants.refreshTokenEnvVar]);
    if (refreshToken != null) {
      return loginWithRefreshToken(refreshToken);
    }
    final String? providedToken =
        _nonEmpty(explicitAccessToken) ??
        _nonEmpty(_hostEnvironment.environment[DashboardConstants.accessTokenEnvVar]);
    if (providedToken != null) {
      return loginWithAccessToken(providedToken);
    }
    final String gcloudToken = await _requireGcloudGoogleAccessToken(accountEmail: accountEmail);
    return loginWithAccessToken(gcloudToken);
  }

  /// Exchanges a Firebase [refreshToken] (from Google or GitHub Sign-In on
  /// `flutter-dashboard`) and persists it with `0600` permissions.
  Future<StoredDashboardCredentials> loginWithRefreshToken(String refreshToken) async {
    final String trimmed = refreshToken.trim();
    if (trimmed.isEmpty) {
      throw const DashboardAuthException('Firebase refresh token cannot be empty.');
    }
    final StoredDashboardCredentials refreshed = await _refreshIdToken(
      StoredDashboardCredentials(refreshToken: trimmed),
    );
    await _writeCredentialsSecurely(refreshed);
    return refreshed;
  }

  /// Exchanges a Google OAuth [accessToken] via Firebase `accounts:signInWithIdp`
  /// (`providerId=google.com`) and persists the resulting credentials (`0600`).
  Future<StoredDashboardCredentials> loginWithAccessToken(String accessToken) async {
    final String trimmedToken = accessToken.trim();
    if (trimmedToken.isEmpty) {
      throw const DashboardAuthException('Google OAuth access token cannot be empty.');
    }
    if (trimmedToken.startsWith('ghp_') || trimmedToken.startsWith('github_pat_')) {
      throw const DashboardAuthException(
        'Classic/fine-grained GitHub PATs (from `gh auth token`) are rejected by '
        'flutter-dashboard Firebase authentication. Authenticate with a @google.com '
        'account via `gcloud auth login`, or pass a Firebase token via --id-token / --refresh-token.',
      );
    }

    final String apiKey = await _resolveFirebaseWebApiKey();
    final http.Response response = await _httpClient.post(
      Uri.parse(DashboardConstants.firebaseSignInWithIdpUrl(apiKey)),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, Object?>{
        'postBody':
            'access_token=${Uri.encodeQueryComponent(trimmedToken)}'
            '&providerId=${DashboardConstants.googleProviderId}',
        'requestUri': DashboardConstants.dashboardBaseUrl,
        'returnIdpCredential': true,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      throw DashboardAuthException(
        'Firebase Google Sign-In exchange failed (HTTP ${response.statusCode}): '
        '${_summarizeErrorBody(response.body)}',
      );
    }

    final Map<String, Object?> payload = decodeJsonObject(
      _decodeJson(response.body, context: 'Firebase signInWithIdp response'),
      context: 'Firebase signInWithIdp response',
    );
    final String? idToken = _nonEmpty(readJsonString(payload['idToken']));
    final String? refreshToken = _nonEmpty(readJsonString(payload['refreshToken']));
    if (idToken == null || refreshToken == null) {
      throw const DashboardAuthException(
        'Firebase signInWithIdp response did not include idToken and refreshToken.',
      );
    }

    _validateFirebaseJwtClaims(idToken, requireGoogleEmail: true);
    final String? email = _nonEmpty(readJsonString(payload['email'])) ?? _extractJwtEmail(idToken);
    _validateAccountEmail(email, requireGoogleDomain: true);

    final int expiresInSeconds = readJsonInt(payload['expiresIn']) ?? _defaultExpiresInSeconds;
    final int expiresAtEpochMs = _clock().millisecondsSinceEpoch + expiresInSeconds * 1000;

    final credentials = StoredDashboardCredentials(
      email: email,
      expiresAtEpochMs: expiresAtEpochMs,
      firebaseApiKey: apiKey,
      idToken: idToken,
      refreshToken: refreshToken,
    );
    await _writeCredentialsSecurely(credentials);
    return credentials;
  }

  StoredDashboardCredentials? readStoredCredentials() {
    final String credentialsPath = resolveCredentialsPath();
    final File file = _fileSystem.file(credentialsPath);
    if (!file.existsSync()) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (error) {
      throw DashboardAuthException(
        'Corrupt credentials file at $credentialsPath: ${error.message}. '
        'Run `login --logout` or `login` to recreate it.',
      );
    }
    if (decoded is! Map<Object?, Object?>) {
      throw DashboardAuthException(
        'Corrupt credentials file at $credentialsPath: expected JSON object. '
        'Run `login --logout` or `login` to recreate it.',
      );
    }
    return StoredDashboardCredentials.fromJson(
      decodeJsonObject(decoded, context: 'stored credentials ($credentialsPath)'),
    );
  }

  bool deleteStoredCredentials() {
    final File file = _fileSystem.file(resolveCredentialsPath());
    if (!file.existsSync()) {
      return false;
    }
    file.deleteSync();
    return true;
  }

  Future<StoredDashboardCredentials> _refreshIdToken(StoredDashboardCredentials stored) async {
    final String apiKey = await _resolveFirebaseWebApiKey(cachedApiKey: stored.firebaseApiKey);
    final http.Response response = await _httpClient.post(
      Uri.parse(DashboardConstants.firebaseSecureTokenUrl(apiKey)),
      headers: const <String, String>{'Content-Type': 'application/x-www-form-urlencoded'},
      body:
          'grant_type=refresh_token'
          '&refresh_token=${Uri.encodeQueryComponent(stored.refreshToken)}',
    );

    if (response.statusCode != 200) {
      throw DashboardAuthException(
        'Failed to refresh cached flutter-dashboard token (HTTP ${response.statusCode}): '
        '${_summarizeErrorBody(response.body)}. Re-run `login` to re-authenticate.',
      );
    }

    final Map<String, Object?> payload = decodeJsonObject(
      _decodeJson(response.body, context: 'Firebase securetoken refresh response'),
      context: 'Firebase securetoken refresh response',
    );
    final String? idToken = _nonEmpty(
      readJsonString(payload['id_token']) ?? readJsonString(payload['idToken']),
    );
    final String refreshToken =
        _nonEmpty(
          readJsonString(payload['refresh_token']) ?? readJsonString(payload['refreshToken']),
        ) ??
        stored.refreshToken;
    if (idToken == null) {
      throw const DashboardAuthException(
        'Firebase securetoken refresh response did not include id_token.',
      );
    }

    _validateFirebaseJwtClaims(idToken, requireGoogleEmail: false);
    final String? email = _extractJwtEmail(idToken) ?? stored.email;
    _validateAccountEmail(email, requireGoogleDomain: _isGoogleSignInProvider(idToken));

    final int expiresInSeconds =
        readJsonInt(payload['expires_in']) ??
        readJsonInt(payload['expiresIn']) ??
        _defaultExpiresInSeconds;
    final int expiresAtEpochMs = _clock().millisecondsSinceEpoch + expiresInSeconds * 1000;

    return StoredDashboardCredentials(
      email: email,
      expiresAtEpochMs: expiresAtEpochMs,
      firebaseApiKey: apiKey,
      idToken: idToken,
      refreshToken: refreshToken,
    );
  }

  Future<String> _resolveFirebaseWebApiKey({String? cachedApiKey}) async {
    final String? envKey = _nonEmpty(
      _hostEnvironment.environment[DashboardConstants.firebaseApiKeyEnvVar],
    );
    if (envKey != null) {
      return envKey;
    }
    final String? cached = _nonEmpty(cachedApiKey);
    if (cached != null) {
      return cached;
    }
    final http.Response response = await _httpClient.get(
      Uri.parse(DashboardConstants.cocoonFirebaseOptionsUrl),
    );
    if (response.statusCode != 200) {
      throw DashboardAuthException(
        'Failed to fetch public flutter-dashboard Firebase configuration '
        '(HTTP ${response.statusCode}). Set ${DashboardConstants.firebaseApiKeyEnvVar} if offline.',
      );
    }
    final RegExpMatch? match = _webFirebaseApiKeyPattern.firstMatch(response.body);
    final String? extracted = _nonEmpty(match?.group(1));
    if (extracted == null) {
      throw const DashboardAuthException(
        'Could not parse web Firebase apiKey from flutter/cocoon firebase_options.dart.',
      );
    }
    return extracted;
  }

  Future<String?> _tryReadGcloudGoogleAccessToken({String? accountEmail}) async {
    if (!_processManager.canRun(_gcloudExecutable)) {
      return null;
    }
    final String? selectedAccount = await _selectGoogleAccountFromGcloud(
      requestedAccount: accountEmail,
    );
    if (selectedAccount == null) {
      return null;
    }
    final ProcessResult result = await _processManager.run(<String>[
      _gcloudExecutable,
      'auth',
      'print-access-token',
      '--account=$selectedAccount',
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    return _nonEmpty('${result.stdout}'.trim());
  }

  Future<String> _requireGcloudGoogleAccessToken({String? accountEmail}) async {
    if (!_processManager.canRun(_gcloudExecutable)) {
      throw const DashboardAuthException(
        '`gcloud` CLI was not found on PATH. Run `gcloud auth login` with your '
        '@google.com account, or pass --access-token / --refresh-token.',
      );
    }

    if (accountEmail != null && accountEmail.isNotEmpty) {
      _validateAccountEmail(accountEmail, requireGoogleDomain: true);
    }

    final String? selectedAccount = await _selectGoogleAccountFromGcloud(
      requestedAccount: accountEmail,
      throwOnServiceAccountOnly: true,
    );
    if (selectedAccount == null) {
      throw const DashboardAuthException(
        'No @google.com account is authenticated in `gcloud`. '
        'Run `gcloud auth login` with your @google.com account, then re-run `login`.',
      );
    }

    final ProcessResult result = await _processManager.run(<String>[
      _gcloudExecutable,
      'auth',
      'print-access-token',
      '--account=$selectedAccount',
    ]);
    if (result.exitCode != 0) {
      throw DashboardAuthException(
        '`gcloud auth print-access-token --account=$selectedAccount` failed: '
        '${'${result.stderr}'.trim()}',
      );
    }
    final String? token = _nonEmpty('${result.stdout}'.trim());
    if (token == null) {
      throw DashboardAuthException(
        '`gcloud auth print-access-token --account=$selectedAccount` returned an empty token.',
      );
    }
    return token;
  }

  Future<String?> _selectGoogleAccountFromGcloud({
    String? requestedAccount,
    bool throwOnServiceAccountOnly = false,
  }) async {
    if (requestedAccount != null && requestedAccount.trim().isNotEmpty) {
      final String trimmed = requestedAccount.trim();
      _validateAccountEmail(trimmed, requireGoogleDomain: true);
      return trimmed;
    }

    final ProcessResult listResult = await _processManager.run(<String>[
      _gcloudExecutable,
      'auth',
      'list',
      '--format=json',
    ]);
    if (listResult.exitCode != 0) {
      return null;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode('${listResult.stdout}');
    } on FormatException {
      return null;
    }
    if (decoded is! List<Object?>) {
      return null;
    }

    String? activeGoogleAccount;
    String? fallbackGoogleAccount;
    final serviceAccounts = <String>[];

    for (final Object? item in decoded) {
      if (item is! Map<Object?, Object?>) {
        continue;
      }
      final Object? rawAccount = item['account'];
      final Object? rawStatus = item['status'];
      if (rawAccount is! String || rawAccount.isEmpty) {
        continue;
      }
      if (rawAccount.toLowerCase().endsWith(DashboardConstants.googleEmailSuffix)) {
        if (rawStatus == 'ACTIVE') {
          activeGoogleAccount = rawAccount;
        } else {
          fallbackGoogleAccount ??= rawAccount;
        }
      } else if (rawAccount.toLowerCase().endsWith(DashboardConstants.serviceAccountEmailSuffix)) {
        serviceAccounts.add(rawAccount);
      }
    }

    final String? chosen = activeGoogleAccount ?? fallbackGoogleAccount;
    if (chosen == null && throwOnServiceAccountOnly && serviceAccounts.isNotEmpty) {
      throw DashboardAuthException(
        'Found only machine service account(s) in `gcloud auth list` '
        '(${serviceAccounts.join(', ')}), which flutter-dashboard rejects. '
        'Run `gcloud auth login` in your terminal to sign in with your '
        '@google.com account, then re-run `login`.',
      );
    }
    return chosen;
  }

  Future<void> _writeCredentialsSecurely(StoredDashboardCredentials credentials) async {
    if (!_hostEnvironment.isWindows && !_processManager.canRun(_chmodExecutable)) {
      throw const DashboardException(
        'Cannot securely persist credentials on POSIX: `chmod` is not available on PATH.',
      );
    }

    final String targetPath = resolveCredentialsPath();
    final Directory parentDir = _fileSystem.directory(path.dirname(targetPath));
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }
    if (!_hostEnvironment.isWindows) {
      await _setPosixPermissions(parentDir.path, '700');
    }

    final tempPath = '$targetPath.tmp';
    final File tempFile = _fileSystem.file(tempPath);
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }
    tempFile.createSync();
    if (!_hostEnvironment.isWindows) {
      await _setPosixPermissions(tempFile.path, '600');
    }
    tempFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(credentials.toJson())}\n',
    );
    tempFile.renameSync(targetPath);
    if (!_hostEnvironment.isWindows) {
      await _setPosixPermissions(targetPath, '600');
    }
  }

  Future<void> _setPosixPermissions(String targetPath, String octalMode) async {
    final ProcessResult result = await _processManager.run(<String>[
      _chmodExecutable,
      octalMode,
      targetPath,
    ]);
    if (result.exitCode != 0) {
      throw DashboardException(
        'Failed to set permissions ($octalMode) on $targetPath: ${'${result.stderr}'.trim()}',
      );
    }
  }

  void _validateAccountEmail(String? email, {required bool requireGoogleDomain}) {
    if (email == null || email.isEmpty) {
      return;
    }
    final String lower = email.toLowerCase();
    if (lower.endsWith(DashboardConstants.serviceAccountEmailSuffix)) {
      throw DashboardAuthException(
        'Authenticated account "$email" is a service account. '
        'flutter-dashboard requires an interactive user account.',
      );
    }
    if (requireGoogleDomain && !lower.endsWith(DashboardConstants.googleEmailSuffix)) {
      throw DashboardAuthException(
        'Google Sign-In account "$email" is not an @google.com account required by '
        'DashboardFirebaseAuthentication on flutter-dashboard.',
      );
    }
  }

  void _validateFirebaseJwtClaims(String jwt, {required bool requireGoogleEmail}) {
    final Map<String, Object?>? claims = _tryDecodeJwtPayload(jwt);
    if (claims == null) {
      return;
    }
    final String? issuer = readJsonString(claims['iss']);
    if (issuer != null && issuer != DashboardConstants.firebaseExpectedIssuer) {
      throw DashboardAuthException(
        'JWT issuer "$issuer" does not match "${DashboardConstants.firebaseExpectedIssuer}".',
      );
    }
    final Object? aud = claims['aud'];
    final bool validAudience = switch (aud) {
      final String single => single == DashboardConstants.firebaseProjectId,
      final List<Object?> list => list.contains(DashboardConstants.firebaseProjectId),
      _ => true,
    };
    if (!validAudience) {
      throw DashboardAuthException(
        'JWT audience "$aud" does not include "${DashboardConstants.firebaseProjectId}".',
      );
    }
    final String? email = readJsonString(claims['email']);
    _validateAccountEmail(
      email,
      requireGoogleDomain: requireGoogleEmail || _isClaimsGoogleProvider(claims),
    );
  }

  bool _isGoogleSignInProvider(String jwt) {
    final Map<String, Object?>? claims = _tryDecodeJwtPayload(jwt);
    return claims != null && _isClaimsGoogleProvider(claims);
  }

  static bool _isClaimsGoogleProvider(Map<String, Object?> claims) => switch (claims['firebase']) {
    {'sign_in_provider': DashboardConstants.googleProviderId} => true,
    _ => false,
  };

  String? _extractJwtEmail(String jwt) => readJsonString(_tryDecodeJwtPayload(jwt)?['email']);

  Map<String, Object?>? _tryDecodeJwtPayload(String jwt) {
    final List<String> segments = jwt.split('.');
    if (segments.length != 3) {
      return null;
    }
    try {
      final String normalized = base64Url.normalize(segments[1]);
      final String jsonText = utf8.decode(base64Url.decode(normalized));
      final Object? decoded = jsonDecode(jsonText);
      if (decoded is Map<Object?, Object?>) {
        return decodeJsonObject(decoded, context: 'JWT payload');
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static Object? _decodeJson(String body, {required String context}) {
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw DashboardAuthException('Invalid JSON in $context: ${error.message}');
    }
  }

  static String? _nonEmpty(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _summarizeErrorBody(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return 'empty response body';
    }
    try {
      final Object? decoded = jsonDecode(trimmed);
      if (decoded case {'error': {'message': final String msg}}) {
        return msg;
      }
      if (decoded case {'error_description': final String desc}) {
        return desc;
      }
    } on FormatException {
      // Fall back to raw snippet below.
    }
    return trimmed.length <= 200 ? trimmed : '${trimmed.substring(0, 200)}...';
  }
}

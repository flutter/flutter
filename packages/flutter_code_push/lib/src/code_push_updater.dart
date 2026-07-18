import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'models/patch_info.dart';
import 'models/update_check_result.dart';

/// OTA updater for Dart isolate AOT snapshots only.
///
/// The store-shipped `libapp.so` / `App.framework` (VM + native engine binding)
/// is never replaced. Patches update `isolate_snapshot_data` and
/// `isolate_snapshot_instr` on the next cold start.
class CodePushUpdater {
  CodePushUpdater({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const MethodChannel _channel =
      MethodChannel('dev.flutter.codepush/updater');

  final http.Client _httpClient;

  Future<int?> readCurrentPatchNumber() async {
    return _channel.invokeMethod<int>('readCurrentPatchNumber');
  }

  Future<UpdateCheckResult> checkForUpdate({
    required Uri checkUrl,
    required String releaseVersion,
  }) async {
    final int? currentPatch = await readCurrentPatchNumber();
    final Uri requestUri = checkUrl.replace(
      queryParameters: <String, String>{
        ...checkUrl.queryParameters,
        'release_version': releaseVersion,
        if (currentPatch != null) 'current_patch': '$currentPatch',
      },
    );

    try {
      final http.Response response =
          await _httpClient.get(requestUri).timeout(const Duration(seconds: 30));
      if (response.statusCode == 204) {
        return UpdateCheckResult(
          status: UpdateStatus.upToDate,
          currentPatchNumber: currentPatch,
        );
      }
      if (response.statusCode != 200) {
        return UpdateCheckResult(
          status: UpdateStatus.checkFailed,
          currentPatchNumber: currentPatch,
          message: 'Unexpected status ${response.statusCode}',
        );
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final PatchInfo patch = PatchInfo.fromJson(body);
      if (patch.releaseVersion != releaseVersion) {
        return UpdateCheckResult(
          status: UpdateStatus.checkFailed,
          currentPatchNumber: currentPatch,
          message: 'Server returned patch for ${patch.releaseVersion}, '
              'expected $releaseVersion',
        );
      }
      if (currentPatch != null && patch.patchNumber <= currentPatch) {
        return UpdateCheckResult(
          status: UpdateStatus.upToDate,
          currentPatchNumber: currentPatch,
        );
      }

      return UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        currentPatchNumber: currentPatch,
        availablePatch: patch,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Code push check failed: $error\n$stackTrace');
      }
      return UpdateCheckResult(
        status: UpdateStatus.checkFailed,
        currentPatchNumber: currentPatch,
        message: '$error',
      );
    }
  }

  Future<void> downloadPatch(PatchInfo patch) async {
    await _channel.invokeMethod<void>('stagePatchFromUrls', <String, dynamic>{
      'patch_number': patch.patchNumber,
      'release_version': patch.releaseVersion,
      'data_download_url': patch.dataDownloadUrl,
      'instr_download_url': patch.instrDownloadUrl,
      'isolate_data_sha256': patch.isolateDataSha256,
      'isolate_instr_sha256': patch.isolateInstrSha256,
      if (patch.isolateDataLengthBytes != null)
        'isolate_data_length_bytes': patch.isolateDataLengthBytes,
      if (patch.isolateInstrLengthBytes != null)
        'isolate_instr_length_bytes': patch.isolateInstrLengthBytes,
      'enabled': patch.enabled,
    });
  }

  Future<void> applyStagedPatch() async {
    await _channel.invokeMethod<void>('applyStagedPatch');
  }

  Future<bool> downloadUpdateIfAvailable({
    required Uri checkUrl,
    required String releaseVersion,
  }) async {
    final UpdateCheckResult result = await checkForUpdate(
      checkUrl: checkUrl,
      releaseVersion: releaseVersion,
    );
    if (!result.hasUpdate || result.availablePatch == null) {
      return false;
    }
    await downloadPatch(result.availablePatch!);
    return true;
  }

  Future<void> clearActivePatch() async {
    await _channel.invokeMethod<void>('clearActivePatch');
  }

  void close() {
    _httpClient.close();
  }
}

class CodePushException implements Exception {
  CodePushException(this.message);

  final String message;

  @override
  String toString() => 'CodePushException: $message';
}

import 'patch_info.dart';

/// The status of an update check.
enum UpdateStatus { upToDate, updateAvailable, checkFailed }

/// Result data returned by [CodePushUpdater.checkForUpdate].
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    this.currentPatchNumber,
    this.availablePatch,
    this.message,
  });

  final UpdateStatus status;
  final int? currentPatchNumber;
  final PatchInfo? availablePatch;
  final String? message;

  bool get hasUpdate => status == UpdateStatus.updateAvailable;

  @override
  String toString() {
    return 'UpdateCheckResult(status: $status, '
        'currentPatchNumber: $currentPatchNumber, '
        'availablePatch: $availablePatch, '
        'message: $message)';
  }
}

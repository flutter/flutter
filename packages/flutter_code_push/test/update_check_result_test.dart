import 'package:test/test.dart';

import '../lib/src/models/patch_info.dart';
import '../lib/src/models/update_check_result.dart';

void main() {
  test('UpdateCheckResult reflects update availability', () {
    const UpdateCheckResult result = UpdateCheckResult(
      status: UpdateStatus.updateAvailable,
      currentPatchNumber: 1,
      availablePatch: PatchInfo(
        patchNumber: 2,
        releaseVersion: '1.0.0',
        dataDownloadUrl: 'https://example.com/data',
        instrDownloadUrl: 'https://example.com/instr',
        isolateDataSha256: 'datahash',
        isolateInstrSha256: 'instrhash',
      ),
    );

    expect(result.hasUpdate, isTrue);
    expect(result.currentPatchNumber, 1);
    expect(result.availablePatch?.patchNumber, 2);
  });

  test('UpdateCheckResult without update is not available', () {
    const UpdateCheckResult result = UpdateCheckResult(
      status: UpdateStatus.upToDate,
      currentPatchNumber: 1,
    );

    expect(result.hasUpdate, isFalse);
    expect(result.availablePatch, isNull);
  });
}

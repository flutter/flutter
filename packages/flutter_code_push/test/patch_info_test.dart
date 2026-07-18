import 'package:test/test.dart';

import '../lib/src/models/patch_info.dart';

void main() {
  test('PatchInfo round-trips JSON', () {
    const PatchInfo patch = PatchInfo(
      patchNumber: 3,
      releaseVersion: '2.0.0+1',
      dataDownloadUrl: 'https://example.com/data',
      instrDownloadUrl: 'https://example.com/instr',
      isolateDataSha256: 'datahash',
      isolateInstrSha256: 'instrhash',
      isolateDataLengthBytes: 10,
      isolateInstrLengthBytes: 20,
    );

    final PatchInfo decoded = PatchInfo.fromJson(patch.toJson());
    expect(decoded.patchNumber, 3);
    expect(decoded.dataDownloadUrl, 'https://example.com/data');
    expect(decoded.instrDownloadUrl, 'https://example.com/instr');
    expect(decoded.isolateDataSha256, 'datahash');
    expect(decoded.isolateInstrSha256, 'instrhash');
  });
}

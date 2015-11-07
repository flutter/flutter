import 'dart:convert' hide BASE64;
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flx/bundle.dart';
import 'package:flx/signing.dart';
import 'package:test/test.dart';

main() async {
  // The following constant was generated via the openssl shell commands:
  // openssl ecparam -genkey -name prime256v1 -out privatekey.pem
  // openssl ec -in privatekey.pem -outform DER | base64
  const String kPrivateKeyBase64 = 'MHcCAQEEIG4Xt+MgsdP/o89kAHz7EVVLKkN+DUfpaBtZfMyFGbUgoAoGCCqGSM49AwEHoUQDQgAElPtbBVPPqKHYXYAgHaxB2hL6sXeFc99YLijTAuAPe2Nbhywan+v4k+nFm0TJJW/mkV+nH+fyBZ98t4UcFCqkOg==';
  final List<int> kPrivateKeyDER = BASE64.decode(kPrivateKeyBase64);

  // Test manifest.
  final Map<String, dynamic> kManifest = <String, dynamic>{
    'name': 'test app',
    'version': '1.0.0'
  };

  // Simple test byte pattern.
  final Uint8List kTestBytes = new Uint8List.fromList(<int>[1, 2, 3]);

  // Create a temp dir and file for the bundle.
  Directory tempDir = await Directory.systemTemp.createTempSync('bundle_test');
  String bundlePath = tempDir.path + '/bundle.flx';

  AsymmetricKeyPair keyPair = keyPairFromPrivateKeyBytes(kPrivateKeyDER);
  Map<String, dynamic> manifest = JSON.decode(UTF8.decode(
      serializeManifest(kManifest, keyPair.publicKey, kTestBytes)));

  test('verifyContent works', () async {
    Bundle bundle = new Bundle.fromContent(
      path: bundlePath,
      manifest: manifest,
      contentBytes: kTestBytes,
      keyPair: keyPair
    );

    bool verifies = await bundle.verifyContent();
    expect(verifies, equals(true));
  });

  test('write/read works', () async {
    Bundle bundle = new Bundle.fromContent(
      path: bundlePath,
      manifest: manifest,
      contentBytes: kTestBytes,
      keyPair: keyPair
    );

    bundle.writeSync();

    Bundle diskBundle = await Bundle.readHeader(bundlePath);
    expect(diskBundle != null, equals(true));
    expect(diskBundle.manifestBytes, equals(bundle.manifestBytes));
    expect(diskBundle.signatureBytes, equals(bundle.signatureBytes));
    expect(diskBundle.manifest['key'], equals(bundle.manifest['key']));
    expect(diskBundle.manifest['key'], equals(manifest['key']));

    bool verifies = await diskBundle.verifyContent();
    expect(verifies, equals(true));
  });

  test('cleanup', () async {
    tempDir.deleteSync(recursive: true);
  });
}

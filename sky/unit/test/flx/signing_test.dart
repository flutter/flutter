import 'dart:async';
import 'dart:convert' hide BASE64;
import 'dart:typed_data';

import 'package:bignum/bignum.dart';
import 'package:cipher/cipher.dart' hide CipherParameters;
import 'package:crypto/crypto.dart';
import 'package:flx/signing.dart';
import 'package:test/test.dart';

main() async {
  // The following constant was generated via the openssl shell commands:
  // openssl ecparam -genkey -name prime256v1 -out privatekey.pem
  // openssl ec -in privatekey.pem -outform DER | base64
  const String kPrivateKeyBase64 = 'MHcCAQEEIG4Xt+MgsdP/o89kAHz7EVVLKkN+DUfpaBtZfMyFGbUgoAoGCCqGSM49AwEHoUQDQgAElPtbBVPPqKHYXYAgHaxB2hL6sXeFc99YLijTAuAPe2Nbhywan+v4k+nFm0TJJW/mkV+nH+fyBZ98t4UcFCqkOg==';
  final List<int> kPrivateKeyDER = BASE64.decode(kPrivateKeyBase64);

  // Unpacked values of the above private key.
  const int kPrivateKeyD = 0x6e17b7e320b1d3ffa3cf64007cfb11554b2a437e0d47e9681b597ccc8519b520;
  const int kPublicKeyQx = 0x94fb5b0553cfa8a1d85d80201dac41da12fab1778573df582e28d302e00f7b63;
  const int kPublicKeyQy = 0x5b872c1a9febf893e9c59b44c9256fe6915fa71fe7f2059f7cb7851c142aa43a;

  // Test manifest.
  final Map<String, dynamic> kManifest = <String, dynamic>{
    'name': 'test app',
    'version': '1.0.0'
  };

  // Simple test byte pattern (flat and in chunked form) and its SHA-256 hash.
  final Uint8List kTestBytes = new Uint8List.fromList(<int>[1, 2, 3]);
  final List<Uint8List> kTestBytesList = <Uint8List>[
    new Uint8List.fromList(<int>[1, 2]), new Uint8List.fromList(<int>[3])];
  final int kTestHash = 0x039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81;

  // Set up a key generator.
  CipherParameters cipher = CipherParameters.get();
  await cipher.seedRandom();
  ECKeyGeneratorParameters ecParams = new ECKeyGeneratorParameters(cipher.domain);
  ParametersWithRandom<ECKeyGeneratorParameters> keyGeneratorParams =
    new ParametersWithRandom<ECKeyGeneratorParameters>(ecParams, cipher.random);
  KeyGenerator keyGenerator = new KeyGenerator('EC');
  keyGenerator.init(keyGeneratorParams);

  test('can read openssl key pair', () {
    AsymmetricKeyPair keyPair = keyPairFromPrivateKeyBytes(kPrivateKeyDER);
    expect(keyPair != null, equals(true));
    expect(keyPair.privateKey.d.intValue(), equals(kPrivateKeyD));
    expect(keyPair.publicKey.Q.x.toBigInteger().intValue(), equals(kPublicKeyQx));
    expect(keyPair.publicKey.Q.y.toBigInteger().intValue(), equals(kPublicKeyQy));
  });

  test('serializeManifest adds key and content-hash', () {
    AsymmetricKeyPair keyPair = keyPairFromPrivateKeyBytes(kPrivateKeyDER);
    Uint8List manifestBytes = serializeManifest(kManifest, keyPair.publicKey, kTestBytes);
    Map<String, dynamic> decodedManifest = JSON.decode(UTF8.decode(manifestBytes));
    String expectedKey = BASE64.encode(keyPair.publicKey.Q.getEncoded());
    expect(decodedManifest != null, equals(true));
    expect(decodedManifest['name'], equals(kManifest['name']));
    expect(decodedManifest['version'], equals(kManifest['version']));
    expect(decodedManifest['key'], equals(expectedKey));
    expect(decodedManifest['content-hash'], equals(kTestHash));
  });

  test('signManifest and verifyManifestSignature work', () {
    AsymmetricKeyPair keyPair = keyPairFromPrivateKeyBytes(kPrivateKeyDER);
    Map<String, dynamic> manifest = JSON.decode(UTF8.decode(
        serializeManifest(kManifest, keyPair.publicKey, kTestBytes)));
    Uint8List signatureBytes = signManifest(kTestBytes, keyPair.privateKey);

    bool verifies = verifyManifestSignature(manifest, kTestBytes, signatureBytes);
    expect(verifies, equals(true));

    // Ensure it fails with invalid signature or content.
    Uint8List badBytes = new Uint8List.fromList(<int>[42]);
    verifies = verifyManifestSignature(manifest, kTestBytes, badBytes);
    expect(verifies, equals(false));
    verifies = verifyManifestSignature(manifest, badBytes, signatureBytes);
    expect(verifies, equals(false));
  });

  test('signing works with arbitrary key', () {
    AsymmetricKeyPair keyPair = keyGenerator.generateKeyPair();
    String failReason = 'offending private key: ${keyPair.privateKey.d}';
    Map<String, dynamic> manifest = JSON.decode(UTF8.decode(
        serializeManifest(kManifest, keyPair.publicKey, kTestBytes)));
    Uint8List signatureBytes = signManifest(kTestBytes, keyPair.privateKey);

    bool verifies = verifyManifestSignature(manifest, kTestBytes, signatureBytes);
    expect(verifies, equals(true), reason: failReason);

    // Ensure it fails with invalid signature or content.
    Uint8List badBytes = new Uint8List.fromList(<int>[42]);
    verifies = verifyManifestSignature(manifest, kTestBytes, badBytes);
    expect(verifies, equals(false), reason: failReason);
    verifies = verifyManifestSignature(manifest, badBytes, signatureBytes);
    expect(verifies, equals(false), reason: failReason);
  });

  test('verifyContentHash works', () async {
    Stream contentStream = new Stream.fromIterable(kTestBytesList);
    bool verifies = await verifyContentHash(new BigInteger(kTestHash), contentStream);
    expect(verifies, equals(true));

    // Ensure it fails with invalid hash or content.
    contentStream = new Stream.fromIterable(kTestBytesList);
    verifies = await verifyContentHash(new BigInteger(0xdeadbeef), contentStream);
    expect(verifies, equals(false));

    Stream badContentStream =
        new Stream.fromIterable([new Uint8List.fromList(<int>[42])]);
    verifies = await verifyContentHash(new BigInteger(kTestHash), badContentStream);
    expect(verifies, equals(false));
  });
}

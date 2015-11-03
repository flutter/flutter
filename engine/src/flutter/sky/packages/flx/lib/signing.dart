// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:bignum/bignum.dart';
import 'package:cipher/cipher.dart';
import 'package:cipher/impl/client.dart';

export 'package:cipher/cipher.dart' show AsymmetricKeyPair;

// The ECDSA algorithm parameters we're using. These match the parameters used
// by the Flutter updater package.
class CipherParameters {
  final String signerAlgorithm = 'SHA-256/ECDSA';
  final String hashAlgorithm = 'SHA-256';
  final ECDomainParameters domain = new ECDomainParameters('prime256v1');
  final SecureRandom random = _initRandom();
}

SecureRandom _initRandom() {
  // TODO(mpcomplete): Provide a better seed here. External entropy source?
  final Uint8List key = new Uint8List(16);
  final KeyParameter keyParam = new KeyParameter(key);
  final ParametersWithIV params = new ParametersWithIV(keyParam, new Uint8List(16));
  SecureRandom random = new SecureRandom('AES/CTR/AUTO-SEED-PRNG')
      ..seed(params);
  return random;
}

CipherParameters _initParams() {
  initCipher();
  return new CipherParameters();
}

final CipherParameters _params = _initParams();

// Returns a serialized manifest, with the public key and hash of the content
// included.
Uint8List serializeManifest(Map manifestDescriptor, ECPublicKey publicKey, Uint8List zipBytes) {
  if (manifestDescriptor == null)
    return null;
  final List<String> kSavedKeys = <String>[
    'name',
    'version',
    'update-url'
  ];
  Map outputManifest = new Map();
  manifestDescriptor.forEach((key, value) {
    if (kSavedKeys.contains(key))
      outputManifest[key] = value;
  });

  if (publicKey != null)
    outputManifest['key'] = BASE64.encode(publicKey.Q.getEncoded());

  Uint8List zipHash = new Digest(_params.hashAlgorithm).process(zipBytes);
  BigInteger zipHashInt = new BigInteger.fromBytes(1, zipHash);
  outputManifest['content-hash'] = zipHashInt.intValue();

  return new Uint8List.fromList(UTF8.encode(JSON.encode(outputManifest)));
}

// Returns the ASN.1 encoded signature of the input manifestBytes.
Uint8List signManifest(Uint8List manifestBytes, ECPrivateKey privateKey) {
  if (manifestBytes == null || privateKey == null)
    return new Uint8List(0);
  Signer signer = new Signer(_params.signerAlgorithm);
  PrivateKeyParameter params = new PrivateKeyParameter(privateKey);
  signer.init(true, new ParametersWithRandom(params, _params.random));
  ECSignature signature = signer.generateSignature(manifestBytes);
  ASN1Sequence asn1 = new ASN1Sequence()
    ..add(new ASN1Integer(signature.r))
    ..add(new ASN1Integer(signature.s));
  return asn1.encodedBytes;
}

bool verifyManifestSignature(Map<String, dynamic> manifest,
                             Uint8List manifestBytes,
                             Uint8List signatureBytes) {
  ECSignature signature = _asn1ParseSignature(signatureBytes);
  if (signature == null)
    return false;

  List<int> keyBytes = BASE64.decode(manifest['key']);
  ECPoint q = _params.domain.curve.decodePoint(keyBytes);
  ECPublicKey publicKey = new ECPublicKey(q, _params.domain);

  Signer signer = new Signer(_params.signerAlgorithm);
  signer.init(false, new PublicKeyParameter(publicKey));
  return signer.verifySignature(manifestBytes, signature);
}

Future<bool> verifyContentHash(BigInteger expectedHash, Stream<List<int>> content) async {
  // Hash the file incrementally.
  Digest hasher = new Digest(_params.hashAlgorithm);
  await content.forEach((List<int> chunk) {
    hasher.update(chunk, 0, chunk.length);
  });
  Uint8List hashBytes = new Uint8List(hasher.digestSize);
  int len = hasher.doFinal(hashBytes, 0);
  hashBytes = hashBytes.sublist(0, len);
  BigInteger actualHash = new BigInteger.fromBytes(1, hashBytes);

  return expectedHash == actualHash;
}

// Parses a DER-encoded ASN.1 ECDSA private key block.
ECPrivateKey _asn1ParsePrivateKey(ECDomainParameters ecDomain, Uint8List privateKey) {
  ASN1Parser parser = new ASN1Parser(privateKey);
  ASN1Sequence seq = parser.nextObject();
  assert(seq.elements.length >= 2);
  ASN1OctetString keyOct = seq.elements[1];
  BigInteger d = new BigInteger.fromBytes(1, keyOct.octets);
  return new ECPrivateKey(d, ecDomain);
}

// Parses a DER-encoded ASN.1 ECDSA signature block.
ECSignature _asn1ParseSignature(Uint8List signature) {
  try {
    ASN1Parser parser = new ASN1Parser(signature);
    ASN1Object object = parser.nextObject();
    if (object is! ASN1Sequence)
      return null;
    ASN1Sequence sequence = object;
    if (!(sequence.elements.length == 2 &&
          sequence.elements[0] is ASN1Integer &&
          sequence.elements[1] is ASN1Integer))
      return null;
    ASN1Integer r = sequence.elements[0];
    ASN1Integer s = sequence.elements[1];
    return new ECSignature(r.valueAsPositiveBigInteger, s.valueAsPositiveBigInteger);
  } on ASN1Exception {
    return null;
  }
}

ECPublicKey _publicKeyFromPrivateKey(ECPrivateKey privateKey) {
  ECPoint Q = privateKey.parameters.G * privateKey.d;
  return new ECPublicKey(Q, privateKey.parameters);
}

AsymmetricKeyPair keyPairFromPrivateKeyFileSync(String privateKeyPath) {
  File file = new File(privateKeyPath);
  if (!file.existsSync())
    return null;
  return keyPairFromPrivateKeyBytes(file.readAsBytesSync());
}

AsymmetricKeyPair keyPairFromPrivateKeyBytes(List<int> privateKeyBytes) {
  ECPrivateKey privateKey = _asn1ParsePrivateKey(
      _params.domain, new Uint8List.fromList(privateKeyBytes));
  if (privateKey == null)
    return null;

  ECPublicKey publicKey = _publicKeyFromPrivateKey(privateKey);
  return new AsymmetricKeyPair(publicKey, privateKey);
}

// TODO(mpcomplete): remove this class when flutter_tools is updated.
class KeyPair extends AsymmetricKeyPair {
  KeyPair(PublicKey publicKey, PrivateKey privateKey)
      : super(publicKey, privateKey);

  static KeyPair readFromPrivateKeySync(String privateKeyPath) {
    AsymmetricKeyPair pair = keyPairFromPrivateKeyFileSync(privateKeyPath);
    if (pair == null)
      return null;
    return new KeyPair(pair.publicKey, pair.privateKey);
  }
}

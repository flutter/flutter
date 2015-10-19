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

// The ECDSA algorithm parameters we're using. These match the parameters used
// by the Flutter updater package.
final ECDomainParameters _ecDomain = new ECDomainParameters('prime256v1');
final String kSignerAlgorithm = 'SHA-256/ECDSA';
final String kHashAlgorithm = 'SHA-256';

final SecureRandom _random = _initRandom();

SecureRandom _initRandom() {
  // TODO(mpcomplete): Provide a better seed here. External entropy source?
  final Uint8List key = new Uint8List(16);
  final KeyParameter keyParam = new KeyParameter(key);
  final ParametersWithIV params = new ParametersWithIV(keyParam, new Uint8List(16));
  SecureRandom random = new SecureRandom('AES/CTR/AUTO-SEED-PRNG')
      ..seed(params);
  return random;
}

// Returns a serialized manifest, with the public key and hash of the content
// included.
Uint8List serializeManifest(Map manifestDescriptor, ECPublicKey publicKey, Uint8List zipBytes) {
  if (manifestDescriptor == null)
    return null;
  final List<String> kSavedKeys = [
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

  Uint8List zipHash = new Digest(kHashAlgorithm).process(zipBytes);
  BigInteger zipHashInt = new BigInteger.fromBytes(1, zipHash);
  outputManifest['content-hash'] = zipHashInt.intValue();

  return new Uint8List.fromList(UTF8.encode(JSON.encode(outputManifest)));
}

// Returns the ASN.1 encoded signature of the input manifestBytes.
List<int> signManifest(Uint8List manifestBytes, ECPrivateKey privateKey) {
  if (manifestBytes == null || privateKey == null)
    return [];
  Signer signer = new Signer(kSignerAlgorithm);
  PrivateKeyParameter params = new PrivateKeyParameter(privateKey);
  signer.init(true, new ParametersWithRandom(params, _random));
  ECSignature signature = signer.generateSignature(manifestBytes);
  ASN1Sequence asn1 = new ASN1Sequence()
    ..add(new ASN1Integer(signature.r))
    ..add(new ASN1Integer(signature.s));
  return asn1.encodedBytes;
}

ECPrivateKey _asn1ParsePrivateKey(ECDomainParameters ecDomain, Uint8List privateKey) {
  ASN1Parser parser = new ASN1Parser(privateKey);
  ASN1Sequence seq = parser.nextObject();
  assert(seq.elements.length >= 2);
  ASN1OctetString keyOct = seq.elements[1];
  BigInteger d = new BigInteger.fromBytes(1, keyOct.octets);
  return new ECPrivateKey(d, ecDomain);
}

Future<ECPrivateKey> loadPrivateKey(String privateKeyPath) async {
  File file = new File(privateKeyPath);
  if (!file.existsSync())
    return null;
  List<int> bytes = file.readAsBytesSync();
  return _asn1ParsePrivateKey(_ecDomain, new Uint8List.fromList(bytes));
}

ECPublicKey publicKeyFromPrivateKey(ECPrivateKey privateKey) {
  if (privateKey == null)
    return null;
  ECPoint Q = privateKey.parameters.G * privateKey.d;
  return new ECPublicKey(Q, privateKey.parameters);
}

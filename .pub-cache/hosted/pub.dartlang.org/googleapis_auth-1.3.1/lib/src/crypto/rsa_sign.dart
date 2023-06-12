// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'asn1.dart';
import 'rsa.dart';

/// Used for signing messages with a private RSA key.
///
/// The implemented algorithm can be seen in
/// RFC 3447, Section 9.2 EMSA-PKCS1-v1_5.
class RS256Signer {
  // NIST sha-256 OID (2 16 840 1 101 3 4 2 1)
  // See a reference for the encoding here:
  // http://msdn.microsoft.com/en-us/library/bb540809%28v=vs.85%29.aspx
  static const _rsaSha256AlgorithmIdentifier = [
    0x06,
    0x09,
    0x60,
    0x86,
    0x48,
    0x01,
    0x65,
    0x03,
    0x04,
    0x02,
    0x01
  ];

  final RSAPrivateKey _rsaKey;

  RS256Signer(this._rsaKey);

  List<int> sign(List<int> bytes) {
    final digest = _digestInfo(sha256.convert(bytes).bytes);
    final modulusLen = (_rsaKey.bitLength + 7) ~/ 8;

    final block = Uint8List(modulusLen);
    final padLength = block.length - digest.length - 3;
    block[0] = 0x00;
    block[1] = 0x01;
    block.fillRange(2, 2 + padLength, 0xFF);
    block[2 + padLength] = 0x00;
    block.setRange(2 + padLength + 1, block.length, digest);
    return RSAAlgorithm.encrypt(_rsaKey, block, modulusLen);
  }

  static Uint8List _digestInfo(List<int> hash) {
    // DigestInfo :== SEQUENCE {
    //     digestAlgorithm AlgorithmIdentifier,
    //     digest OCTET STRING
    // }
    var offset = 0;
    final digestInfo = Uint8List(
      2 + 2 + _rsaSha256AlgorithmIdentifier.length + 2 + 2 + hash.length,
    );
    {
      // DigestInfo
      digestInfo[offset++] = ASN1Parser.sequenceTag;
      digestInfo[offset++] = digestInfo.length - 2;
      {
        // AlgorithmIdentifier.
        digestInfo[offset++] = ASN1Parser.sequenceTag;
        digestInfo[offset++] = _rsaSha256AlgorithmIdentifier.length + 2;
        digestInfo.setAll(offset, _rsaSha256AlgorithmIdentifier);
        offset += _rsaSha256AlgorithmIdentifier.length;
        digestInfo[offset++] = ASN1Parser.nullTag;
        digestInfo[offset++] = 0;
      }
      digestInfo[offset++] = ASN1Parser.octetStringTag;
      digestInfo[offset++] = hash.length;
      digestInfo.setAll(offset, hash);
    }
    return digestInfo;
  }
}

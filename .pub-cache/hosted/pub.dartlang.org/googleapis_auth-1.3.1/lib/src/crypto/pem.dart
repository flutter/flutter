// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'asn1.dart';
import 'rsa.dart';

/// Decode a [RSAPrivateKey] from the string content of a PEM file.
///
/// A PEM file can be extracted from a .p12 cryptostore with
/// $ openssl pkcs12 -nocerts -nodes -passin pass:notasecret \
///       -in *-privatekey.p12 -out *-privatekey.pem
RSAPrivateKey keyFromString(String pemFileString) {
  final bytes = _getBytesFromPEMString(pemFileString);
  return _extractRSAKeyFromDERBytes(bytes);
}

/// Helper function for decoding the base64 in [pemString].
Uint8List _getBytesFromPEMString(String pemString) {
  final lines = LineSplitter.split(pemString)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  if (lines.length < 2 ||
      !lines.first.startsWith('-----BEGIN') ||
      !lines.last.startsWith('-----END')) {
    throw ArgumentError(
      'The given string does not have the correct '
      'begin/end markers expected in a PEM file.',
    );
  }
  final base64 = lines.sublist(1, lines.length - 1).join();
  return Uint8List.fromList(base64Decode(base64));
}

/// Helper to decode the ASN.1/DER bytes in [bytes] into an [RSAPrivateKey].
RSAPrivateKey _extractRSAKeyFromDERBytes(Uint8List bytes) {
  // We recognize two formats:
  // Real format:
  //
  // PrivateKey := seq[int/version=0, int/n, int/e, int/d, int/p,
  //                   int/q, int/dmp1, int/dmq1, int/coeff]
  //
  // Or the above `PrivateKey` embeddded inside another ASN object:
  // Encapsulated := seq[int/version=0,
  //                     seq[obj-id/rsa-id, null-obj],
  //                     octet-string/PrivateKey]
  //

  RSAPrivateKey privateKeyFromSequence(ASN1Sequence asnSequence) {
    final objects = asnSequence.objects;

    final asnIntegers = objects.take(9).map((o) => o as ASN1Integer).toList();

    final version = asnIntegers.first;
    if (version.integer != BigInt.zero) {
      throw ArgumentError('Expected version 0, got: ${version.integer}.');
    }

    final key = RSAPrivateKey(
      asnIntegers[1].integer,
      asnIntegers[2].integer,
      asnIntegers[3].integer,
      asnIntegers[4].integer,
      asnIntegers[5].integer,
      asnIntegers[6].integer,
      asnIntegers[7].integer,
      asnIntegers[8].integer,
    );

    final bitLength = key.bitLength;
    if (bitLength != 1024 && bitLength != 2048 && bitLength != 4096) {
      throw ArgumentError(
        'The RSA modulus has a bit length of $bitLength. '
        'Only 1024, 2048 and 4096 are supported.',
      );
    }
    return key;
  }

  try {
    final asn = ASN1Parser.parse(bytes);
    if (asn is ASN1Sequence) {
      final objects = asn.objects;
      if (objects.length == 3 && objects[2] is ASN1OctetString) {
        final string = objects[2] as ASN1OctetString;
        // Seems like the embedded form.
        // TODO: Validate that rsa identifier matches!
        return privateKeyFromSequence(
          ASN1Parser.parse(string.bytes as Uint8List) as ASN1Sequence,
        );
      }
    }
    return privateKeyFromSequence(asn as ASN1Sequence);
  } catch (error) {
    throw ArgumentError(
      'Error while extracting private key from DER bytes: $error',
    );
  }
}

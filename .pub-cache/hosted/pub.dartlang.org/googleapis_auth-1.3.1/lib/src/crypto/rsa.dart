// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A small part is based on a JavaScript implementation of RSA by Tom Wu
// but re-written in dart.

import 'dart:typed_data';

/// Represents integers obtained while creating a Public/Private key pair.
class RSAPrivateKey {
  /// First prime number.
  final BigInt p;

  /// Second prime number.
  final BigInt q;

  /// Modulus for public and private keys. Satisfies `n=p*q`.
  final BigInt n;

  /// Public key exponent. Satisfies `d*e=1 mod phi(n)`.
  final BigInt e;

  /// Private key exponent. Satisfies `d*e=1 mod phi(n)`.
  final BigInt d;

  /// Different form of [p]. Satisfies `dmp1=d mod (p-1)`.
  final BigInt dmp1;

  /// Different form of [p]. Satisfies `dmq1=d mod (q-1)`.
  final BigInt dmq1;

  /// A coefficient which satisfies `coeff=q^-1 mod p`.
  final BigInt coeff;

  /// The number of bits used for the modulus. Usually 1024, 2048 or 4096 bits.
  int get bitLength => n.bitLength;

  RSAPrivateKey(
    this.n,
    this.e,
    this.d,
    this.p,
    this.q,
    this.dmp1,
    this.dmq1,
    this.coeff,
  );
}

// ignore: avoid_classes_with_only_static_members
/// Provides a [encrypt] method for encrypting messages with a [RSAPrivateKey].
abstract class RSAAlgorithm {
  /// Performs the encryption of [bytes] with the private [key].
  /// Others who have access to the public key will be able to decrypt this
  /// the result.
  ///
  /// The [intendedLength] argument specifies the number of bytes in which the
  /// result should be encoded. Zero bytes will be used for padding.
  static List<int> encrypt(
    RSAPrivateKey key,
    List<int> bytes,
    int intendedLength,
  ) {
    final message = bytes2BigInt(bytes);
    final encryptedMessage = _encryptInteger(key, message);
    return integer2Bytes(encryptedMessage, intendedLength);
  }

  static BigInt _encryptInteger(RSAPrivateKey key, BigInt x) {
    // The following is equivalent to `_modPow(x, key.d, key.n) but is much
    // more efficient. It exploits the fact that we have dmp1/dmq1.
    var xp = _modPow(x % key.p, key.dmp1, key.p);
    final xq = _modPow(x % key.q, key.dmq1, key.q);
    while (xp < xq) {
      xp += key.p;
    }
    return ((((xp - xq) * key.coeff) % key.p) * key.q) + xq;
  }

  static BigInt _modPow(BigInt b, BigInt e, BigInt m) {
    if (e < BigInt.one) {
      return BigInt.one;
    }
    if (b < BigInt.zero || b > m) {
      b = b % m;
    }
    var r = BigInt.one;
    while (e > BigInt.zero) {
      if ((e & BigInt.one) > BigInt.zero) {
        r = (r * b) % m;
      }
      e >>= 1;
      b = (b * b) % m;
    }
    return r;
  }

  static BigInt bytes2BigInt(List<int> bytes) {
    var number = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      number = (number << 8) | BigInt.from(bytes[i]);
    }
    return number;
  }

  static List<int> integer2Bytes(BigInt integer, int intendedLength) {
    if (integer < BigInt.one) {
      throw ArgumentError('Only positive integers are supported.');
    }
    final bytes = Uint8List(intendedLength);
    for (var i = bytes.length - 1; i >= 0; i--) {
      bytes[i] = (integer & _bigIntFF).toInt();
      integer >>= 8;
    }
    return bytes;
  }
}

final _bigIntFF = BigInt.from(0xff);

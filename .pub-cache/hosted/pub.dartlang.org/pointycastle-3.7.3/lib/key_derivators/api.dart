// See file LICENSE for more information.

library api.key_derivators;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';

/// [CipherParameters] used by PBKDF2.
class Pbkdf2Parameters extends CipherParameters {
  final Uint8List salt;
  final int iterationCount;
  final int desiredKeyLength;

  Pbkdf2Parameters(this.salt, this.iterationCount, this.desiredKeyLength);
}

/// [CipherParameters] for the scrypt password based key derivation function.
class ScryptParameters implements CipherParameters {
  final int N;
  final int r;
  final int p;
  final int desiredKeyLength;
  final Uint8List salt;

  ScryptParameters(this.N, this.r, this.p, this.desiredKeyLength, this.salt);
}

/// Generates [CipherParameters] for HKDF key derivation function.
class HkdfParameters extends CipherParameters {
  final Uint8List ikm; // the input keying material or seed
  final int desiredKeyLength;
  final Uint8List?
      salt; // the salt to use, may be null for a salt for hashLen zeros
  final Uint8List?
      info; // the info to use, may be null for an info field of zero bytes
  final bool skipExtract;

  HkdfParameters._(this.ikm, this.desiredKeyLength,
      [this.salt, this.info, this.skipExtract = false]);

  factory HkdfParameters(ikm, desiredKeyLength,
      [salt, info, skipExtract = false]) {
    if (ikm == null) {
      throw ArgumentError('IKM (input keying material) should not be null');
    }

    if (salt == null || salt.length == 0) {
      salt = null;
    }

    return HkdfParameters._(
        ikm, desiredKeyLength, salt, info ?? Uint8List(0), skipExtract);
  }
}

/// The Argon2 parameters.
class Argon2Parameters extends CipherParameters {
  static const int ARGON2_d = 0x00;
  static const int ARGON2_i = 0x01;
  static const int ARGON2_id = 0x02;

  static const int ARGON2_VERSION_10 = 0x10;
  static const int ARGON2_VERSION_13 = 0x13;

  static const int DEFAULT_ITERATIONS = 3;
  static const int DEFAULT_MEMORY_COST = 12;
  static const int DEFAULT_LANES = 1;
  static const int DEFAULT_TYPE = ARGON2_i;
  static const int DEFAULT_VERSION = ARGON2_VERSION_13;

  final int type;
  final int desiredKeyLength;

  final Uint8List _salt;
  final Uint8List? _secret;
  final Uint8List? _additional;

  final int iterations;
  final int memory;
  final int lanes;

  final int version;

  Argon2Parameters(
    this.type,
    this._salt, {
    required this.desiredKeyLength,
    Uint8List? secret,
    Uint8List? additional,
    this.iterations = DEFAULT_ITERATIONS,
    int? memoryPowerOf2,
    int? memory,
    this.lanes = DEFAULT_LANES,
    this.version = DEFAULT_VERSION,
  })  : memory = memoryPowerOf2 != null
            ? 1 << memoryPowerOf2
            : (memory ?? (1 << DEFAULT_MEMORY_COST)),
        _secret = secret,
        _additional = additional;

  Uint8List get salt => _salt;

  Uint8List? get secret => _secret;

  Uint8List? get additional => _additional;

  void clear() {
    _salt.clear();
    _secret?.clear();
    _additional?.clear();
  }

  @override
  String toString() {
    return 'Argon2Parameters{ type: $type, iterations: $iterations, memory: $memory, lanes: $lanes, version: $version }';
  }
}

class ECDHKDFParameters extends CipherParameters {
  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;

  ECDHKDFParameters(this.privateKey, this.publicKey);
}

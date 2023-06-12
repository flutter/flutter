/// Utility functions for UUID library.
library uuid_util;

import 'dart:math';
import 'dart:typed_data';

class UuidUtil {
  static final _random = Random();
  static final _secureRandom = Random.secure();

  /// Math.Random()-based RNG. All platforms, fast, not cryptographically
  /// strong. Optional Seed passable.
  static Uint8List mathRNG({int seed = -1}) {
    final b = Uint8List(16);
    final rand = (seed == -1) ? _random : Random(seed);

    for (var i = 0; i < 16; i++) {
      b[i] = rand.nextInt(256);
    }

    return b;
  }

  /// Crypto-Strong RNG. All platforms, unknown speed, cryptographically strong
  /// (theoretically)
  static Uint8List cryptoRNG() {
    final b = Uint8List(16);

    for (var i = 0; i < 16; i++) {
      b[i] = _secureRandom.nextInt(256);
    }

    return b;
  }
}

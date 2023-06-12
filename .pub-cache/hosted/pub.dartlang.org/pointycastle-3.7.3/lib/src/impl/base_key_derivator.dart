// See file LICENSE for more information.

library src.impl.base_key_derivator;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base implementation of [KeyDerivator] which provides shared methods.
abstract class BaseKeyDerivator implements KeyDerivator {
  @override
  Uint8List process(Uint8List data) {
    var out = Uint8List(keySize);
    var len = deriveKey(data, 0, out, 0);
    return out.sublist(0, len);
  }
}

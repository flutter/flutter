// See file LICENSE for more information.

library src.impl.base_asymmetric_block_cipher;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base implementation of [AsymmetricBlockCipher] which provides shared methods.
abstract class BaseAsymmetricBlockCipher implements AsymmetricBlockCipher {
  @override
  Uint8List process(Uint8List data) {
    var out = Uint8List(outputBlockSize);
    var len = processBlock(data, 0, data.length, out, 0);
    return out.sublist(0, len);
  }
}

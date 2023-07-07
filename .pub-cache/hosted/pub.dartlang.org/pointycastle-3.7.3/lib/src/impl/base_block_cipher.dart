// See file LICENSE for more information.

library src.impl.base_block_cipher;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base implementation of [BlockCipher] which provides shared methods.
abstract class BaseBlockCipher implements BlockCipher {
  @override
  Uint8List process(Uint8List data) {
    var out = Uint8List(blockSize);
    var len = processBlock(data, 0, out, 0);
    return out.sublist(0, len);
  }
}

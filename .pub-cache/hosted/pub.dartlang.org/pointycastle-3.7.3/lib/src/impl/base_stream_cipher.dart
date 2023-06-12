// See file LICENSE for more information.

library src.impl.base_stream_cipher;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base implementation of [StreamCipher] which provides shared methods.
abstract class BaseStreamCipher implements StreamCipher {
  @override
  Uint8List process(Uint8List data) {
    var out = Uint8List(data.length);
    processBytes(data, 0, data.length, out, 0);
    return out;
  }
}

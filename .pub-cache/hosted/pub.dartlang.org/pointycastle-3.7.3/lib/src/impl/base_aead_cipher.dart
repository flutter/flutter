library src.impl.base_aead_cipher;

import 'dart:typed_data';

import '../../api.dart';

abstract class BaseAEADCipher implements AEADCipher {
  Uint8List process(Uint8List data) {
    var out = Uint8List(data.length);
    processBytes(data, 0, data.length, out, 0);
    return out;
  }
}

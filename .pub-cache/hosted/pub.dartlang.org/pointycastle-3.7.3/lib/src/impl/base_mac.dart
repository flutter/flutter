// See file LICENSE for more information.

library src.impl.base_mac;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base implementation of [Mac] which provides shared methods.
abstract class BaseMac implements Mac {
  @override
  Uint8List process(Uint8List data) {
    update(data, 0, data.length);
    var out = Uint8List(macSize);
    var len = doFinal(out, 0);
    return out.sublist(0, len);
  }
}

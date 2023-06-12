// See file LICENSE for more information.

library src.impl.base_padding;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base implementation of [Padding] which provides shared methods.
abstract class BasePadding implements Padding {
  @override
  Uint8List process(bool pad, Uint8List data) {
    if (pad) {
      var out = Uint8List.fromList(data);
      return out;
    } else {
      var len = padCount(data);
      return Uint8List.fromList(data.sublist(0, len));
    }
  }
}

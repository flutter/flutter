// See file LICENSE for more information.

library src.impl.base_padding;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base implementation of [Padding] which provides shared methods.
abstract class BasePadding implements Padding {
  @override
  Uint8List process(bool pad, Uint8List data) {
    if (pad) {
      throw StateError(
          'cannot add padding, use PaddedBlockCipher to add padding');
    } else {
      var len = padCount(data);
      return data.sublist(0, data.length - len);
    }
  }
}

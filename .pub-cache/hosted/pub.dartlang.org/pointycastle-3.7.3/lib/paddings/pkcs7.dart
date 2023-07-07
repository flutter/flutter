// See file LICENSE for more information.

library impl.padding.pkcs7;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_padding.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// A [Padding] that adds PKCS7/PKCS5 padding to a block.
class PKCS7Padding extends BasePadding {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Padding, 'PKCS7', () => PKCS7Padding());

  @override
  String get algorithmName => 'PKCS7';

  @override
  void init([CipherParameters? params]) {
    // nothing to do.
  }

  @override
  int addPadding(Uint8List data, int offset) {
    var code = (data.length - offset);

    while (offset < data.length) {
      data[offset] = code;
      offset++;
    }

    return code;
  }

  @override
  int padCount(Uint8List data) {
    var count = clip8(data[data.length - 1]);

    if (count > data.length || count == 0) {
      throw ArgumentError('Invalid or corrupted pad block');
    }

    for (var i = 1; i <= count; i++) {
      if (data[data.length - i] != count) {
        throw ArgumentError('Invalid or corrupted pad block');
      }
    }

    return count;
  }
}

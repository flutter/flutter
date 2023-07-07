// See file LICENSE for more information.

library impl.padding.iso7816d4;

import 'dart:typed_data' show Uint8List;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_padding.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// A padder that adds the padding according to the scheme referenced in
/// ISO 7814-4 - scheme 2 from ISO 9797-1. The first byte is 0x80, rest is 0x00
class ISO7816d4Padding extends BasePadding {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Padding, 'ISO7816-4', () => ISO7816d4Padding());

  @override
  String get algorithmName => 'ISO7816-4';

  @override
  void init([CipherParameters? params]) {
    // nothing to do.
  }

  /// add the pad bytes to the passed in block, returning the
  /// number of bytes added.
  @override
  int addPadding(Uint8List data, int offset) {
    var added = (data.length - offset);

    data[offset] = 0x80;
    offset++;

    while (offset < data.length) {
      data[offset] = 0;
      offset++;
    }

    return added;
  }

  /// return the number of pad bytes present in the block.
  @override
  int padCount(Uint8List data) {
    var count = data.length - 1;

    while (count > 0 && data[count] == 0) {
      count--;
    }

    if (data[count] != 0x80) {
      throw ArgumentError('pad block corrupted');
    }

    return data.length - count;
  }
}

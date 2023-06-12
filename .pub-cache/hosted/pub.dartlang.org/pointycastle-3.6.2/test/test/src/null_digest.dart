// See file LICENSE for more information.

library impl.block_chipher.test.src.null_digest;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// An implementation of a null [Digest], that is, a digest that returns an empty string. It can be
/// used for testing or benchmarking chaining algorithms.
class NullDigest extends BaseDigest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'Null', () => NullDigest());

  @override
  final int digestSize;

  NullDigest([this.digestSize = 32]);
  @override
  final String algorithmName = 'Null';
  @override
  void reset() {}
  @override
  void updateByte(int inp) {}
  @override
  void update(Uint8List? inp, int inpOff, int? len) {}
  @override
  int doFinal(Uint8List? out, int? outOff) {
    out!.fillRange(0, digestSize, 0);
    return digestSize;
  }

  @override
  // TODO: implement byteLength
  int get byteLength => throw UnimplementedError();
}

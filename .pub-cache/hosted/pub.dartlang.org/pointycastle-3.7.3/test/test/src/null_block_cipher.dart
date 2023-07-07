// See file LICENSE for more information.

library impl.block_cipher.test.src.null_block_cipher;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_block_cipher.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// An implementation of a null [BlockCipher], that is, a cipher that does not encrypt, neither decrypt. It can be used for
/// testing or benchmarking chaining algorithms.
class NullBlockCipher extends BaseBlockCipher {
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
      BlockCipher, r'^Null(?:-([0-9]+))?$', (_, Match match) {
    final blockSize = match.group(1) == null ? 16 : int.parse(match.group(1)!);
    return () => NullBlockCipher(blockSize);
  });

  @override
  final int blockSize;

  NullBlockCipher([this.blockSize = 16]);

  @override
  String get algorithmName => 'Null';

  @override
  void reset() {}

  @override
  void init(bool forEncryption, CipherParameters? params) {}

  @override
  int processBlock(Uint8List? inp, int inpOff, Uint8List? out, int outOff) {
    out!.setRange(outOff, outOff + blockSize, inp!.sublist(inpOff));
    return blockSize;
  }
}

// See file LICENSE for more information.

library impl.asymmetric_block_cipher.test.null_asymmetric_block_cipher;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_asymmetric_block_cipher.dart';

/// An implementation of a null [AsymmetricBlockCipher], that is, a cipher that does not encrypt, neither decrypt. It can be used
/// for testing or benchmarking chaining algorithms.
class NullAsymmetricBlockCipher extends BaseAsymmetricBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
    AsymmetricBlockCipher,
    r'^Null$',
    (s, m) => () {
      return NullAsymmetricBlockCipher(70, 70);
    },
  );

  @override
  final int inputBlockSize;
  @override
  final int outputBlockSize;

  NullAsymmetricBlockCipher(this.inputBlockSize, this.outputBlockSize);

  @override
  String get algorithmName => 'Null';

  @override
  void reset() {}

  @override
  void init(bool forEncryption, CipherParameters params) {}

  @override
  int processBlock(
      Uint8List? inp, int inpOff, int len, Uint8List out, int outOff) {
    out.setRange(outOff, outOff + len, inp!.sublist(inpOff));
    return len;
  }
}

class NullAsymmetricKey implements AsymmetricKey {}

class NullPublicKey extends NullAsymmetricKey implements PublicKey {}

class NullPrivateKey extends NullAsymmetricKey implements PrivateKey {}

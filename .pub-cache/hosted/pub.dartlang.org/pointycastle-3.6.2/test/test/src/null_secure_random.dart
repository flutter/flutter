// See file LICENSE for more information.

library impl.secure_random.test.src.null_secure_random;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/secure_random_base.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// An implementation of [SecureRandom] that return numbers in growing sequence.
class NullSecureRandom extends SecureRandomBase {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(SecureRandom, 'Null', () => NullSecureRandom());

  var _nextValue = 0;
  @override
  String get algorithmName => 'Null';
  @override
  void seed(CipherParameters params) {}
  @override
  int nextUint8() => clip8(_nextValue++);
}

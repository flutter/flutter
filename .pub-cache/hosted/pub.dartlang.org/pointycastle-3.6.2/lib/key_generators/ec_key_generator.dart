// See file LICENSE for more information.

library impl.key_generator.ec_key_generator;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Abstract [CipherParameters] to init an ECC key generator.
class ECKeyGenerator implements KeyGenerator {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(KeyGenerator, 'EC', () => ECKeyGenerator());

  late ECDomainParameters _params;
  late SecureRandom _random;

  @override
  String get algorithmName => 'EC';

  @override
  void init(CipherParameters params) {
    ECKeyGeneratorParameters ecparams;

    if (params is ParametersWithRandom) {
      _random = params.random;
      ecparams = params.parameters as ECKeyGeneratorParameters;
    } else {
      _random = SecureRandom();
      ecparams = params as ECKeyGeneratorParameters;
    }

    _params = ecparams.domainParameters;
  }

  @override
  AsymmetricKeyPair generateKeyPair() {
    var n = _params.n;
    var nBitLength = n.bitLength;
    BigInt? d;

    do {
      d = _random.nextBigInteger(nBitLength);
    } while (d == BigInt.zero || (d >= n));

    var Q = _params.G * d;

    return AsymmetricKeyPair(ECPublicKey(Q, _params), ECPrivateKey(d, _params));
  }
}

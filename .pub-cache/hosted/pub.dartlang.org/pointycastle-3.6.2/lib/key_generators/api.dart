// See file LICENSE for more information.

library api.key_generators;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';

/// Abstract [CipherParameters] to init an ECC key generator.
class ECKeyGeneratorParameters extends KeyGeneratorParameters {
  final ECDomainParameters _domainParameters;

  ECKeyGeneratorParameters(ECDomainParameters domainParameters)
      : _domainParameters = domainParameters,
        super(domainParameters.n.bitLength);

  ECDomainParameters get domainParameters => _domainParameters;
}

/// Abstract [CipherParameters] to init an RSA key generator.
class RSAKeyGeneratorParameters extends KeyGeneratorParameters {
  final BigInt publicExponent;
  final int certainty;

  RSAKeyGeneratorParameters(
      this.publicExponent, int bitStrength, this.certainty)
      : super(bitStrength);
}

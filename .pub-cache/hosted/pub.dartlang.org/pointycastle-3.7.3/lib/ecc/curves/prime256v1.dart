// See file LICENSE for more information.

library impl.ec_domain_parameters.prime256v1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_prime256v1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'prime256v1', () => ECCurve_prime256v1());

  factory ECCurve_prime256v1() => constructFpStandardCurve(
      'prime256v1', ECCurve_prime256v1._make,
      q: BigInt.parse('ffffffff00000001000000000000000000000000ffffffffffffffffffffffff',
          radix: 16),
      a: BigInt.parse(
          'ffffffff00000001000000000000000000000000fffffffffffffffffffffffc',
          radix: 16),
      b: BigInt.parse(
          '5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b',
          radix: 16),
      g: BigInt.parse(
          '036b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
          radix: 16),
      n: BigInt.parse(
          'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: BigInt.parse('c49d360886e704936a6678e1139d26b7819f7e90',
          radix: 16)) as ECCurve_prime256v1;

  static ECCurve_prime256v1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_prime256v1._super(domainName, curve, G, n, _h, seed);

  ECCurve_prime256v1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

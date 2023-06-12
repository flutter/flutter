// See file LICENSE for more information.

library impl.ec_domain_parameters.secp128r1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp128r1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp128r1', () => ECCurve_secp128r1());

  factory ECCurve_secp128r1() => constructFpStandardCurve(
      'secp128r1', ECCurve_secp128r1._make,
      q: BigInt.parse('fffffffdffffffffffffffffffffffff', radix: 16),
      a: BigInt.parse('fffffffdfffffffffffffffffffffffc', radix: 16),
      b: BigInt.parse('e87579c11079f43dd824993c2cee5ed3', radix: 16),
      g: BigInt.parse(
          '04161ff7528b899b2d0c28607ca52c5b86cf5ac8395bafeb13c02da292dded7a83',
          radix: 16),
      n: BigInt.parse('fffffffe0000000075a30d1b9038a115', radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: BigInt.parse('000e0d4d696e6768756151750cc03a4473d03679',
          radix: 16)) as ECCurve_secp128r1;

  static ECCurve_secp128r1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_secp128r1._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp128r1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

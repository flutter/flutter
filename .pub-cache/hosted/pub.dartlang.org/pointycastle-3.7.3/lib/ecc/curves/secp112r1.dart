// See file LICENSE for more information.

library impl.ec_domain_parameters.secp112r1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp112r1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp112r1', () => ECCurve_secp112r1());

  factory ECCurve_secp112r1() =>
      constructFpStandardCurve('secp112r1', ECCurve_secp112r1._make,
          q: BigInt.parse('db7c2abf62e35e668076bead208b', radix: 16),
          a: BigInt.parse('db7c2abf62e35e668076bead2088', radix: 16),
          b: BigInt.parse('659ef8ba043916eede8911702b22', radix: 16),
          g: BigInt.parse(
              '0409487239995a5ee76b55f9c2f098a89ce5af8724c0a23e0e0ff77500',
              radix: 16),
          n: BigInt.parse('db7c2abf62e35e7628dfac6561c5', radix: 16),
          h: BigInt.parse('1', radix: 16),
          seed: BigInt.parse('00f50b028e4d696e676875615175290472783fb1',
              radix: 16)) as ECCurve_secp112r1;

  static ECCurve_secp112r1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_secp112r1._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp112r1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

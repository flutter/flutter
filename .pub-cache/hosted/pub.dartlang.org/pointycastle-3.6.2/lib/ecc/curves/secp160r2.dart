// See file LICENSE for more information.

library impl.ec_domain_parameters.secp160r2;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp160r2 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp160r2', () => ECCurve_secp160r2());

  factory ECCurve_secp160r2() => constructFpStandardCurve(
      'secp160r2', ECCurve_secp160r2._make,
      q: BigInt.parse('fffffffffffffffffffffffffffffffeffffac73', radix: 16),
      a: BigInt.parse('fffffffffffffffffffffffffffffffeffffac70', radix: 16),
      b: BigInt.parse('b4e134d3fb59eb8bab57274904664d5af50388ba', radix: 16),
      g: BigInt.parse(
          '0452dcb034293a117e1f4ff11b30f7199d3144ce6dfeaffef2e331f296e071fa0df9982cfea7d43f2e',
          radix: 16),
      n: BigInt.parse('100000000000000000000351ee786a818f3a1a16b', radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: BigInt.parse('b99b99b099b323e02709a4d696e6768756151751',
          radix: 16)) as ECCurve_secp160r2;

  static ECCurve_secp160r2 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_secp160r2._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp160r2._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

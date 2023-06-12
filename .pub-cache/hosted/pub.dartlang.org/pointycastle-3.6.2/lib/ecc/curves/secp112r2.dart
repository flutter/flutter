// See file LICENSE for more information.

library impl.ec_domain_parameters.secp112r2;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp112r2 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp112r2', () => ECCurve_secp112r2());

  factory ECCurve_secp112r2() =>
      constructFpStandardCurve('secp112r2', ECCurve_secp112r2._make,
          q: BigInt.parse('db7c2abf62e35e668076bead208b', radix: 16),
          a: BigInt.parse('6127c24c05f38a0aaaf65c0ef02c', radix: 16),
          b: BigInt.parse('51def1815db5ed74fcc34c85d709', radix: 16),
          g: BigInt.parse(
              '044ba30ab5e892b4e1649dd0928643adcd46f5882e3747def36e956e97',
              radix: 16),
          n: BigInt.parse('36df0aafd8b8d7597ca10520d04b', radix: 16),
          h: BigInt.parse('4', radix: 16),
          seed: BigInt.parse('002757a1114d696e6768756151755316c05e0bd4',
              radix: 16)) as ECCurve_secp112r2;

  static ECCurve_secp112r2 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_secp112r2._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp112r2._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

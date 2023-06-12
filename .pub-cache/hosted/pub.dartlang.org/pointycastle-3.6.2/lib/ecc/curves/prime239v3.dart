// See file LICENSE for more information.

library impl.ec_domain_parameters.prime239v3;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_prime239v3 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'prime239v3', () => ECCurve_prime239v3());

  factory ECCurve_prime239v3() =>
      constructFpStandardCurve('prime239v3', ECCurve_prime239v3._make,
          q: BigInt.parse(
              '7fffffffffffffffffffffff7fffffffffff8000000000007fffffffffff',
              radix: 16),
          a: BigInt.parse(
              '7fffffffffffffffffffffff7fffffffffff8000000000007ffffffffffc',
              radix: 16),
          b: BigInt.parse(
              '255705fa2a306654b1f4cb03d6a750a30c250102d4988717d9ba15ab6d3e',
              radix: 16),
          g: BigInt.parse(
              '036768ae8e18bb92cfcf005c949aa2c6d94853d0e660bbf854b1c9505fe95a',
              radix: 16),
          n: BigInt.parse(
              '7fffffffffffffffffffffff7fffff975deb41b3a6057c3c432146526551',
              radix: 16),
          h: BigInt.parse('1', radix: 16),
          seed: BigInt.parse('7d7374168ffe3471b60a857686a19475d3bfa2ff',
              radix: 16)) as ECCurve_prime239v3;

  static ECCurve_prime239v3 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_prime239v3._super(domainName, curve, G, n, _h, seed);

  ECCurve_prime239v3._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

// See file LICENSE for more information.

library impl.ec_domain_parameters.brainpoolp160r1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_brainpoolp160r1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'brainpoolp160r1', () => ECCurve_brainpoolp160r1());

  factory ECCurve_brainpoolp160r1() => constructFpStandardCurve(
      'brainpoolp160r1', ECCurve_brainpoolp160r1._make,
      q: BigInt.parse('e95e4a5f737059dc60dfc7ad95b3d8139515620f', radix: 16),
      a: BigInt.parse('340e7be2a280eb74e2be61bada745d97e8f7c300', radix: 16),
      b: BigInt.parse('1e589a8595423412134faa2dbdec95c8d8675e58', radix: 16),
      g: BigInt.parse(
          '04bed5af16ea3f6a4f62938c4631eb5af7bdbcdbc31667cb477a1a8ec338f94741669c976316da6321',
          radix: 16),
      n: BigInt.parse('e95e4a5f737059dc60df5991d45029409e60fc09', radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_brainpoolp160r1;

  static ECCurve_brainpoolp160r1 _make(String domainName, ECCurve curve,
          ECPoint G, BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_brainpoolp160r1._super(domainName, curve, G, n, _h, seed);

  ECCurve_brainpoolp160r1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

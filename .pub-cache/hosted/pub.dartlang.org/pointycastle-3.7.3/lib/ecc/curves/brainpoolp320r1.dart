// See file LICENSE for more information.

library impl.ec_domain_parameters.brainpoolp320r1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_brainpoolp320r1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'brainpoolp320r1', () => ECCurve_brainpoolp320r1());

  factory ECCurve_brainpoolp320r1() => constructFpStandardCurve(
      'brainpoolp320r1', ECCurve_brainpoolp320r1._make,
      q: BigInt.parse(
          'd35e472036bc4fb7e13c785ed201e065f98fcfa6f6f40def4f92b9ec7893ec28fcd412b1f1b32e27',
          radix: 16),
      a: BigInt.parse(
          '3ee30b568fbab0f883ccebd46d3f3bb8a2a73513f5eb79da66190eb085ffa9f492f375a97d860eb4',
          radix: 16),
      b: BigInt.parse(
          '520883949dfdbc42d3ad198640688a6fe13f41349554b49acc31dccd884539816f5eb4ac8fb1f1a6',
          radix: 16),
      g: BigInt.parse(
          '0443bd7e9afb53d8b85289bcc48ee5bfe6f20137d10a087eb6e7871e2a10a599c710af8d0d39e2061114fdd05545ec1cc8ab4093247f77275e0743ffed117182eaa9c77877aaac6ac7d35245d1692e8ee1',
          radix: 16),
      n: BigInt.parse(
          'd35e472036bc4fb7e13c785ed201e065f98fcfa5b68f12a32d482ec7ee8658e98691555b44c59311',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_brainpoolp320r1;

  static ECCurve_brainpoolp320r1 _make(String domainName, ECCurve curve,
          ECPoint G, BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_brainpoolp320r1._super(domainName, curve, G, n, _h, seed);

  ECCurve_brainpoolp320r1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

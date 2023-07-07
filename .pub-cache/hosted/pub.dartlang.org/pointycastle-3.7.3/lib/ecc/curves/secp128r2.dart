// See file LICENSE for more information.

library impl.ec_domain_parameters.secp128r2;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp128r2 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp128r2', () => ECCurve_secp128r2());

  factory ECCurve_secp128r2() => constructFpStandardCurve(
      'secp128r2', ECCurve_secp128r2._make,
      q: BigInt.parse('fffffffdffffffffffffffffffffffff', radix: 16),
      a: BigInt.parse('d6031998d1b3bbfebf59cc9bbff9aee1', radix: 16),
      b: BigInt.parse('5eeefca380d02919dc2c6558bb6d8a5d', radix: 16),
      g: BigInt.parse(
          '047b6aa5d85e572983e6fb32a7cdebc14027b6916a894d3aee7106fe805fc34b44',
          radix: 16),
      n: BigInt.parse('3fffffff7fffffffbe0024720613b5a3', radix: 16),
      h: BigInt.parse('4', radix: 16),
      seed: BigInt.parse('004d696e67687561517512d8f03431fce63b88f4',
          radix: 16)) as ECCurve_secp128r2;

  static ECCurve_secp128r2 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_secp128r2._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp128r2._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

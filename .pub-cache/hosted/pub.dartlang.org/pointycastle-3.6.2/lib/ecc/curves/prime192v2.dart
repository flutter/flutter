// See file LICENSE for more information.

library impl.ec_domain_parameters.prime192v2;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_prime192v2 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'prime192v2', () => ECCurve_prime192v2());

  factory ECCurve_prime192v2() =>
      constructFpStandardCurve('prime192v2', ECCurve_prime192v2._make,
          q: BigInt.parse('fffffffffffffffffffffffffffffffeffffffffffffffff',
              radix: 16),
          a: BigInt.parse('fffffffffffffffffffffffffffffffefffffffffffffffc',
              radix: 16),
          b: BigInt.parse('cc22d6dfb95c6b25e49c0d6364a4e5980c393aa21668d953',
              radix: 16),
          g: BigInt.parse('03eea2bae7e1497842f2de7769cfe9c989c072ad696f48034a',
              radix: 16),
          n: BigInt.parse('fffffffffffffffffffffffe5fb1a724dc80418648d8dd31',
              radix: 16),
          h: BigInt.parse('1', radix: 16),
          seed: BigInt.parse('31a92ee2029fd10d901b113e990710f0d21ac6b6',
              radix: 16)) as ECCurve_prime192v2;

  static ECCurve_prime192v2 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_prime192v2._super(domainName, curve, G, n, _h, seed);

  ECCurve_prime192v2._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

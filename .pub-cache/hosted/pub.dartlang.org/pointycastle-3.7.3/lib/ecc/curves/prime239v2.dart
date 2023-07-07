// See file LICENSE for more information.

library impl.ec_domain_parameters.prime239v2;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_prime239v2 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'prime239v2', () => ECCurve_prime239v2());

  factory ECCurve_prime239v2() =>
      constructFpStandardCurve('prime239v2', ECCurve_prime239v2._make,
          q: BigInt.parse(
              '7fffffffffffffffffffffff7fffffffffff8000000000007fffffffffff',
              radix: 16),
          a: BigInt.parse(
              '7fffffffffffffffffffffff7fffffffffff8000000000007ffffffffffc',
              radix: 16),
          b: BigInt.parse(
              '617fab6832576cbbfed50d99f0249c3fee58b94ba0038c7ae84c8c832f2c',
              radix: 16),
          g: BigInt.parse(
              '0238af09d98727705120c921bb5e9e26296a3cdcf2f35757a0eafd87b830e7',
              radix: 16),
          n: BigInt.parse(
              '7fffffffffffffffffffffff800000cfa7e8594377d414c03821bc582063',
              radix: 16),
          h: BigInt.parse('1', radix: 16),
          seed: BigInt.parse('e8b4011604095303ca3b8099982be09fcb9ae616',
              radix: 16)) as ECCurve_prime239v2;

  static ECCurve_prime239v2 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_prime239v2._super(domainName, curve, G, n, _h, seed);

  ECCurve_prime239v2._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

// See file LICENSE for more information.

library impl.ec_domain_parameters.prime192v1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_prime192v1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'prime192v1', () => ECCurve_prime192v1());

  factory ECCurve_prime192v1() =>
      constructFpStandardCurve('prime192v1', ECCurve_prime192v1._make,
          q: BigInt.parse('fffffffffffffffffffffffffffffffeffffffffffffffff',
              radix: 16),
          a: BigInt.parse('fffffffffffffffffffffffffffffffefffffffffffffffc',
              radix: 16),
          b: BigInt.parse('64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1',
              radix: 16),
          g: BigInt.parse('03188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012',
              radix: 16),
          n: BigInt.parse('ffffffffffffffffffffffff99def836146bc9b1b4d22831',
              radix: 16),
          h: BigInt.parse('1', radix: 16),
          seed: BigInt.parse('3045ae6fc8422f64ed579528d38120eae12196d5',
              radix: 16)) as ECCurve_prime192v1;

  static ECCurve_prime192v1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_prime192v1._super(domainName, curve, G, n, _h, seed);

  ECCurve_prime192v1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

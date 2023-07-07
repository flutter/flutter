// See file LICENSE for more information.

library impl.ec_domain_parameters.secp384r1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp384r1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp384r1', () => ECCurve_secp384r1());

  factory ECCurve_secp384r1() => constructFpStandardCurve(
      'secp384r1', ECCurve_secp384r1._make,
      q: BigInt.parse('fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff',
          radix: 16),
      a: BigInt.parse(
          'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc',
          radix: 16),
      b: BigInt.parse(
          'b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef',
          radix: 16),
      g: BigInt.parse(
          '04aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab73617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f',
          radix: 16),
      n: BigInt.parse(
          'ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: BigInt.parse('a335926aa319a27a1d00896a6773a4827acdac73',
          radix: 16)) as ECCurve_secp384r1;

  static ECCurve_secp384r1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_secp384r1._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp384r1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

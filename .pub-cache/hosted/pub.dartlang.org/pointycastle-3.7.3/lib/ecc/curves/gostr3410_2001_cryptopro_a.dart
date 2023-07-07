// See file LICENSE for more information.

library impl.ec_domain_parameters.gostr3410_2001_cryptopro_a;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_gostr3410_2001_cryptopro_a extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters,
      'GostR3410-2001-CryptoPro-A',
      () => ECCurve_gostr3410_2001_cryptopro_a());

  factory ECCurve_gostr3410_2001_cryptopro_a() => constructFpStandardCurve(
      'GostR3410-2001-CryptoPro-A', ECCurve_gostr3410_2001_cryptopro_a._make,
      q: BigInt.parse(
          'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd97',
          radix: 16),
      a: BigInt.parse(
          'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd94',
          radix: 16),
      b: BigInt.parse('a6', radix: 16),
      g: BigInt.parse(
          '0400000000000000000000000000000000000000000000000000000000000000018d91e471e0989cda27df505a453f2b7635294f2ddf23e3b122acc99c9e9f1e14',
          radix: 16),
      n: BigInt.parse(
          'ffffffffffffffffffffffffffffffff6c611070995ad10045841b09b761b893',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_gostr3410_2001_cryptopro_a;

  static ECCurve_gostr3410_2001_cryptopro_a _make(String domainName,
          ECCurve curve, ECPoint G, BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_gostr3410_2001_cryptopro_a._super(
          domainName, curve, G, n, _h, seed);

  ECCurve_gostr3410_2001_cryptopro_a._super(String domainName, ECCurve curve,
      ECPoint G, BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

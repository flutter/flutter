// See file LICENSE for more information.

library impl.ec_domain_parameters.secp256k1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp256k1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp256k1', () => ECCurve_secp256k1());

  factory ECCurve_secp256k1() => constructFpStandardCurve(
      'secp256k1', ECCurve_secp256k1._make,
      q: BigInt.parse(
          'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f',
          radix: 16),
      a: BigInt.parse('0', radix: 16),
      b: BigInt.parse('7', radix: 16),
      g: BigInt.parse(
          '0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8',
          radix: 16),
      n: BigInt.parse(
          'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_secp256k1;

  static ECCurve_secp256k1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_secp256k1._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp256k1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

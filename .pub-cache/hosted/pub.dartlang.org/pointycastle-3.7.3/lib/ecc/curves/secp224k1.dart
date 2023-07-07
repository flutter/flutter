// See file LICENSE for more information.

library impl.ec_domain_parameters.secp224k1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp224k1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp224k1', () => ECCurve_secp224k1());

  factory ECCurve_secp224k1() => constructFpStandardCurve(
      'secp224k1', ECCurve_secp224k1._make,
      q: BigInt.parse(
          'fffffffffffffffffffffffffffffffffffffffffffffffeffffe56d',
          radix: 16),
      a: BigInt.parse('0', radix: 16),
      b: BigInt.parse('5', radix: 16),
      g: BigInt.parse(
          '04a1455b334df099df30fc28a169a467e9e47075a90f7e650eb6b7a45c7e089fed7fba344282cafbd6f7e319f7c0b0bd59e2ca4bdb556d61a5',
          radix: 16),
      n: BigInt.parse(
          '10000000000000000000000000001dce8d2ec6184caf0a971769fb1f7',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_secp224k1;

  static ECCurve_secp224k1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_secp224k1._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp224k1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

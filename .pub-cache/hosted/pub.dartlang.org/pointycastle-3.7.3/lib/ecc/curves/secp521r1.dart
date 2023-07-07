// See file LICENSE for more information.

library impl.ec_domain_parameters.secp521r1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_secp521r1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'secp521r1', () => ECCurve_secp521r1());

  factory ECCurve_secp521r1() => constructFpStandardCurve(
      'secp521r1', ECCurve_secp521r1._make,
      q: BigInt.parse('1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          radix: 16),
      a: BigInt.parse(
          '1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc',
          radix: 16),
      b: BigInt.parse(
          '51953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00',
          radix: 16),
      g: BigInt.parse(
          '0400c6858e06b70404e9cd9e3ecb662395b4429c648139053fb521f828af606b4d3dbaa14b5e77efe75928fe1dc127a2ffa8de3348b3c1856a429bf97e7e31c2e5bd66011839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e662c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650',
          radix: 16),
      n: BigInt.parse(
          '1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa51868783bf2f966b7fcc0148f709a5d03bb5c9b8899c47aebb6fb71e91386409',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: BigInt.parse('d09e8800291cb85396cc6717393284aaa0da64ba',
          radix: 16)) as ECCurve_secp521r1;

  static ECCurve_secp521r1 _make(String domainName, ECCurve curve, ECPoint G,
          BigInt n, BigInt _h, List<int> seed) =>
      ECCurve_secp521r1._super(domainName, curve, G, n, _h, seed);

  ECCurve_secp521r1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int> seed)
      : super(domainName, curve, G, n, _h, seed);
}

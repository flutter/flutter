// See file LICENSE for more information.

library impl.ec_domain_parameters.brainpoolp384t1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_brainpoolp384t1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'brainpoolp384t1', () => ECCurve_brainpoolp384t1());

  factory ECCurve_brainpoolp384t1() => constructFpStandardCurve(
      'brainpoolp384t1', ECCurve_brainpoolp384t1._make,
      q: BigInt.parse(
          '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec53',
          radix: 16),
      a: BigInt.parse(
          '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec50',
          radix: 16),
      b: BigInt.parse(
          '7f519eada7bda81bd826dba647910f8c4b9346ed8ccdc64e4b1abd11756dce1d2074aa263b88805ced70355a33b471ee',
          radix: 16),
      g: BigInt.parse(
          '0418de98b02db9a306f2afcd7235f72a819b80ab12ebd653172476fecd462aabffc4ff191b946a5f54d8d0aa2f418808cc25ab056962d30651a114afd2755ad336747f93475b7a1fca3b88f2b6a208ccfe469408584dc2b2912675bf5b9e582928',
          radix: 16),
      n: BigInt.parse(
          '8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b31f166e6cac0425a7cf3ab6af6b7fc3103b883202e9046565',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_brainpoolp384t1;

  static ECCurve_brainpoolp384t1 _make(String domainName, ECCurve curve,
          ECPoint G, BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_brainpoolp384t1._super(domainName, curve, G, n, _h, seed);

  ECCurve_brainpoolp384t1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

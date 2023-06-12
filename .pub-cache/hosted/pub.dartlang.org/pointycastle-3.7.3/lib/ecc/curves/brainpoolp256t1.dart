// See file LICENSE for more information.

library impl.ec_domain_parameters.brainpoolp256t1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_brainpoolp256t1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'brainpoolp256t1', () => ECCurve_brainpoolp256t1());

  factory ECCurve_brainpoolp256t1() => constructFpStandardCurve(
      'brainpoolp256t1', ECCurve_brainpoolp256t1._make,
      q: BigInt.parse(
          'a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377',
          radix: 16),
      a: BigInt.parse(
          'a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5374',
          radix: 16),
      b: BigInt.parse(
          '662c61c430d84ea4fe66a7733d0b76b7bf93ebc4af2f49256ae58101fee92b04',
          radix: 16),
      g: BigInt.parse(
          '04a3e8eb3cc1cfe7b7732213b23a656149afa142c47aafbc2b79a191562e1305f42d996c823439c56d7f7b22e14644417e69bcb6de39d027001dabe8f35b25c9be',
          radix: 16),
      n: BigInt.parse(
          'a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_brainpoolp256t1;

  static ECCurve_brainpoolp256t1 _make(String domainName, ECCurve curve,
          ECPoint G, BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_brainpoolp256t1._super(domainName, curve, G, n, _h, seed);

  ECCurve_brainpoolp256t1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

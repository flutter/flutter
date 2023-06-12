// See file LICENSE for more information.

library impl.ec_domain_parameters.brainpoolp256r1;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/ec_standard_curve_constructor.dart';
import 'package:pointycastle/src/registry/registry.dart';

// ignore: camel_case_types
class ECCurve_brainpoolp256r1 extends ECDomainParametersImpl {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      ECDomainParameters, 'brainpoolp256r1', () => ECCurve_brainpoolp256r1());

  factory ECCurve_brainpoolp256r1() => constructFpStandardCurve(
      'brainpoolp256r1', ECCurve_brainpoolp256r1._make,
      q: BigInt.parse(
          'a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377',
          radix: 16),
      a: BigInt.parse(
          '7d5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9',
          radix: 16),
      b: BigInt.parse(
          '26dc5c6ce94a4b44f330b5d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b6',
          radix: 16),
      g: BigInt.parse(
          '048bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262547ef835c3dac4fd97f8461a14611dc9c27745132ded8e545c1d54c72f046997',
          radix: 16),
      n: BigInt.parse(
          'a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7',
          radix: 16),
      h: BigInt.parse('1', radix: 16),
      seed: null) as ECCurve_brainpoolp256r1;

  static ECCurve_brainpoolp256r1 _make(String domainName, ECCurve curve,
          ECPoint G, BigInt n, BigInt _h, List<int>? seed) =>
      ECCurve_brainpoolp256r1._super(domainName, curve, G, n, _h, seed);

  ECCurve_brainpoolp256r1._super(String domainName, ECCurve curve, ECPoint G,
      BigInt n, BigInt _h, List<int>? seed)
      : super(domainName, curve, G, n, _h, seed);
}

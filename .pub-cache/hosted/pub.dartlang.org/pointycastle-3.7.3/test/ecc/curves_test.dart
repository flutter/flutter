import 'package:test/test.dart';
import 'package:pointycastle/export.dart';

void main() {
  group('ECCurve tests', () {
    test('ECCurve constructors', () {
      ECCurve_brainpoolp160r1();
      ECCurve_brainpoolp160t1();
      ECCurve_brainpoolp192r1();
      ECCurve_brainpoolp192t1();
      ECCurve_brainpoolp224r1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();
      ECCurve_brainpoolp224t1();

      ECCurve_gostr3410_2001_cryptopro_a();
      ECCurve_gostr3410_2001_cryptopro_b();
      ECCurve_gostr3410_2001_cryptopro_c();
      ECCurve_gostr3410_2001_cryptopro_xcha();
      ECCurve_gostr3410_2001_cryptopro_xchb();

      ECCurve_prime192v1();
      ECCurve_prime192v2();
      ECCurve_prime192v3();
      ECCurve_prime239v1();
      ECCurve_prime239v2();
      ECCurve_prime239v3();
      ECCurve_prime256v1();

      ECCurve_secp112r1();
      ECCurve_secp112r2();
      ECCurve_secp128r1();
      ECCurve_secp128r2();
      ECCurve_secp160k1();
      ECCurve_secp160r1();
      ECCurve_secp160r2();
      ECCurve_secp192k1();
      ECCurve_secp192r1();
      ECCurve_secp224k1();
      ECCurve_secp224r1();
      ECCurve_secp256k1();
      ECCurve_secp256r1();
      ECCurve_secp384r1();
      ECCurve_secp521r1();
    });
  });
}

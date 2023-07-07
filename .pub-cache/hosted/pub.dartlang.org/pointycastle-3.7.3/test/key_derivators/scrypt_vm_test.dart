// See file LICENSE for more information.

@OnPlatform({
  'chrome': Skip('Excessive time / resource consumption on this platform'),
  'node': Skip('Excessive time / resource consumption on this platform')
})
library test.key_derivators.scrypt_test;

import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/runners/key_derivators.dart';
import '../test/src/helpers.dart';

/// NOTE: the expected results for these tests are taken from the Java library found at
/// [https://github.com/wg/scrypt]. See also
/// [http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-00#page-10] (which at the time of writing
/// this test had typos because it interchanged N and r parameters).
void main() {
  group("scrypt - vm ", () {
    var scrypt = KeyDerivator('scrypt');
    runKeyDerivatorTests(scrypt, [
      ScryptParameters(1024, 8, 16, 64, createUint8ListFromString('NaCl')),
      'password',
      'fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640',
      ScryptParameters(
          16384, 8, 1, 64, createUint8ListFromString('SodiumChloride')),
      'pleaseletmein',
      '7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2d5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887',
      ScryptParameters(
          1048576, 8, 1, 64, createUint8ListFromString('SodiumChloride')),
      'pleaseletmein',
      '2101cb9b6a511aaeaddbbe09cf70f881ec568d574a2ffd4dabe5ee9820adaa478e56fd8f4ba5d09ffa1c6d927c40f4c337304049e8a952fbcbf45c6fa77a41a4',
    ]);
  });
}

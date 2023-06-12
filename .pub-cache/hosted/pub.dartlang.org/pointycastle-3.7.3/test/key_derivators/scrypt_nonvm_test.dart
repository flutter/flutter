// See file LICENSE for more information.

@OnPlatform({
  'vm': Skip(),
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
  //
  // This is a sanity test for the js platform
  //

    var scrypt = KeyDerivator('scrypt');
    runKeyDerivatorTests(scrypt, [
      ScryptParameters(1024, 8, 16, 64, createUint8ListFromString('NaCl')),
      'password',
      'fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640'
    ]);

}

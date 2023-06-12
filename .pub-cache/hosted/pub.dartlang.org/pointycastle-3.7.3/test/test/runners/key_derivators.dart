// See file LICENSE for more information.

library test.test.key_derivators_tests;

import 'package:test/test.dart';
import 'package:pointycastle/pointycastle.dart';

import '../src/helpers.dart';

void runKeyDerivatorTests(
    KeyDerivator keyDerivator, List<dynamic> paramsPasswordKeyTuples) {
  group('${keyDerivator.algorithmName}:', () {
    group('deriveKey:', () {
      for (var i = 0; i < paramsPasswordKeyTuples.length; i += 3) {
        var params = paramsPasswordKeyTuples[i];
        var password = paramsPasswordKeyTuples[i + 1];
        var key = paramsPasswordKeyTuples[i + 2];

        test(
            '${formatAsTruncated(password as String)}',
            () => _runKeyDerivatorTest(keyDerivator, params as CipherParameters,
                password, key as String));
      }
    });
  });
}

void _runKeyDerivatorTest(KeyDerivator keyDerivator, CipherParameters params,
    String password, String expectedHexKey) {
  keyDerivator.init(params);

  var passwordBytes = createUint8ListFromString(password);
  var out = keyDerivator.process(passwordBytes);
  var hexOut = formatBytesAsHexString(out);

  expect(hexOut, equals(expectedHexKey));
}

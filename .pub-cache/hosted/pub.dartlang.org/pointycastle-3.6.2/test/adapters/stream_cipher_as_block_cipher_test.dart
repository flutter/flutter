// See file LICENSE for more information.

library test.adapters.stream_cipher_as_block_cipher_test;

import 'package:test/test.dart';
import 'package:pointycastle/adapters/stream_cipher_as_block_cipher.dart';

import '../test/runners/block_cipher.dart';
import '../test/src/helpers.dart';
import '../test/src/null_stream_cipher.dart';

void main() {
  var cbc = StreamCipherAsBlockCipher(16, NullStreamCipher());
  group('StreamCipherAsBlockCipher:', () {
    runBlockCipherTests(cbc, null, [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
      formatBytesAsHexString(createUint8ListFromString(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........')),
      'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
      formatBytesAsHexString(createUint8ListFromString(
          'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...')),
    ]);
  });
}

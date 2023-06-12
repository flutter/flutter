import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  group('RC2 Engine', () {
    blockCipherTest(
        0,
        RC2Engine(),
        RC2Parameters(createUint8ListFromHexString('0000000000000000'),
            bits: 63),
        '0000000000000000',
        'EBB773F993278EFF');
    blockCipherTest(
        1,
        RC2Engine(),
        RC2Parameters(createUint8ListFromHexString('ffffffffffffffff'),
            bits: 64),
        'ffffffffffffffff',
        '278b27e42e2f0d49');

    blockCipherTest(
        2,
        RC2Engine(),
        RC2Parameters(createUint8ListFromHexString('3000000000000000'),
            bits: 64),
        '1000000000000001',
        '30649edf9be7d2c2');

    blockCipherTest(
        3,
        RC2Engine(),
        RC2Parameters(createUint8ListFromHexString('88'), bits: 64),
        '0000000000000000',
        '61a8a244adacccf0');
    blockCipherTest(
        4,
        RC2Engine(),
        RC2Parameters(createUint8ListFromHexString('88bca90e90875a'), bits: 64),
        '0000000000000000',
        '6ccf4308974c267f');
    blockCipherTest(
        5,
        RC2Engine(),
        RC2Parameters(
            createUint8ListFromHexString('88bca90e90875a7f0f79c384627bafb2'),
            bits: 64),
        '0000000000000000',
        '1a807d272bbe5db1');
    blockCipherTest(
        6,
        RC2Engine(),
        RC2Parameters(
            createUint8ListFromHexString('88bca90e90875a7f0f79c384627bafb2'),
            bits: 128),
        '0000000000000000',
        '2269552ab0f85ca6');
    blockCipherTest(
        7,
        RC2Engine(),
        RC2Parameters(
            createUint8ListFromHexString(
                '88bca90e90875a7f0f79c384627bafb216f80a6f85920584c42fceb0be255daf1e'),
            bits: 129),
        '0000000000000000',
        '5b78d3a43dfff1f1');
  });

  test('test openssl rc2-40-cbc', () {
    // CMD = openssl enc -e -rc2-40-cbc -a -p -nosalt -iv c7d90059b29e97f7 -v
    // Password = test
    // Input = helloworld
    var engine = CBCBlockCipher(RC2Engine());
    engine.reset();

    var params = ParametersWithIV(
      RC2Parameters(
        createUint8ListFromHexString('098F6BCD46'),
        bits: 40,
      ),
      createUint8ListFromHexString('C7D90059B29E97F7'),
    );
    var input = createUint8ListFromHexString('68656c6c6f776f726c64');
    var output = '3MN/S1ipU7V7lOHQGmGW6g==';

    engine.init(true, params);

    var padded = addPKCS7Padding(input, 8);
    final cipherText = Uint8List(padded.length);

    var offset = 0;
    while (offset < padded.length) {
      offset += engine.processBlock(padded, offset, cipherText, offset);
    }

    var out = base64.decode(output);
    expect(cipherText, out);
  });
}

// See file LICENSE for more information.

library test.modes.gcm_test;

import 'dart:typed_data';

import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/ccm.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  var paramList = [
    {
      'name': 'Test Case 1',
      'key': createUint8ListFromHexString('404142434445464748494a4b4c4d4e4f'),
      'iv': createUint8ListFromHexString('10111213141516'),
      'aad': createUint8ListFromHexString('0001020304050607'),
      'input': '20212223',
      'output': '7162015b4dac255d',
      'mac': createUint8ListFromHexString('6084341b'),
      'tl': 32,
    },
    {
      'name': 'Test Case 2',
      'key': createUint8ListFromHexString('404142434445464748494a4b4c4d4e4f'),
      'iv': createUint8ListFromHexString('1011121314151617'),
      'aad': createUint8ListFromHexString('000102030405060708090a0b0c0d0e0f'),
      'input': '202122232425262728292a2b2c2d2e2f',
      'output': 'd2a1f0e051ea5f62081a7792073d593d1fc64fbfaccd',
      'mac': createUint8ListFromHexString('7f479ffca464'),
      'tl': 48
    },
    {
      'name': 'Test Case 3',
      'key': createUint8ListFromHexString('404142434445464748494a4b4c4d4e4f'),
      'iv': createUint8ListFromHexString('101112131415161718191a1b'),
      'aad': createUint8ListFromHexString(
          '000102030405060708090a0b0c0d0e0f10111213'),
      'input': '202122232425262728292a2b2c2d2e2f3031323334353637',
      'output':
          'e3b201a9f5b71a7a9b1ceaeccd97e70b6176aad9a4428aa5484392fbc1b09951',
      'mac': createUint8ListFromHexString('67c99240c7d51048'),
      'tl': 64
    },
  ];

  group('AES-CCM', () {
    for (var map in paramList) {
      test(map['name'], () {
        var encrypter = CCMBlockCipher(AESEngine());
        var params = AEADParameters(
            KeyParameter((map['key'] as Uint8List)),
            map['tl'] as int,
            (map['iv'] as Uint8List),
            (map['aad'] as Uint8List));

        encrypter.init(true, params);
        var result = encrypter
            .process(createUint8ListFromHexString(map['input'] as String));

        expect(
            result,
            orderedEquals(
                createUint8ListFromHexString(map['output'] as String)));
        expect(encrypter.mac, orderedEquals(map['mac'] as Uint8List));

        var decrypter = CCMBlockCipher(AESEngine())..init(false, params);
        var decrypted = formatBytesAsHexString(decrypter.process(result));
        expect(decrypted, map['input']);
      });
    }
  });
}

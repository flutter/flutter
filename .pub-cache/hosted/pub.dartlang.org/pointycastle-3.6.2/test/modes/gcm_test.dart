// See file LICENSE for more information.
@TestOn('vm')
library test.modes.gcm_test;

import 'dart:typed_data';

import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  group('counter regression', () {
    test('4096 byte message', () {
      final aesKey = createUint8ListFromHexString(
          'fecfc5c627a1bcd0e83c495023351e653b58b964d79a75791f691d9620903343');
      final iv =
          createUint8ListFromHexString('72ac336d49b1b8cf01fe0aec3206f524');
      final msg =
          Uint8List.fromList(List.generate(4096, (index) => index % 256));

      final aesCipher = GCMBlockCipher(AESEngine())
        ..init(
            true,
            AEADParameters(
                KeyParameter(aesKey), 128, iv, Uint8List.fromList([])));
      final encrypted = aesCipher.process(msg);

      //
      // Rather than 8kb of cipher text as a hex string. Use a message digest
      // (SHA256) of the expected cipher text result.
      //

      final expectedSHA256 = createUint8ListFromHexString(
          "1679DCC9C8AD4B75BE69BBCABE46D4F32472F48C24595D5280EC5B44E77B3105");

      var dig = SHA256Digest();
      dig.update(encrypted, 0, encrypted.length);
      var calculatedSHA256 = Uint8List(dig.digestSize);
      dig.doFinal(calculatedSHA256, 0);

      expect(calculatedSHA256, equals(expectedSHA256),
          reason: 'digest of cipher text');

      aesCipher.init(
          false,
          AEADParameters(
              KeyParameter(aesKey), 128, iv, Uint8List.fromList([])));

      var decrypted = aesCipher.process(encrypted);

      expect(msg, equals(decrypted), reason: 'decrypted match message');
    });
  });

  var paramList = [
    {
      'name': 'Test Case 1',
      'key': createUint8ListFromHexString('00000000000000000000000000000000'),
      'iv': createUint8ListFromHexString('000000000000000000000000'),
      'aad': createUint8ListFromHexString(''),
      'input': '',
      'output': '',
      'mac': createUint8ListFromHexString('58e2fccefa7e3061367f1d57a4e7455a')
    },
    {
      'name': 'Test Case 2',
      'key': createUint8ListFromHexString('00000000000000000000000000000000'),
      'iv': createUint8ListFromHexString('000000000000000000000000'),
      'aad': createUint8ListFromHexString(''),
      'input': '00000000000000000000000000000000',
      'output': '0388dace60b6a392f328c2b971b2fe78',
      'mac': createUint8ListFromHexString('ab6e47d42cec13bdf53a67b21257bddf')
    },
    {
      'name': 'Test Case 3',
      'key': createUint8ListFromHexString('feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString('cafebabefacedbaddecaf888'),
      'aad': createUint8ListFromHexString(''),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255',
      'output':
      '42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985',
      'mac': createUint8ListFromHexString('4d5c2af327cd64a62cf35abd2ba6fab4')
    },
    {
      'name': 'Test Case 4',
      'key': createUint8ListFromHexString('feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString('cafebabefacedbaddecaf888'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      '42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091',
      'mac': createUint8ListFromHexString('5bc94fbc3221a5db94fae95ae7121a47')
    },
    {
      'name': 'Test Case 5',
      'key': createUint8ListFromHexString('feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString('cafebabefacedbad'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      '61353b4c2806934a777ff51fa22a4755699b2a714fcdc6f83766e5f97b6c742373806900e49f24b22b097544d4896b424989b5e1ebac0f07c23f4598',
      'mac': createUint8ListFromHexString('3612d2e79e3b0785561be14aaca2fccb')
    },
    {
      'name': 'Test Case 6',
      'key': createUint8ListFromHexString('feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString(
          '9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      '8ce24998625615b603a033aca13fb894be9112a5c3a211a8ba262a3cca7e2ca701e4a9a4fba43c90ccdcb281d48c7c6fd62875d2aca417034c34aee5',
      'mac': createUint8ListFromHexString('619cc5aefffe0bfa462af43c1699d050')
    },
    {
      'name': 'Test Case 7',
      'key': createUint8ListFromHexString(
          '000000000000000000000000000000000000000000000000'),
      'iv': createUint8ListFromHexString('000000000000000000000000'),
      'aad': createUint8ListFromHexString(''),
      'input': '',
      'output': '',
      'mac': createUint8ListFromHexString('cd33b28ac773f74ba00ed1f312572435')
    },
    {
      'name': 'Test Case 8',
      'key': createUint8ListFromHexString(
          '000000000000000000000000000000000000000000000000'),
      'iv': createUint8ListFromHexString('000000000000000000000000'),
      'aad': createUint8ListFromHexString(''),
      'input': '00000000000000000000000000000000',
      'output': '98e7247c07f0fe411c267e4384b0f600',
      'mac': createUint8ListFromHexString('2ff58d80033927ab8ef4d4587514f0fb')
    },
    {
      'name': 'Test Case 9',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c'),
      'iv': createUint8ListFromHexString('cafebabefacedbaddecaf888'),
      'aad': createUint8ListFromHexString(''),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255',
      'output':
      '3980ca0b3c00e841eb06fac4872a2757859e1ceaa6efd984628593b40ca1e19c7d773d00c144c525ac619d18c84a3f4718e2448b2fe324d9ccda2710acade256',
      'mac': createUint8ListFromHexString('9924a7c8587336bfb118024db8674a14')
    },
    {
      'name': 'Test Case 10',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c'),
      'iv': createUint8ListFromHexString('cafebabefacedbaddecaf888'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      '3980ca0b3c00e841eb06fac4872a2757859e1ceaa6efd984628593b40ca1e19c7d773d00c144c525ac619d18c84a3f4718e2448b2fe324d9ccda2710',
      'mac': createUint8ListFromHexString('2519498e80f1478f37ba55bd6d27618c')
    },
    {
      'name': 'Test Case 11',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c'),
      'iv': createUint8ListFromHexString('cafebabefacedbad'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      '0f10f599ae14a154ed24b36e25324db8c566632ef2bbb34f8347280fc4507057fddc29df9a471f75c66541d4d4dad1c9e93a19a58e8b473fa0f062f7',
      'mac': createUint8ListFromHexString('65dcc57fcf623a24094fcca40d3533f8')
    },
    {
      'name': 'Test Case 12',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c'),
      'iv': createUint8ListFromHexString(
          '9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      'd27e88681ce3243c4830165a8fdcf9ff1de9a1d8e6b447ef6ef7b79828666e4581e79012af34ddd9e2f037589b292db3e67c036745fa22e7e9b7373b',
      'mac': createUint8ListFromHexString('dcf566ff291c25bbb8568fc3d376a6d9')
    },
    {
      'name': 'Test Case 13',
      'key': createUint8ListFromHexString(
          '0000000000000000000000000000000000000000000000000000000000000000'),
      'iv': createUint8ListFromHexString('000000000000000000000000'),
      'aad': createUint8ListFromHexString(''),
      'input': '',
      'output': '',
      'mac': createUint8ListFromHexString('530f8afbc74536b9a963b4f1c4cb738b')
    },
    {
      'name': 'Test Case 14',
      'key': createUint8ListFromHexString(
          '0000000000000000000000000000000000000000000000000000000000000000'),
      'iv': createUint8ListFromHexString('000000000000000000000000'),
      'aad': createUint8ListFromHexString(''),
      'input': '00000000000000000000000000000000',
      'output': 'cea7403d4d606b6e074ec5d3baf39d18',
      'mac': createUint8ListFromHexString('d0d1c8a799996bf0265b98b5d48ab919')
    },
    {
      'name': 'Test Case 15',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString('cafebabefacedbaddecaf888'),
      'aad': createUint8ListFromHexString(''),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255',
      'output':
      '522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662898015ad',
      'mac': createUint8ListFromHexString('b094dac5d93471bdec1a502270e3cc6c')
    },
    {
      'name': 'Test Case 16',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString('cafebabefacedbaddecaf888'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      '522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662',
      'mac': createUint8ListFromHexString('76fc6ece0f4e1768cddf8853bb2d551b')
    },
    {
      'name': 'Test Case 17',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString('cafebabefacedbad'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      'c3762df1ca787d32ae47c13bf19844cbaf1ae14d0b976afac52ff7d79bba9de0feb582d33934a4f0954cc2363bc73f7862ac430e64abe499f47c9b1f',
      'mac': createUint8ListFromHexString('3a337dbf46a792c45e454913fe2ea8f2')
    },
    {
      'name': 'Test Case 18',
      'key': createUint8ListFromHexString(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308'),
      'iv': createUint8ListFromHexString(
          '9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b'),
      'aad': createUint8ListFromHexString(
          'feedfacedeadbeeffeedfacedeadbeefabaddad2'),
      'input':
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
      'output':
      '5a8def2f0c9e53f1f75d7853659e2a20eeb2b22aafde6419a058ab4f6f746bf40fc0c3b780f244452da3ebf1c5d82cdea2418997200ef82e44ae7e3f',
      'mac': createUint8ListFromHexString('a44a8266ee1c8eb0c8b5d4cf5ae9f19a')
    },
  ];

  group('AES-GCM', () {
    for (var map in paramList) {
      test(map['name'], () {
        var encrypter = GCMBlockCipher(AESEngine());
        var params = AEADParameters(KeyParameter((map['key'] as Uint8List)),
            16 * 8, (map['iv'] as Uint8List), (map['aad'] as Uint8List));
        encrypter.init(true, params);
        var result = encrypter
            .process(createUint8ListFromHexString(map['input'] as String));
        var pos = 0;
        for (var elem
            in createUint8ListFromHexString(map['output'] as String)) {
          expect(elem, result[pos++]);
        }
        pos = 0;
        for (var elem in map['mac'] as Uint8List) {
          expect(elem, encrypter.mac[pos++]);
        }

        var decrypter = GCMBlockCipher(AESEngine())..init(false, params);
        var decrypted = formatBytesAsHexString(decrypter.process(result));
        expect(decrypted, map['input']);
      });
    }
  });
}

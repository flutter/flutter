library test.block.aes_fast_test;

import 'dart:typed_data';

import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  group('AES Engine', () {
    blockCipherTest(0, AESEngine(), kp('80000000000000000000000000000000'),
        '00000000000000000000000000000000', '0EDD33D3C621E546455BD8BA1418BEC8');

    blockCipherTest(1, AESEngine(), kp('00000000000000000000000000000080'),
        '00000000000000000000000000000000', '172AEAB3D507678ECAF455C12587ADB7');

    blockCipherMCTTest(
        2,
        10000,
        AESEngine(),
        kp('00000000000000000000000000000000'),
        '00000000000000000000000000000000',
        'C34C052CC0DA8D73451AFE5F03BE297F');

    blockCipherMCTTest(
        3,
        10000,
        AESEngine(),
        kp('5F060D3716B345C253F6749ABAC10917'),
        '355F697E8B868B65B25A04E18D782AFA',
        'ACC863637868E3E068D2FD6E3508454A');

    blockCipherTest(
        4,
        AESEngine(),
        kp('000000000000000000000000000000000000000000000000'),
        '80000000000000000000000000000000',
        '6CD02513E8D4DC986B4AFE087A60BD0C');

    blockCipherMCTTest(
        5,
        10000,
        AESEngine(),
        kp('AAFE47EE82411A2BF3F6752AE8D7831138F041560631B114'),
        'F3F6752AE8D7831138F041560631B114',
        '77BA00ED5412DFF27C8ED91F3C376172');

    blockCipherTest(
        6,
        AESEngine(),
        kp('0000000000000000000000000000000000000000000000000000000000000000'),
        '80000000000000000000000000000000',
        'DDC6BF790C15760D8D9AEB6F9A75FD4E');

    blockCipherMCTTest(
        7,
        10000,
        AESEngine(),
        kp('28E79E2AFC5F7745FCCABE2F6257C2EF4C4EDFB37324814ED4137C288711A386'),
        'C737317FE0846F132B23C8C2A672CE22',
        'E58B82BFBA53C0040DC610C642121168');

    blockCipherTest(8, AESEngine(), kp('80000000000000000000000000000000'),
        '00000000000000000000000000000000', '0EDD33D3C621E546455BD8BA1418BEC8');

    blockCipherTest(9, AESEngine(), kp('00000000000000000000000000000080'),
        '00000000000000000000000000000000', '172AEAB3D507678ECAF455C12587ADB7');

    blockCipherMCTTest(
        10,
        10000,
        AESEngine(),
        kp('00000000000000000000000000000000'),
        '00000000000000000000000000000000',
        'C34C052CC0DA8D73451AFE5F03BE297F');

    blockCipherMCTTest(
        11,
        10000,
        AESEngine(),
        kp('5F060D3716B345C253F6749ABAC10917'),
        '355F697E8B868B65B25A04E18D782AFA',
        'ACC863637868E3E068D2FD6E3508454A');

    blockCipherTest(
        12,
        AESEngine(),
        kp('000000000000000000000000000000000000000000000000'),
        '80000000000000000000000000000000',
        '6CD02513E8D4DC986B4AFE087A60BD0C');

    blockCipherMCTTest(
        13,
        10000,
        AESEngine(),
        kp('AAFE47EE82411A2BF3F6752AE8D7831138F041560631B114'),
        'F3F6752AE8D7831138F041560631B114',
        '77BA00ED5412DFF27C8ED91F3C376172');

    blockCipherTest(
        14,
        AESEngine(),
        kp('0000000000000000000000000000000000000000000000000000000000000000'),
        '80000000000000000000000000000000',
        'DDC6BF790C15760D8D9AEB6F9A75FD4E');

    blockCipherMCTTest(
        15,
        10000,
        AESEngine(),
        kp('28E79E2AFC5F7745FCCABE2F6257C2EF4C4EDFB37324814ED4137C288711A386'),
        'C737317FE0846F132B23C8C2A672CE22',
        'E58B82BFBA53C0040DC610C642121168');

    blockCipherTest(16, AESEngine(), kp('80000000000000000000000000000000'),
        '00000000000000000000000000000000', '0EDD33D3C621E546455BD8BA1418BEC8');

    blockCipherTest(17, AESEngine(), kp('00000000000000000000000000000080'),
        '00000000000000000000000000000000', '172AEAB3D507678ECAF455C12587ADB7');

    blockCipherMCTTest(
        18,
        10000,
        AESEngine(),
        kp('00000000000000000000000000000000'),
        '00000000000000000000000000000000',
        'C34C052CC0DA8D73451AFE5F03BE297F');

    blockCipherMCTTest(
        19,
        10000,
        AESEngine(),
        kp('5F060D3716B345C253F6749ABAC10917'),
        '355F697E8B868B65B25A04E18D782AFA',
        'ACC863637868E3E068D2FD6E3508454A');

    blockCipherTest(
        20,
        AESEngine(),
        kp('000000000000000000000000000000000000000000000000'),
        '80000000000000000000000000000000',
        '6CD02513E8D4DC986B4AFE087A60BD0C');

    blockCipherMCTTest(
        21,
        10000,
        AESEngine(),
        kp('AAFE47EE82411A2BF3F6752AE8D7831138F041560631B114'),
        'F3F6752AE8D7831138F041560631B114',
        '77BA00ED5412DFF27C8ED91F3C376172');

    blockCipherTest(
        22,
        AESEngine(),
        kp('0000000000000000000000000000000000000000000000000000000000000000'),
        '80000000000000000000000000000000',
        'DDC6BF790C15760D8D9AEB6F9A75FD4E');

    blockCipherMCTTest(
        23,
        10000,
        AESEngine(),
        kp('28E79E2AFC5F7745FCCABE2F6257C2EF4C4EDFB37324814ED4137C288711A386'),
        'C737317FE0846F132B23C8C2A672CE22',
        'E58B82BFBA53C0040DC610C642121168');
  });
}

KeyParameter kp(String src) {
  return KeyParameter(createUint8ListFromHexString(src));
}

void blockCipherTest(int id, BlockCipher cipher, CipherParameters parameters,
    String input, String output) {
  test('AES BlockCipher Test: $id ', () {
    var _input = createUint8ListFromHexString(input);
    var _output = createUint8ListFromHexString(output);

    cipher.init(true, parameters);
    var out = Uint8List(_input.length);
    var p = 0;
    while (p < _input.length) {
      p += cipher.processBlock(_input, p, out, p);
    }

    expect(_output, equals(out), reason: '$id did not match output');

    cipher.init(false, parameters);
    out = Uint8List(_output.length);
    p = 0;
    while (p < _output.length) {
      p += cipher.processBlock(_output, p, out, p);
    }

    expect(_input, equals(out), reason: '$id did not match input');
  });
}

void blockCipherMCTTest(int id, int iterations, BlockCipher cipher,
    CipherParameters parameters, String input, String output) {
  test('AES BlockCipher MCT Test: $id ', () {
    var _input = createUint8ListFromHexString(input);
    var _output = createUint8ListFromHexString(output);

    cipher.init(true, parameters);
    var out = Uint8List(_input.length);
    out.setRange(0, out.length, _input);

    for (var i = 0; i != iterations; i++) {
      var p = 0;
      while (p < out.length) {
        p += cipher.processBlock(out, p, out, p);
      }
    }

    expect(_output, equals(out), reason: '$id did not match output');

    cipher.init(false, parameters);

    for (var i = 0; i != iterations; i++) {
      var p = 0;
      while (p < out.length) {
        p += cipher.processBlock(out, p, out, p);
      }
    }

    expect(_input, equals(out), reason: '$id did not match input');
  });
}

// See file LICENSE for more information.

library test.hmacs.hmac_test;

import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';

import '../test/runners/mac.dart';
import '../test/src/helpers.dart';

void main() {
  final mac = Mac('SHA-1/HMAC');
  final key = Uint8List.fromList([
    0x00,
    0x11,
    0x22,
    0x33,
    0x44,
    0x55,
    0x66,
    0x77,
    0x88,
    0x99,
    0xAA,
    0xBB,
    0xCC,
    0xDD,
    0xEE,
    0xFF
  ]);
  final keyParam = KeyParameter(key);

  mac.init(keyParam);

  runMacTests(mac, [
    PlainTextDigestPair(
        createUint8ListFromString(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit...'),
        'a646990cca06cb7550a91bdd9ae481c6472f06bc'),
    PlainTextDigestPair(
        createUint8ListFromString(
            'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...'),
        '1d710be3529ecee6ddd2f1ad4c3c12d6f467243f'),
  ]);

  testWithRfc4231();
}

/// Testing HMAC with using the test vectors from
/// [RFC 4231](https://tools.ietf.org/html/rfc4231) _Identifiers and Test
/// Vectors for HMAC-SHA-224, HMAC-SHA-256, HMAC-SHA-384, and HMAC-SHA-512_.
void testWithRfc4231() {
  // THe RFC has seven test cases, with data that is replicated here.

  Rfc4231TestVector.runAll([
    // First set of tests

    Rfc4231TestVector(
        'Test Case 1',
        '0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b'
            '0b0b0b0b',
        '4869205468657265',
        // Hi There

        '896fb1128abbdf196832107cd49df33f'
            '47b4b1169912ba4f53684b22',
        'b0344c61d8db38535ca8afceaf0bf12b'
            '881dc200c9833da726e9376c2e32cff7',
        'afd03944d84895626b0825f4ab46907f'
            '15f9dadbe4101ec682aa034c7cebc59c'
            'faea9ea9076ede7f4af152e8b2fa9cb6',
        '87aa7cdea5ef619d4ff0b4241a1d6cb0'
            '2379f4e2ce4ec2787ad0b30545e17cde'
            'daa833b7d6b8a702038b274eaea3f4e4'
            'be9d914eeb61f1702e696c203a126854'),

    // Test with a key shorter than the length of the HMAC output.

    Rfc4231TestVector(
        'Test Case 2',
        '4a656665',
        '7768617420646f2079612077616e7420'
            '666f72206e6f7468696e673f',
        'a30e01098bc6dbbf45690f3a7e9e6d0f'
            '8bbea2a39e6148008fd05e44',
        '5bdcc146bf60754e6a042426089575c7'
            '5a003f089d2739839dec58b964ec3843',
        'af45d2e376484031617f78d2b58a6b1b'
            '9c7ef464f5a01b47e42ec3736322445e'
            '8e2240ca5e69e2c78b3239ecfab21649',
        '164b7a7bfcf819e2e395fbe73b56e0a3'
            '87bd64222e831fd610270cd7ea250554'
            '9758bf75c05a994a6d034f65f8f0e6fd'
            'caeab1a34d4a6b4b636e070a38bce737'),

    // Test with a combined length of key and data that is larger than 64
    // bytes (= block-size of SHA-224 and SHA-256).

    Rfc4231TestVector(
        'Test Case 3',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaa',
        'dddddddddddddddddddddddddddddddd'
            'dddddddddddddddddddddddddddddddd'
            'dddddddddddddddddddddddddddddddd'
            'dddd',
        '7fb3cb3588c6c1f6ffa9694d7d6ad264'
            '9365b0c1f65d69d1ec8333ea',
        '773ea91e36800e46854db8ebd09181a7'
            '2959098b3ef8c122d9635514ced565fe',
        '88062608d3e6ad8a0aa2ace014c8a86f'
            '0aa635d947ac9febe83ef4e55966144b'
            '2a5ab39dc13814b94e3ab6e101a34f27',
        'fa73b0089d56a284efb0f0756c890be9'
            'b1b5dbdd8ee81a3655f83e33b2279d39'
            'bf3e848279a722c806b485a47e67c807'
            'b946a337bee8942674278859e13292fb'),

    // Test with a combined length of key and data that is larger than 64
    // bytes (= block-size of SHA-224 and SHA-256).

    Rfc4231TestVector(
        'Test Case 4',
        '0102030405060708090a0b0c0d0e0f10'
            '111213141516171819',
        'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
            'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
            'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
            'cdcd',
        '6c11506874013cac6a2abc1bb382627c'
            'ec6a90d86efc012de7afec5a',
        '82558a389a443c0ea4cc819899f2083a'
            '85f0faa3e578f8077a2e3ff46729665b',
        '3e8a69b7783c25851933ab6290af6ca7'
            '7a9981480850009cc5577c6e1f573b4e'
            '6801dd23c4a7d679ccf8a386c674cffb',
        'b0ba465637458c6990e5a8c5f61d4af7'
            'e576d97ff94b872de76f8050361ee3db'
            'a91ca5c11aa25eb4d679275cc5788063'
            'a5f19741120c4f2de2adebeb10a298dd'),

    // Test with a truncation of output to 128 bits.

    Rfc4231TestVector(
        'Test Case 5',
        '0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c'
            '0c0c0c0c',
        '546573742057697468205472756e6361'
            '74696f6e',
        '0e2aea68a90c8d37c988bcdb9fca6fa8',
        'a3b6167473100ee06e0c796c2955552b',
        '3abf34c3503b2a23a46efc619baef897',
        '415fad6271580a531d4179bc891d87a6',
        truncate128: true),

    // Test with a key larger than 128 bytes (= block-size of SHA-384 and
    // SHA-512).

    Rfc4231TestVector(
        'Test Case 6',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaa',
        '54657374205573696e67204c61726765'
            '72205468616e20426c6f636b2d53697a'
            '65204b6579202d2048617368204b6579'
            '204669727374',
        '95e9a0db962095adaebe9b2d6f0dbce2'
            'd499f112f2d2b7273fa6870e',
        '60e431591ee0b67f0d8a26aacbf5b77f'
            '8e0bc6213728c5140546040f0ee37f54',
        '4ece084485813e9088d2c63a041bc5b4'
            '4f9ef1012a2b588f3cd11f05033ac4c6'
            '0c2ef6ab4030fe8296248df163f44952',
        '80b24263c7c1a3ebb71493c1dd7be8b4'
            '9b46d1f41b4aeec1121b013783f8f352'
            '6b56d037e05f2598bd0fd2215d6a1e52'
            '95e64f73f63f0aec8b915a985d786598'),

    // Test with a key and data that is larger than 128 bytes (= block-size
    // of SHA-384 and SHA-512).

    Rfc4231TestVector(
        'Test Case 7',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaa',
        '54686973206973206120746573742075'
            '73696e672061206c6172676572207468'
            '616e20626c6f636b2d73697a65206b65'
            '7920616e642061206c61726765722074'
            '68616e20626c6f636b2d73697a652064'
            '6174612e20546865206b6579206e6565'
            '647320746f2062652068617368656420'
            '6265666f7265206265696e6720757365'
            '642062792074686520484d414320616c'
            '676f726974686d2e',
        '3a854166ac5d9f023f54d517d0b39dbd'
            '946770db9c2b95c9f6f565d1',
        '9b09ffa71b942fcb27635fbcd5b0e944'
            'bfdc63644f0713938a7f51535c3a35e2',
        '6617178e941f020d351e2f254e8fd32c'
            '602420feb0b8fb9adccebb82461e99c5'
            'a678cc31e799176d3860e6110c46523e',
        'e37b6a775dc87dbaa4dfa9f96e5e3ffd'
            'debd71f8867289865df5a32d20cdc944'
            'b6022cac3c4982b10d5eeb55c3e4de15'
            '134676fb6de0446065c97440fa8c6a58')
  ]);
}

// See file LICENSE for more information.

library test.asymmetric.oaep_test;

import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/impl/secure_random_base.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/utils.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';
import '../test/src/null_asymmetric_block_cipher.dart';

//================================================================

void main() {
  internalStateTesting();
  rsaesOaepFromBCSHA256();
  rsaesOaepFromBC();
  rsaOaepStandardTests();
}

//================================================================
/// Tests for RSA-OAEP with a known-correct test vector.
///
/// Test RSA-OAEP using the test vector from 'RSAES-OAEP Encryption Scheme:
/// Algorithm specification and supporting documentation', published by
/// RSA Laboratories in 2000.
///
/// A copy was found here:
/// https://www.inf.pucrs.br/~calazans/graduate/TPVLSI_I/RSA-oaep_spec.pdf

void rsaOaepStandardTests() {
  // RSA key information

  // n, the modulus:
  final n = decodeBigIntWithSign(
      1,
      createUint8ListFromHexString(
          'bb f8 2f 09 06 82 ce 9c 23 38 ac 2b 9d a8 71 f7 36 8d 07 ee d4 10 43 a4'
          '40 d6 b6 f0 74 54 f5 1f b8 df ba af 03 5c 02 ab 61 ea 48 ce eb 6f cd 48'
          '76 ed 52 0d 60 e1 ec 46 19 71 9d 8a 5b 8b 80 7f af b8 e0 a3 df c7 37 72'
          '3e e6 b4 b7 d9 3a 25 84 ee 6a 64 9d 06 09 53 74 88 34 b2 45 45 98 39 4e'
          'e0 aa b1 2d 7b 61 a5 1f 52 7a 9a 41 f6 c1 68 7f e2 53 72 98 ca 2a 8f 59'
          '46 f8 e5 fd 09 1d bd cb'));

  // e, the public exponent
  final e = decodeBigIntWithSign(1, createUint8ListFromHexString('11'));

  // p, the first prime factor of n
  final p = decodeBigIntWithSign(
      1,
      createUint8ListFromHexString(
          'ee cf ae 81 b1 b9 b3 c9 08 81 0b 10 a1 b5 60 01 99 eb 9f 44 ae f4 fd a4'
          '93 b8 1a 9e 3d 84 f6 32 12 4e f0 23 6e 5d 1e 3b 7e 28 fa e7 aa 04 0a 2d'
          '5b 25 21 76 45 9d 1f 39 75 41 ba 2a 58 fb 65 99'));

  // q, the second prime factor of n:
  final q = decodeBigIntWithSign(
      1,
      createUint8ListFromHexString(
          'c9 7f b1 f0 27 f4 53 f6 34 12 33 ea aa d1 d9 35 3f 6c 42 d0 88 66 b1 d0'
          '5a 0f 20 35 02 8b 9d 86 98 40 b4 16 66 b4 2e 92 ea 0d a3 b4 32 04 b5 cf'
          'ce 33 52 52 4d 04 16 a5 a4 41 e7 00 af 46 15 03'));

  // dP , p’s exponent:
  final dP = decodeBigIntWithSign(
      1,
      createUint8ListFromHexString(
          '54 49 4c a6 3e ba 03 37 e4 e2 40 23 fc d6 9a 5a eb 07 dd dc 01 83 a4 d0'
          'ac 9b 54 b0 51 f2 b1 3e d9 49 09 75 ea b7 74 14 ff 59 c1 f7 69 2e 9a 2e'
          '20 2b 38 fc 91 0a 47 41 74 ad c9 3c 1f 67 c9 81'));

  // dQ, q’s exponent:
  final dQ = decodeBigIntWithSign(
      1,
      createUint8ListFromHexString(
          '47 1e 02 90 ff 0a f0 75 03 51 b7 f8 78 86 4c a9 61 ad bd 3a 8a 7e 99 1c'
          '5c 05 56 a9 4c 31 46 a7 f9 80 3f 8f 6f 8a e3 42 e9 31 fd 8a e4 7a 22 0d'
          '1b 99 a4 95 84 98 07 fe 39 f9 24 5a 98 36 da 3d'));

  // qInv, the CRT coefficient:
  final qInv = decodeBigIntWithSign(
      1,
      createUint8ListFromHexString(
          'b0 6c 4f da bb 63 01 19 8d 26 5b db ae 94 23 b3 80 f2 71 f7 34 53 88 50'
          '93 07 7f cd 39 e2 11 9f c9 86 32 15 4f 58 83 b1 67 a9 67 bf 40 2b 4e 9e'
          '2e 0f 96 56 e6 98 ea 36 66 ed fb 25 79 80 39 f7'));

  //----------------
  // Encryption

  // M, the message to be encrypted:
  final message = createUint8ListFromHexString(
      'd4 36 e9 95 69 fd 32 a7 c8 a0 5b bc 90 d3 2c 49');

  // P , encoding parameters: NULL
  // ignore: unused_local_variable
  final dynamic params = null;

  // pHash = Hash(P ):
  // ignore: unused_local_variable
  final pHash = createUint8ListFromHexString(
      'da 39 a3 ee 5e 6b 4b 0d 32 55 bf ef 95 60 18 90 af d8 07 09');

  // DB = pHash∥PS∥01∥M:
  // ignore: unused_local_variable
  final db = createUint8ListFromHexString(
      'da 39 a3 ee 5e 6b 4b 0d 32 55 bf ef 95 60 18 90 af d8 07 09 00 00 00 00'
      '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00'
      '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00'
      '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 d4 36 e9 95 69'
      'fd 32 a7 c8 a0 5b bc 90 d3 2c 49');

  // seed, a random octet string:
  // ignore: unused_local_variable
  final seed = createUint8ListFromHexString(
      'aa fd 12 f6 59 ca e6 34 89 b4 79 e5 07 6d de c2 f0 6c b5 8f');

  // dbMask = M GF (seed , 107):
  // ignore: unused_local_variable
  final dbMask = createUint8ListFromHexString(
      '06 e1 de b2 36 9a a5 a5 c7 07 d8 2c 8e 4e 93 24 8a c7 83 de e0 b2 c0 46'
      '26 f5 af f9 3e dc fb 25 c9 c2 b3 ff 8a e1 0e 83 9a 2d db 4c dc fe 4f f4'
      '77 28 b4 a1 b7 c1 36 2b aa d2 9a b4 8d 28 69 d5 02 41 21 43 58 11 59 1b'
      'e3 92 f9 82 fb 3e 87 d0 95 ae b4 04 48 db 97 2f 3a c1 4e af f4 9c 8c 3b'
      '7c fc 95 1a 51 ec d1 dd e6 12 64');

  // maskedDB = DB ⊕ dbMask:
  // ignore: unused_local_variable
  final maskedDB = createUint8ListFromHexString(
      'dc d8 7d 5c 68 f1 ee a8 f5 52 67 c3 1b 2e 8b b4 25 1f 84 d7 e0 b2 c0 46'
      '26 f5 af f9 3e dc fb 25 c9 c2 b3 ff 8a e1 0e 83 9a 2d db 4c dc fe 4f f4'
      '77 28 b4 a1 b7 c1 36 2b aa d2 9a b4 8d 28 69 d5 02 41 21 43 58 11 59 1b'
      'e3 92 f9 82 fb 3e 87 d0 95 ae b4 04 48 db 97 2f 3a c1 4f 7b c2 75 19 52'
      '81 ce 32 d2 f1 b7 6d 4d 35 3e 2d');

  // seedMask = M GF (maskedDB, 20):
  // ignore: unused_local_variable
  final seedMask = createUint8ListFromHexString(
      '41 87 0b 5a b0 29 e6 57 d9 57 50 b5 4c 28 3c 08 72 5d be a9');

  // maskedSeed = seed ⊕ seedMask:
  // ignore: unused_local_variable
  final maskedSeed = createUint8ListFromHexString(
      'eb 7a 19 ac e9 e3 00 63 50 e3 29 50 4b 45 e2 ca 82 31 0b 26');

  // EM = maskedSeed∥maskedDB:
  final em = createUint8ListFromHexString(
      'eb 7a 19 ac e9 e3 00 63 50 e3 29 50 4b 45 e2 ca 82 31 0b 26 dc d8 7d 5c'
      '68 f1 ee a8 f5 52 67 c3 1b 2e 8b b4 25 1f 84 d7 e0 b2 c0 46 26 f5 af f9'
      '3e dc fb 25 c9 c2 b3 ff 8a e1 0e 83 9a 2d db 4c dc fe 4f f4 77 28 b4 a1'
      'b7 c1 36 2b aa d2 9a b4 8d 28 69 d5 02 41 21 43 58 11 59 1b e3 92 f9 82'
      'fb 3e 87 d0 95 ae b4 04 48 db 97 2f 3a c1 4f 7b c2 75 19 52 81 ce 32 d2'
      'f1 b7 6d 4d 35 3e 2d');

  // C, the RSA encryption of EM:
  final ciphertext = createUint8ListFromHexString(
      '12 53 e0 4d c0 a5 39 7b b4 4a 7a b8 7e 9b f2 a0 39 a3 3d 1e 99 6f c8 2a'
      '94 cc d3 00 74 c9 5d f7 63 72 20 17 06 9e 52 68 da 5d 1c 0b 4f 87 2c f6'
      '53 c1 1d f8 23 14 a6 79 68 df ea e2 8d ef 04 bb 6d 84 b1 c3 1d 65 4a 19'
      '70 e5 78 3b d6 eb 96 a0 24 c2 ca 2f 4a 90 fe 9f 2e f5 c9 c1 40 e5 bb 48'
      'da 95 36 ad 87 00 c8 4f c9 13 0a de a7 4e 55 8d 51 a7 4d df 85 d8 b5 0d'
      'e9 68 38 d6 06 3e 09 55');

  //----------------
  // Decryption

  // c mod p (c is the integer value of C):
  // ignore: unused_local_variable
  final cModP = createUint8ListFromHexString(
      'de 63 d4 72 35 66 fa a7 59 bf e4 08 82 1d d5 25 72 ec 92 85 4d df 87 a2'
      'b6 64 d4 4d aa 37 ca 34 6a 05 20 3d 82 ff 2d e8 e3 6c ec 1d 34 f9 8e b6'
      '05 e2 a7 d2 6d e7 af 36 9c e4 ec ae 14 e3 56 33');

  // c mod q:
  // ignore: unused_local_variable
  final cModQ = createUint8ListFromHexString(
      'a2 d9 24 de d9 c3 6d 62 3e d9 a6 5b 5d 86 2c fb ec 8b 19 9c 64 27 9c 54'
      '14 e6 41 19 6e f1 c9 3c 50 7a 9b 52 13 88 1a ad 05 b4 cc fa 02 8a c1 ec'
      '61 42 09 74 bf 16 25 83 6b 0b 7d 05 fb b7 53 36');

  // m1 =cdP modp=(cmodp)dP modp:
  // ignore: unused_local_variable
  final m1 = createUint8ListFromHexString(
      '89 6c a2 6c d7 e4 87 1c 7f c9 68 a8 ed ea 11 e2 71 82 4f 0e 03 65 52 17'
      '94 f1 e9 e9 43 b4 a4 4b 57 c9 e3 95 a1 46 74 78 f5 26 49 6b 4b b9 1f 1c'
      'ba ea 90 0f fc 60 2c f0 c6 63 6e ba 84 fc 9f f7');

  //m2 =cdQ modq=(cmodq)dQ modq:
  // ignore: unused_local_variable
  final m2 = createUint8ListFromHexString(
      '4e bb 22 75 85 f0 c1 31 2d ca 19 e0 b5 41 db 14 99 fb f1 4e 27 0e 69 8e'
      '23 9a 8c 27 a9 6c da 9a 74 09 74 de 93 7b 5c 9c 93 ea d9 46 2c 65 75 02'
      '1a 23 d4 64 99 dc 9f 6b 35 89 75 59 60 8f 19 be');

  // h=(m1 −m2)qInvmodp:
  // ignore: unused_local_variable
  final h = createUint8ListFromHexString(
      '01 2b 2b 24 15 0e 76 e1 59 bd 8d db 42 76 e0 7b fa c1 88 e0 8d 60 47 cf'
      '0e fb 8a e2 ae bd f2 51 c4 0e bc 23 dc fd 4a 34 42 43 94 ad a9 2c fc be'
      '1b 2e ff bb 60 fd fb 03 35 9a 95 36 8d 98 09 25');

  //----------------------------------------------------------------
  // Create Pointy Castle [RSAPublicKey] and [RSAPrivateKey] objects.

  // Derive the private exponent (d) from values provided in the test vector.

  final phi = (p - BigInt.one) * (q - BigInt.one);

  final privateExponent = e.modInverse(phi);

  // Instantiate the RSA key pair objects

  final publicKey = RSAPublicKey(n, e);
  final privateKey = RSAPrivateKey(n, privateExponent, p, q, e);

  //----------------

  test('RSA key pair is valid', () {
    // Some correctness checks for the RSA public-key values.
    //
    // This test should never fail, since the values are known to be correct.

    expect(p * q, equals(n)); // modulus = p * q

    // dP = (1/e) mod (p-1)
    expect(e.modInverse(p - BigInt.one), equals(dP));

    // dQ = (1/e) mod (q-1)
    expect(e.modInverse(q - BigInt.one), equals(dQ));

    // qInv = (1/q) mod p  where p > q
    expect(q.modInverse(p), equals(qInv));

    expect((e * privateExponent) % phi, equals(BigInt.one));
  });

  //----------------------------------------------------------------

  test('EME-OAEP encoding operation', () {
    // This test is actually redundant.
    //
    // If the following 'encryption' test passes, then the encoding operation
    // would have also worked. But since we can make replace the [RSAEngine]
    // with the [NullAsymmetricBlockCipher] that does nothing, we can use it to
    // examine the EME-OAEP encoded message (called 'EM' in RFC 2437), before it
    // normally gets encrypted.
    //
    // If there is a bug in the underlying asymmetric encryption (i.e. in the
    // [RSAEngine], this test will succeed when the encryption test will fail.
    // If there is a bug in the EME-OAEP encoding operation, then this test and
    // the following encryption test will both fail. It is impossible for this
    // test to fail and the encryption test to pass.

    // Can't instantiate using AsymmetricBlockCipher('Null/OAEP'), because the
    // default [NullAsymmetricBlockCipher] has block lengths of 70 instead of
    // 127 (which is necessary for this to work properly). So must use its
    // constructor and pass in 127 for the two block lengths.

    final encryptor = OAEPEncoding(NullAsymmetricBlockCipher(127, 127));

    encryptor.init(
        true,
        ParametersWithRandom(PublicKeyParameter<RSAPublicKey>(publicKey),
            _OAEPTestEntropySource()..seed(KeyParameter(seed))));

    // Pretend to encrypt the test [message] value

    final output = Uint8List(encryptor.outputBlockSize);

    final size = encryptor.processBlock(message, 0, message.length, output, 0);
    expect(size, equals(encryptor.outputBlockSize));

    // The output should be the unencrypted EM (since Null cipher does nothing)

    expect(output, equals(em));
  });

  //----------------------------------------------------------------

  test('encryption', () {
    // Create the OAEPEncoding and initialize it with the publicKey and a
    // special SecureRandom implementation that always returns the fixed [seed]
    // value, so the produced ciphertext is deterministic and can match the
    // expected value. DO NOT DO THIS IN PRODUCTION. This is insecure and is
    // done only for testing purposes.

    registry.register(_OAEPTestEntropySource.factoryConfig); // register 'Fixed'

    final encryptor = AsymmetricBlockCipher('RSA/OAEP'); // using registry

    encryptor.init(
        true, // true = for encryption
        ParametersWithRandom(PublicKeyParameter<RSAPublicKey>(publicKey),
            SecureRandom('_oaep_rand')..seed(KeyParameter(seed))));

    // Encrypt the test [message] value

    final output = Uint8List(encryptor.outputBlockSize);

    final size = encryptor.processBlock(message, 0, message.length, output, 0);
    expect(size, equals(encryptor.outputBlockSize));

    // The ciphertext should be the expected test [ciphertext] value

    expect(output, equals(ciphertext));
  });

  //----------------------------------------------------------------

  test('decryption', () {
    final decryptor = OAEPEncoding(RSAEngine()); // without using the registry

    decryptor.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    // Decrypt the test [ciphertext] value

    final outBuf = Uint8List(decryptor.outputBlockSize);

    final outputSize =
        decryptor.processBlock(ciphertext, 0, ciphertext.length, outBuf, 0);
    final decrypted = outBuf.sublist(0, outputSize);

    // The decrypted message should be the expected test [message] value

    expect(decrypted, equals(message));
  });

  //----------------------------------------------------------------

  test('encryption with encoding parameters', () {
    final params = Uint8List.fromList('TestLabel'.codeUnits);
    final encryptor =
        OAEPEncoding(RSAEngine(), params); // without using the registry

    encryptor.init(
        true, // true = for encryption
        ParametersWithRandom(PublicKeyParameter<RSAPublicKey>(publicKey),
            SecureRandom('_oaep_rand')..seed(KeyParameter(seed))));

    // Encrypt the test [message] value

    final output = Uint8List(encryptor.outputBlockSize);

    final size = encryptor.processBlock(message, 0, message.length, output, 0);
    expect(size, equals(encryptor.outputBlockSize));

    // The ciphertext should be the [expectedCipherText] value
    final expectedCipherText = createUint8ListFromHexString(
        '04 cc a5 6a f9 f7 93 67 3e 98 9e d1 d6 08 4a 5c a7 46 f3 9b d7 37 40'
        '40 1d 88 0d 70 24 57 e9 41 42 a2 5a 04 92 0f 83 60 04 14 ef 43 a8 0e'
        '60 ad 72 c7 e4 66 ae 18 68 5f 05 a5 5b 0d b8 db 19 67 d7 18 b9 5d e7'
        '09 db d0 20 6c 2a 43 31 15 ae d5 cf b3 9b 68 bb 13 d2 22 4a 51 e1 b0'
        '6f 93 4c 91 f3 f7 48 6b 5f 57 28 f6 b3 b2 2d e6 9a 6d b9 12 4a a9 31'
        '03 12 86 20 f0 50 d7 0c e4 33 58 ee 7c');

    expect(output, equals(expectedCipherText));
  });

  test('decryption with encoding parameters', () {
    final params = Uint8List.fromList('TestLabel'.codeUnits);
    final decryptor =
        OAEPEncoding(RSAEngine(), params); // without using the registry

    decryptor.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final cipherTextEncodingParams = createUint8ListFromHexString(
        '04 cc a5 6a f9 f7 93 67 3e 98 9e d1 d6 08 4a 5c a7 46 f3 9b d7 37 40'
        '40 1d 88 0d 70 24 57 e9 41 42 a2 5a 04 92 0f 83 60 04 14 ef 43 a8 0e'
        '60 ad 72 c7 e4 66 ae 18 68 5f 05 a5 5b 0d b8 db 19 67 d7 18 b9 5d e7'
        '09 db d0 20 6c 2a 43 31 15 ae d5 cf b3 9b 68 bb 13 d2 22 4a 51 e1 b0'
        '6f 93 4c 91 f3 f7 48 6b 5f 57 28 f6 b3 b2 2d e6 9a 6d b9 12 4a a9 31'
        '03 12 86 20 f0 50 d7 0c e4 33 58 ee 7c');

    // Decrypt the test [cipherTextEncodingParams] value

    final outBuf = Uint8List(decryptor.outputBlockSize);

    final outputSize = decryptor.processBlock(cipherTextEncodingParams, 0,
        cipherTextEncodingParams.length, outBuf, 0);
    final decrypted = outBuf.sublist(0, outputSize);

    // The decrypted message should be the expected test [message] value

    expect(decrypted, equals(message));
  });

  //----------------------------------------------------------------

  test('tampered ciphertext detected', () {
    final decryptor = OAEPEncoding(RSAEngine()); // without using the registry

    decryptor.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    // Try tampering with every bit in the ciphertext (128 bytes = 1024 bits)

    for (var bitPos = 0; bitPos < ciphertext.length * 8; bitPos++) {
      // Create a copy of the ciphertext that has been tampered with

      final tamperedCiphertext = Uint8List.fromList(ciphertext);
      tamperedCiphertext[bitPos ~/ 8] ^= 0x01 << (bitPos % 8); // flip a bit

      // Try to decrypt it: expecting it to always fail

      try {
        final outBuf = Uint8List(decryptor.outputBlockSize);

        // ignore: unused_local_variable
        final _outputSize = decryptor.processBlock(
            tamperedCiphertext, 0, tamperedCiphertext.length, outBuf, 0);
        fail('tampered with ciphertext still decrypted');

        // final decrypted = outBuf.sublist(0, outputSize);
        // expect(decrypted, equals(message));
      } on ArgumentError catch (e) {
        expect(e.message, equals('decoding error'));
      }
    }
  });

  test('EME-OAEP encoding operation', () {
    // This test is actually redundant.
    //
    // If the following 'encryption' test passes, then the encoding operation
    // would have also worked. But since we can make replace the [RSAEngine]
    // with the [NullAsymmetricBlockCipher] that does nothing, we can use it to
    // examine the EME-OAEP encoded message (called 'EM' in RFC 2437), before it
    // normally gets encrypted.
    //
    // If there is a bug in the underlying asymmetric encryption (i.e. in the
    // [RSAEngine], this test will succeed when the encryption test will fail.
    // If there is a bug in the EME-OAEP encoding operation, then this test and
    // the following encryption test will both fail. It is impossible for this
    // test to fail and the encryption test to pass.

    // Can't instantiate using AsymmetricBlockCipher('Null/OAEP'), because the
    // default [NullAsymmetricBlockCipher] has block lengths of 70 instead of
    // 127 (which is necessary for this to work properly). So must use its
    // constructor and pass in 127 for the two block lengths.

    final encryptor = OAEPEncoding(NullAsymmetricBlockCipher(127, 127));

    encryptor.init(
        true,
        ParametersWithRandom(PublicKeyParameter<RSAPublicKey>(publicKey),
            _OAEPTestEntropySource()..seed(KeyParameter(seed))));

    // Pretend to encrypt the test [message] value

    final output = Uint8List(encryptor.outputBlockSize);

    final size = encryptor.processBlock(message, 0, message.length, output, 0);
    expect(size, equals(encryptor.outputBlockSize));

    // The output should be the unencrypted EM (since Null cipher does nothing)

    expect(output, equals(em));
  });

  //----------------------------------------------------------------
  /// Test decryption when EME-OAEP encoded message has leading 0x00 bytes.
  ///
  /// This is a regression test, since Pointy Castle v1.0.2 had a bug which
  /// caused decryption to fail in these situation. The leading null byte is not
  /// needed to represent the same integer value. But a correct implementation
  /// of the I2OSP (integer to octet string primitive) will produce the
  /// correct number of null bytes.

  test('I2OSP when EM starts with 0x00 bytes', () {
    // This test could be done with any key pair, but since we already have a
    // key pair from the above tests, use it.

    final keySizeInBytes = publicKey.modulus!.bitLength ~/ 8;

    final numNulls = List<int>.filled(keySizeInBytes, 0); // tracks test cases

    // The EME-OAEP encoded message (EM) is determined by:
    //
    //   - length of the block (determined by public key used)
    //   - the message
    //   - random bytes used as the seed
    //   - other factors that are constant in OAEPEncoding (i.e. hash algorithm,
    //     parameters and mask generating function)
    //
    // Below are a carefully chosen test message and seeds for a
    // FixedSecureRandom known to produce _EM_ that start with 1, 2 and 3 0x00
    // bytes.

    final testMsg = Uint8List.fromList('Hello world!'.codeUnits);

    for (final x in [822, 197378, 522502]) {
      // Change above to the following, to use the code to find test cases
      // const numCasesToTry = 1000;
      // for (var x = 0; x < numCasesToTry; x++) {

      // Create a testSeed from x

      final numbers = <int>[];
      var n = x;
      while (0 < n) {
        numbers.add(n & 0xFF);
        n = n >> 8;
      }
      final testFixedRndSeed = Uint8List.fromList(numbers.reversed.toList());
      // print('FixedSecureRandom seed: $testFixedRndSeed (from x = $x)');

      final processTestCaseWith = (AsymmetricBlockCipher blockCipher) {
        final rnd = _OAEPTestEntropySource()
          ..seed(KeyParameter(testFixedRndSeed));

        final enc = OAEPEncoding(blockCipher);

        enc.init(
            true,
            ParametersWithRandom(
                PublicKeyParameter<RSAPublicKey>(publicKey), rnd));

        final _buf = Uint8List(enc.outputBlockSize);
        final _len = enc.processBlock(testMsg, 0, testMsg.length, _buf, 0);
        return _buf.sublist(0, _len);
      };

      // Use null block cipher to obtain the EM (encryption does nothing)

      final testEM = processTestCaseWith(
          NullAsymmetricBlockCipher(keySizeInBytes - 1, keySizeInBytes));

      // Determine how many 0x00 are at the start of the EM

      var numNullBytesAtStart = 0;
      while (testEM[numNullBytesAtStart] == 0x00) {
        numNullBytesAtStart++;
      }

      numNulls[numNullBytesAtStart]++; // record it for later test case checking

      // if (0 < numNullBytesAtStart) {
      //  print('x=$x produced ${numNullBytesAtStart} null bytes');
      // }

      // Use RSA block cipher to obtain the ciphertext (i.e. encrypted EM).
      // Exactly the same as when finding the EM, except the underlying cipher
      // is now RSA instead of a null cipher.

      final cipher = processTestCaseWith(RSAEngine());

      // Decrypt the cipher (if the I2OSP does not correctly reproduce the
      // 0x00 byte, the decryption operation will fail).

      final dec = OAEPEncoding(RSAEngine());

      dec.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      final _decBuf = Uint8List(dec.outputBlockSize);
      final _decSize = dec.processBlock(cipher, 0, cipher.length, _decBuf, 0);
      final decrypted = _decBuf.sublist(0, _decSize);

      expect(decrypted, equals(testMsg));
    }

    // Check above has included test cases with the desired number of 0x00 bytes

    const maxNumNullsTested = 3; // looking for cases with 1, 2 and 3 0x00 bytes

    for (var n = 1; n <= maxNumNullsTested; n++) {
      // print('Number of test cases starting with $n 0x00: ${numNulls[n]}');
      expect(numNulls[n], greaterThan(0),
          reason: 'no test case with EM starting with $n 0x00');
    }
  });
}

class Vector {
  BigInt? pubExp;
  BigInt? pubMod;
  late BigInt privExp;
  BigInt? privMod;
  BigInt? privP;
  BigInt? privQ;
  BigInt? privDP;
  BigInt? privDQ;
  BigInt? privQInv;
  Uint8List? pt;
  Uint8List? ct;
  Uint8List? seed;

  bool success = false;

  Vector(
      String pubExp,
      String pubMod,
      String privExp,
      String privMod,
      String privP,
      String privQ,
      String pt,
      String ct,
      String seed,
      this.success) {
    this.pubExp = BigInt.parse(pubExp, radix: 10);
    this.pubMod = BigInt.parse(pubMod, radix: 10);

    this.privExp = BigInt.parse(privExp, radix: 10);
    this.privMod = BigInt.parse(privMod, radix: 10);
    this.privP = BigInt.parse(privP, radix: 10);
    this.privQ = BigInt.parse(privQ, radix: 10);
    this.pt = createUint8ListFromHexString(pt);
    this.ct = createUint8ListFromHexString(ct);
    this.seed = createUint8ListFromHexString(seed);
  }

  RSAPublicKey getPublicKey() {
    return RSAPublicKey(pubMod!, pubExp!);
  }

  RSAPrivateKey getPrivateKey() {
    return RSAPrivateKey(privMod!, privExp, privP, privQ);
  }
}

///
/// Check for controlled failure if the payload decrypts correctly.
///
void internalStateTesting() {
  var e = BigInt.parse('17');
  var n = BigInt.parse(
      '18904793323418458651049426928801905285353796206385193666381737473597835434592217089788859459502722864449929528026460733832101275463481053011104851889194611340892902106814930153201137075011689812853583062022802401066404443801928558344390307491359578381828323202923825005967997182480368891209321353708191936440581584590352341102052628938464842924718115348382042288768422683607812317488624471145713271448836553349942090507534654252362527087639524130879656765282272133914712413710755311513452265197601040534855780870663561450317819530420407368857024352282644119023990887913427980404345159582897596808724346289832894083203');
  var privE = BigInt.parse(
      '617803703379688191210765585908558996253392032888405021777180963189471746228503826463688217630807936746729723138119631824578473054362125915395583395071719324865781114601795103045788793301035614799136701373294196113281190973919233932823212663116326090909422326892935457711372456943802904941481089990463788772559031057214358422944212239732312586528170369790496999028037134004691319620578080624784410538321964157477137634793679842220183389194487973889415513666720489302892692475014393096306934540126165897827044583270894711764757806980961253390129735543605935602739263581935639888398241224738439056849378642168461974233');
  var p = BigInt.parse(
      '143420423826270698175633028465402741568026051978003404422758284490094742892554157033700862464778324477416298502402311074511535147590579816829854156588557905481381920228165031361037666213139917088009390138780140545235925176923381310162839263972799741951878755589786868244570696343039584097757121751323287364159');
  var q = BigInt.parse(
      '131813815766702661784101374190675035388075980814830714087728098574163194206381046993609446511406125653725380380445740005913380230697612313033687890492067255764814103747149851405422402056600446973338826483794042725080305459879611704956215180675502747628290666716410531574788281762861777571376238088154670307517');

  // We need to examine behavior when the encoding is invalid but the
  // RSA decryption is ok.

  var pubKey = PublicKeyParameter<RSAPublicKey>(RSAPublicKey(n, e));
  var privKey =
      PrivateKeyParameter<RSAPrivateKey>(RSAPrivateKey(n, privE, p, q));

  test('cause invalid hash', () {
    var msg = Uint8List(190 + 32 + 1);
    var rsa = RSAEngine();
    rsa.init(true, pubKey);
    var out = Uint8List(rsa.outputBlockSize);
    rsa.processBlock(msg, 0, msg.length, out, 0);
    var oaep = OAEPEncoding.withSHA256(RSAEngine());
    oaep.init(false, privKey);

    var oaepOut = Uint8List(oaep.outputBlockSize);
    expect(() {
      oaep.processBlock(out, 0, out.length, oaepOut, 0);
    }, throwsA(TypeMatcher<ArgumentError>()));
  });

  test('wrong data length', () {
    var msg = Uint8List(190 + 31 + 1);
    var rsa = _RSABroken();
    rsa.init(true, pubKey);
    var out = Uint8List(rsa.outputBlockSize);
    rsa.processBlock(msg, 0, msg.length, out, 0);

    var oaep = OAEPEncoding.withSHA256(rsa);
    oaep.init(false, privKey);

    var oaepOut = Uint8List(oaep.outputBlockSize);

    expect(() {
      //
      // Create a circumstance where block len is less than 2x hash size +1
      //
      rsa.wrongSizeDelta = -191;
      oaep.processBlock(out, 0, out.length, oaepOut, 0);
    }, throwsA(TypeMatcher<ArgumentError>()));
  });
}

///
/// Test RSAESOAEP using sha256, vectors generated from BC Java api.
///
void rsaesOaepFromBCSHA256() {
  var e = BigInt.parse('17');
  var n = BigInt.parse(
      '18904793323418458651049426928801905285353796206385193666381737473597835434592217089788859459502722864449929528026460733832101275463481053011104851889194611340892902106814930153201137075011689812853583062022802401066404443801928558344390307491359578381828323202923825005967997182480368891209321353708191936440581584590352341102052628938464842924718115348382042288768422683607812317488624471145713271448836553349942090507534654252362527087639524130879656765282272133914712413710755311513452265197601040534855780870663561450317819530420407368857024352282644119023990887913427980404345159582897596808724346289832894083203');
  var privE = BigInt.parse(
      '617803703379688191210765585908558996253392032888405021777180963189471746228503826463688217630807936746729723138119631824578473054362125915395583395071719324865781114601795103045788793301035614799136701373294196113281190973919233932823212663116326090909422326892935457711372456943802904941481089990463788772559031057214358422944212239732312586528170369790496999028037134004691319620578080624784410538321964157477137634793679842220183389194487973889415513666720489302892692475014393096306934540126165897827044583270894711764757806980961253390129735543605935602739263581935639888398241224738439056849378642168461974233');
  var p = BigInt.parse(
      '143420423826270698175633028465402741568026051978003404422758284490094742892554157033700862464778324477416298502402311074511535147590579816829854156588557905481381920228165031361037666213139917088009390138780140545235925176923381310162839263972799741951878755589786868244570696343039584097757121751323287364159');
  var q = BigInt.parse(
      '131813815766702661784101374190675035388075980814830714087728098574163194206381046993609446511406125653725380380445740005913380230697612313033687890492067255764814103747149851405422402056600446973338826483794042725080305459879611704956215180675502747628290666716410531574788281762861777571376238088154670307517');

  var pubKey = PublicKeyParameter<RSAPublicKey>(RSAPublicKey(n, e));
  var privKey =
      PrivateKeyParameter<RSAPrivateKey>(RSAPrivateKey(n, privE, p, q));

  // [<seed>,<msg>,<ct>, ..., <seed>,<msg>,<ct>
  var vectors = [
    '2f9821a62f95013a4bb947e8b1dc298592107868782cdf06b33666d2dbc2231f7196e070bed93f41924778508963de2fe996a0d0ee4dcfee1a224d2236118ca508b700be1791c8c6dbcf6101e7e34849374bb46d6f22e4e435e3c9ffbfd1caefff9b92b12f0729701409e6b63eb39af1b75357051adfd8199d5c185e07a325f031619b8152fb7a55052370033f2b97d9cca7bb9daeaf02b36651c27b4e6094ea773c30b691e7d4da0506b5be8dab1dd4484bc647d82dceeb8fddb5b8cc75b165017ad2a5ae24de16b33e34207621e7222f00def60cdb69f4b45cd820d63e3c9ec39d4e731d70cd1c6c3fa63c4d8959c9a93cf813e1301f8e0ad93466b889810c047190c1036369572a753f5c1818d6e4dcd6f5a2c99b95d714aa6d7cae29813d598bd5858a840d0f8e68c86c6367fe79bffa25f5a4b24975b74905807d0fbca482dcf02619358d84852a9defa82768467ca1eb861495619b969f3cafba94979ac9388f7bfde908b7a2edef2bc0278c190673f66b86dbd00ec7a425941ab02f7264e7de772b8c94a40cce37a9787584feff81ecd737248d29942f4a7f915d8f8e39a81858022a26a0afc915edf151903a9544c7c06543376f3e59a8c704798b57dc4d0361ec90106423c5a7306525709e2744d6245e9d34a7055a4b3742a66e063fd0817fd05283fa80713855485063b6a0581402d981818b1c9ca6c97b30dffe',
    '76c5ae60011feb4334f08b83553b2fcbd898ea3fe0beb6f08fd8a7107106da932d8f8503ab9e0774d5d173a64b2b0284475fd3cab01fd565d0fed7e428c36e64bd178bdee00b2735cf5b4f332e38e64d776a81f2d781b7bd56ccbe304910ba82d5f7d9574120c332114be41ae7b609205774ea5ce45b5b569b77151a318342744e8fd88a71c96f9e57f1e47002e29fd8d518f0379c386dd77e6e1e4f27fdbba49bbee3188d0625e3face8c7a2baefa092daeee6ed6ea592c3dde8add802d',
    '04da21f24d7c757dcc0e23e879812779d20c7b2e35d1fdbd83187b070c49a75639f4b6723cec912527798fd511191bf2fc2f6b059b603efda1fa77b749a77fcb83ab2d7ab4de32f80d51e23ccacbebad129fb259d587308eb233829f53c4ef05bad21e92b4eebe71f52d3720f373c922ff203c9fbcdcf56aa24bd661c458ab05cbd7ec6955becc6404c8916faf520548133833ac96b4cbf7bce1146d164a61078992f45a7b779110147f894c6fcbd46ddc187999375a6cea4460953f71cd94b0f71fb5641a5dffbab88276cf7f16b38c92231d39f59ef250cfd4a807cb51fb0095b00f841d2d5f68908a0cf4932a7b3babebd44626edfbcea8b19f3bc79cda9c',
    '3288c7e74819bddb788af2e8b4247ffbecdb9f07a0fcb6a3b40902708ab7f35272e7f0106543bd2c9a765179bd8e94bfc5f1cc03cf94b87650f9dfe8cd0db5eaf769c3ae722761aa789a04a3b1af4bd948172e025bb4a31b1892aa8e97f3dbb4eaeeaa1d0aa7b7d9cd0dca8a35adb00b17b49e63d72e2e5bdb6c345b0d2731d8daf5c62b2acf20b4722494f3834a30152ac1ce6c50b86ccd2f36574232a1d97e3fbc0cc011487f543075ad17355a06d160a46a53fcbe4a6e631b3e717686b22676a2aca0f585fe389115841a2e9fcaa848dc8fdb39dbc25472c5543f3fe8bd7b4266ec5ed3f14ebb35be0fd026f9e6df0c00ece61d37ec6500817f2cef718a09200a183f99268810706ac7558be669ba53a1eb6b8ce66e338399a140df050ac54f82b1dd681688ef075f08233b75a2d78edaf6f4c3c206aee8f505269c19f5344a37e1cf00620695dfbed7a68f2caded620ec2245462d09c8a2aea29a8e0c37666d2e385def15a1f5b81ac97524d3e026557a07974da85ca0d2b5d6a453b300ecfae8e59a24483c6669949e19f9ae55f8013641fdeed43ee23a7adc5031597b3183c44a6de617d2ac5bb0abc5e48a1d52df8156cfa3aec5d9b03f702f7f542abbba1c5d51d0bcd628356d87887f81a76656357f111a20c47ea9221ee88135e10a2f023c39df9a114987e8de08b18a49d554250fb377e08a7be5c30f30f42afaa',
    '13443416b03e96b50121ea97cd9f30f35bd6fed05653f1d1669554af558f972238ff71a4623e3ea14cb1285862f7609c66a6105d1e1caedc50dfaa72ef09d4227ddebf321de041f2c724c265d6dbfcc95f250613596067dbf31cff256d23532296c331a09e06491019aae5624e6c27a845ecc2d5937d27f7a80ac1d7f985354290fef8dcf2d3ee4a48e88b9af24364130c8e0fdbe03d3406bef677d7f6de34f99bdcd5533ebb5107561cb6d36bc09e7ceeb830075cbd6901422a93dd7c6f',
    '8511545e2a2e924fba41b3283bdec21bef0859740312f1d145eb4ed86fc33fafbbb067b05db9f52bb8beb0c8558c61ac2a25b36eb2e15c66e33b992ab0f8a987cca147161adfff81f2cdcd90841f6936e3020d4745c058af5511a5aebe51ab3b6824fb3951d24b811cb651cbd106eb27c10658e2b1d7ef9a5e1b2d6b68054d2b08737f2fb1523c5827a8e3590a513c7d2c679d6f389c979e61fba082691a6ba9cacc805ed907e03b7a0b1ec04181adce0be1e51385711f38085e96e2add695efa64287145f3388529c5dbee50878f60cfe591ba6a11d1fb0c72e6ff6d56d7d8eaf55705f25431174382c02799ac69306f720cbe895c9d912036813e4949f5450',
    '2640c4b62783aae4c77311ea5703ff845cdd8ac9199028bc7838b19bd5d61d7377d562b762ca9c6386db4cedba762082a138de422a10eff9df919346f43ee2daaabfdc2af65a44a4657a49b494e163f11c85860b50c4637138095485a332f8565fd753adc7b31a20b0b977693afd4d9b54d4a190c4e7e8a83bdd14b8711537891d3f1cc85698b1b7b7a2451cb3b95ff416ab01fde545a7d38238cba1255caa54cd4b8bc7dabc46b801ec84e6aadbf188ddc11105094da5fbbc1d0a59c1d239e9cd09c4a6e5cffd84625291106afd92480b985e05e9e9690a0b1deb442492f1ccdcf8f56303657756dde7ec491db111df56c94a2384c79710a53c571d9ddc77dbba9735647d8895d465599719e2e8b1162b454e7c56a0e1b59535c12004d502e4e210402df90a807c14489775f2ca9fd4e6cf00939603839e63ab92547f409aebf808441f66312eeaab943e0c3212248e27aa5eb1454f0eb5cfe374074d3208b5ade22c612c85f36c56569f31c07c211c6354f012282b8a89618c97bba2fddd4b1ffa37e039aaa9e91ef7261930ba41e361ba823f84e91136cbba02a7821bb452bc6d6bf239bc98c3d8b438affd46f4638ca830aa0408367873d589b210529584d8403c96c7c4196b77e6558821324322a04bbdf5860d0cb32da76b95872a4fae29f37e0df925a9e0ff15076c9558644dce14bbf045b8f3ffdcab801d84c23694',
    'e1d8fe8a9925adaa7409f9de4efb7d76ee3966a799790bb9e50d5685393292820234fea010c488fd83bd51bcd4404f4ab45fdb0f07a3fde4de48ea42db1bbc86d775d817aa50deb6e2ce1bc4aaea3b1d973ff8551309e7fa81c0e05872e0a276fd0adc840980a235587c0b65c213751391be3dd5ef1c2d42204eb0c14ba2ade38c7c4408cefe4753873df1c0bd2c0dd6c4e24e4aa0f6bfa64d39ba654497b48f094d7e96af097dfe6c1952ae924c9947507811df0aba84e925b26c1c440c',
    '59f65cff132486a62ae6c715fce55ade7858c117e521789c6b20a6fab4d6d5fe396b15f7b70e003ff74947dbeffdbc5fa11a9c3332be50cd7f88548148dc6b1d775984ca1a1155b1d993211f32172bbb9a99ca33a7a33a30e62a53d98f25a24b09dd01123bcb0c1c636e01a00b00a63d91c5803db03684ac8cf868d3f64483203cc5f73b375d269363b50670b5d93c3bfa7f2c97d0bec7a501241bb71f6f108ba2f74e3974e8b3034501e4b6c336848f6dfce0475ebe1c68dabaa8b27a404c88d4613cb8693b94f648992248b8530d641169aba74318781da3afd7f53c6aad573ab107abc796574ebafbf18d13ae317d7e137b9c2e01700c5cb0eda7e4968cc8',
    '3b2ec09b0d3e81a0281b69fff90c3ff7c5c12c0ded8cf434bf5cb384ccb051de82bf60bfa13055bc6eb5a627d07fa629118230f8dcfa05f7587f1c1738c920cd8f07dee2b9adc7173262aabf6aa48d98443a8fd9a9bf874385b101e5d7601ca333881436ab60281d454d05a55de92fa2da2fa5094b87d98c214405e2ebd6e057a1942f0f4e9d8e09ffbc39d6454ae4f8a400531c121de2d66ff4b903ff53a30de8a1b1e3f3455b30728c40c49703865f463ef89011b6aeddf56bfde69ca479f69a4c16819d47faa23aa306aaaec948ba62f081f14faa08f74b071959bc8234af97f8016ed5d28cc39981e2265bc298d589592b49b118581aececea8746654b9b97b83f9c825c725757ea7e9221a9aa5fed4ab29bbe02614fb9dfd982901e12330560fd83264754621c4935c74357ae21118c75afafb46c14e2ac85213c3a88922f3f724c89a574c439fca4540ee706b48f7bc28c61b0b4d2343e9b72cb88f5a48fea1d702cd4369c7e65c7b039af3b9b6291b6f926697ca5f4171d09663ec4996ef72ea306dacfff04cd04cbcb9c2fb697d04f29b5111738b8e52fce3fb44d34b0894df597e1dbc00a3c4020e49850d3021167317d6aca0e745cade7c2ddb5ed8f008f27c36f11ea671dd2655a30fd227e1cfca320912ab3ec04d87f2110552beb82bf164423b7e275dbef98fd965b67ef19405a3772872143b3a64f5285edaf',
    'b427d6b159c62b6a8555950a4931865a8b5638a007c031d0445e4ebbdcb0cf28a91c06fb29eb569508b0d15d6561e5884d5842e954242caf9c71481a66c4ae0277e810f9e081a60af0006bedc5f487e42f2ae23a769e409973a10599af2a66e9691fbd4a345383c9d2276de89c4bb6bdfd170a30b1d521ea0a77bd2cfa46817f605d6a028da60b6c29f00cf538877222371e25c5d7dc23ff094f50d97bd87c8948808d2c832864c14af04ae4eb20d873157df77b867333be406569e38df5',
    '5c143074d7d2a13608d44c44ef2fe0a15d62762bcb1b7be97b2ce24d4be918d2fbd0673b69a419806c7d1f316c2811d0fc094b9de0db603f92c727f93388777384608d36217d186f9ba14b496aed4887a4328ead82a10f9cb361467182dc8da56c329f9ba57f350cae2e846ca2e579b0e64c1cf34e19d96048c4251dce29d9aa6150ae79b72fa45a5ecf4f75b3da18a79abc71d4f472aeae8aa733a361cb369dfe4d3bd80c257fb34b5f26437f0e5f75bc51cc7fb2270b97659b54f67ecf9c109ace6260ade8b047de850a8378f304b927b79684da2c43d0525f8f451e0c9496f01a1b2925fb609a55ce89bbbb93ff5585e3e1e1a8a99a0b95f22f9bf7dca424',
    '6659c12b8dd99bb2a98fb94c3cce5c62fabf163d5aedb6eafe6267a7a88c77ba0e9834cf3d04f3aaf02fbd9303fa3ac2141120c3c14d452d18d475d3123790d02f332cc01fa6fc591f9c5d3149fe7f2afaa1d67ccd3825adc2a3ec9e85758a5f46be08fd95eed316684677dea66893a3adc8df37c105455c675052e575cd4bdfbd3218ed26d2d74ac81bc26a7552601d5ff5ba9ac581b9cf9a0e71c6d2e5597cc31be91c8b1876abb2cc4ce3f195660e2999cfd562adb982b8585d6a1786c75340bd4e978dfd2bf4df10d7d24b75780536ad3aa3de8e34c81c47c0f808b5830bed9462f85bf7d40f183c3f14d997b6173f38eb0b5652e67fda827caf076e3e7321b18fa11d5818da28f395b49827ef874fb752a9f0f51e1427649ece6da0080e317b4cbfd2be5d8e2af98f170b9aca96f0cd4ac4241a02f51bfcdd9fcf2408af7e30324aff4dea25eca07b4b5abafb374644e257569be41deedf6138924fab6a2b1b174c7f8a77aa543856219f4f8ec574ced4adb80f5519af7ef30d5e49ae5052e0c6ee2c3eb66f67b8070797a9a59f8fa4200d209b3cca44d85288c128db10d7b2760e0e5bad775b61973a728cb773868b2922186fec251e82953b4548144e5a597a8f75339fbc9d21c9b08ffde1ae9319ad138285a730f4e4c244806ed3130bb9bb39400fc10ce552736158772550a44cd2254ee2d1f9442420b60ec65829',
    'ee6c40b3ed5280f9c9ffb81a948d506e822bc929298fd9d7c7e55ae566bd05ddbe05f3216f2b6044b5dc7273c5d19d4a390264e7d9cb271f0d22afff33918a476d8d70e122d88410ad9ba1825c1c0578c651c9c79610637d0b2858b923b39a77c0f16d0280ee2177c998413090cb791548221b57cd3fc6c2a693c3f943175e36f0ba1b272a213f1b428e91cc6394c2b44b3532ed85e2612735e6bf7d97487744bfe2590d91ea7631985d4a26985baa87a5aa2a45fb19c704d9c40bf0a623',
    '62a626deefa95cb117af6a9ffd4accb19b81457406c4b4e3942af94bd5327679e05d79fbaea91e92ad8efa00a6427b4a6e14459c72e70e2f7aa6539d181492945ea8c77142efeb8ae343d5028bd894c1a1a78904cfdcfd4bc4ee4ce4376ee64b96fd554524570b6098128eec7b9d482e7cb9002e77c24eb27d2ad085b6ec13d7c35ef206aac4a22e7146ccbe6a28bfa13a7db7b00963bfb7101036a2847b46dd4c7b0586fb93a9e0e942c4a8f707b6aab318dcd3c8e07b7348a1a51dac0d36440edc766534ac1916d42f9970f40c7a4069d3103906a96134d39a33d29334a086a49fac6ebab607c81aaa36f16866301bc4cd37d762824dfa853ef71c7b244794',
    '2705ae613f3448f33dc59af7e24bab5524ae1aa2d6c353af1b30793be0962c5edb6d1ac07ef2c08a1f075aed1ae7691ded2ceea15cfc86735c526cb526dff2ffcb01b822676fba02fd2ebce9a52c9f9c80e0b361e04c38d15e25db560cc80d9405ac7ca79020471720eac93bf4f5370a34cb3cc4fdb226d7c531e1f6d5e3a1a49f140e4b187a6d15ca6fa78a5e04690ab4652db56276914fc473dcbc05a968fa009fd9bfd07a6392b8f3d1910a11df1c2ed27e4bf2befb11a510392ed2f2e1399d4ecfecefea698911cfe67dd76d48084e5761543fdf1f6bcb0633d6e0acd74def71aefc0cb42b83bc32c749163e04fc69fb8e267f893fe7b6d87d38e85648bc9d0b9dc7519c0ed867f0edff518f38b55a39d28e0551c4a35b682afe668e124768c37a19cea829cea112cd97e8d5a45cf94b2535a75d5c9e8dfb60297aa3e803a6dd43631297b0a21fd665aa2436df4790b7c08f0ba2610be86de70cd4e45a58461eb69f19778f45b4cb766cd5d470fcaa924ee022ff35edb5660fa9ad88cc58619c03ed55b33fbc58022d40dab92604ee426a7b7ade691abbfccb99491caf20dee368fcae50666f3c71c6acad2574c7982261874cfc6d39d2f21ba3ec4771581278583181e94dfc5b02f88f201d7db9acd8ec82cd080342ffc99350025c5fb3354b8a81a2e1014c5ca7fdbf9ac75285815c540ebe4a401a716348abb2f40956',
    '9f457291dd633b548bcab77d7d0c20397813fca45077c0ce5b28cca215744260c08055264aaa27848d4b78b1a8ae57ce13a420974f17db2a550bbd8850231a0bab253241872112556fcdfb2acabf461514727aee1ea745368e9ced9beea69329e8cc6129895cf65d5f454172e8538df22c5580edf477ab15f34a0a187905de9d4d6dab8121dc146794001ebed67e2e5f9b5e94e927b19f9e8cdcab127bceb56f04ab5f658538a12cf6ce0e8eded51ae731723023ecfa21a2014bd33dedd7',
    '66265a93b5feaa3c1fb487774c817e902176f49b3f2135363aa5b3f1f34fbb2bf4628a2cfa5a93dd5f8591cd99c16452bc015638366d57167ccdc9754c5de3afc6473b8afc0639e9bc3d1966e042f634a8a94263ecc7c16006f34d66b98e985efc108fa65607cded9b3af08d5482d8bcfbd542cfb49433128a880945c4efb43252b4fec612557f51fa28aded5596c40a884a7067054b3e5f9ef4123ef962415a16a37545f8b537037c47d516d1451454bb2e70faea6ac7897f364b333f7fe79158964cee5a9cd0ea11a698feb125bf5b43adf47aeeff90f9cea9718a4ba6c560948065df249ef7f8626e4d4e6262d87113420e7ca281158e0460fdc27e6c02a4',
    'f5b2e7b72a63feac67e53b6c7b5d2e661e802dd1133a9e6d4a09f405c21346d5eb27fa09d9a9757e19a9099389fa3b4e1a96d30b36870b88528bb45b6c3b41a4f521efea4317a5b2c7218a6aaecf5db94addd451b80749f4cef99a2525cb06f9977b47170614fb5714455e0fec8e7ea4d99c597f6dc2fd8a7b155190d899e2f23e1bdb2cee9d00bb0171a3592b59b0b73c8ed221b3c5271cfdb21670ec2ac9815121cd6510ddc1e92eac92e824721a66a5e9faf2a1d09271035f082d15b4efcc1649dab4b3ce97e1411a1b70876e6d1a9c91668333e163ed831ce29e279bc4da0d31d4677be204951bde36eeeec8de9b50b57246a3b986d5d39309d97c9e029941a368e393f00b9b9ef3583b5c39b40006b11808ba562a186dfded9ddfd19141c7e215cd2dd035af91378ba8ac7070a64c48923b24787f694e6aa140dfb8c677dad74a09fb58bafb4c4f8b71bcd357202010f8b97df0fd2959c3c669047c3ad5d0e3d82f504e58e88d8d2145bc3705bda82880f917fb9ae55f049c1b4a8e12dba87669b2018227752bced5c0b1e18989287230782eada1e2345c27fb3046801e38fa80443469f0691634613048fb6f6adec33459c63adc0007b037362c927913bd094ae7339bffcf2b6b969755aceb0379e1a055e39e68641f6a73db4ccc22eb9683c91db337a951156ea5103ab8f49bc9452b5dd054e05d894d5cc4523ce3af',
    'b0acc52d34c9a8e9b3786e7d010176bf928e18c1c9b160e10c88706888b10af384744338453b2ee13ac86cd9e6c9f3b9bff4e3aecedd90a52b25f4b590a41d73472ae9ea3c8ac714be605fa83c6fd689e59ad83f4d7f4521bfed6417c992d8a1b29b856253b5a8e28068e3695bc4614b10187ea3a62a6296f0ef159b8e3c6b4b057f50d327ba953df22a2c3a9b13d992198df9a812ed6fae9c28a40116527eb276be5624105ee8b14e5ca20dd4775b83e5f5ecd5de8840681a0777bee843',
    '0a1498c58efde5d6f5770a7d0be1f974e3f97410375277cf67d2608bb4231bc071bdcfac6be78bdaffdb0b1184d936758e0f4a896a9e907608bda6fe3ac7a87a740a2042b2544e922f2bf150de6267fc1873629ca7fa868698432a1bb7d797659ec7bdf04da8c213cb3720db9650723a9bc0e1c3a4ac813f99d6fd76e60e4faea0c1ac12d7e3aa75c0aa1ffbf3df61ab26c337edca3dbb5bfa8b1f9e9339c71fda6aa74ac45789280d59d7db490ea7643b42c09ca4cf6f46e473dfaf0b516b4ed43047a5ad013b1327aeffdf8deda8c5efc6d00e1dc7eb4f336b2cbf6b1a32aa2213305d9170bef89fcbfd46033ecfa3b6f44785f6713e60478e8248fcf67c7e',
    '6b11e74a286527991aabf37b3e2828c67b9a981d0a5f0f428347ceda31a6b2da2da662cbe5b32df796466783b188baa715c547b505af000928de5e5dcf43e26a5222113a8d17500adf1ba299bf1e92f7e5a2eb4fcf855b61f0cb45c074c9fcc6c9df52a996dd4aea157263c0339a036bfffe215e21bb71772b9e1d529b63b16516fed883a7027f7b75c7b8b91b135c0d60e8acf4b21ab4722cba4875602d4d2182b0ba3357f5c08bb31ac3a0024b2c99b910ae8d17fd13fc6421fc194e7914371515b7b31d41997f14a63153b28137d28e1357a46875e6e6dd92ad0d0e8901066501fbd6ba82aafbc10e771cb33d8700373febef670ed92cccb3e02cb243df82d5518eea7da76991e15226ca8429ba19dd2b1cb1ca62fc94a2821e9d67f25dd8eb6daba52c3b7d36e19b6ad8c22f6456802820c99d3fdbda27c829827988a44a61988da3522fa9601c47ca472c0c2a57451adff8bd5a429f2d3cb2139ac29fca204634adf6cbe6114191b11c69351f79cf65e3c0990130d6fe69930b799c2f708e0f6382c242331368c0642750a2502b1aa7bcb5da916e4deaa089e4f81cd8714ef5cd4741e221f8fe5a1da8c5efd8c36c21748a8b650763b93b31f3fb31713ffedbdb64ed3b010d7baf1d44232994ed4b2be9ca53cd8609c14f5e131b9c2b801f7206faa0c61167a52dc6eec43fd72f7c4eca2e2e7749eca152e2fce94d3558',
    'adbc2a0558e72944ef977ba4b7a62e30ac142044444686d24ac15474d3a05dbe7c104a48d13ebe7cac64a27e99a9fa5bde11e8b02371bf210316e641ae783e5beab0b2fbd87e03a29358acaa030902f26bcdf35dc5a81ae0dfa230337f072bec7374115f3f97caa46adbbbfcc4a8dc05aa9001887b212f0f317785d8ea7c25f78bf4253f1576b1d3f4d415e0cd8ddabbfa8f58a2c177cc58ca7af21dd5793b84c9153d2dc6e92f38fb6356a49300cdc361e162d5d05e60ab0d2f21377541',
    '6bf5f7b436736c50bccc9722952aeb76d378c1bda90f37b0f9d6f0b7a68dfc0508e1d899197c90874c4aedaba43a169a79fd44c8a3283d2b7b823cce147cffa71a0a9d588363546a14b2f67cbac5daae7bdbd8318fb38f30dc1b26f14610976ead834ccb76c04b64284ba3693fccb8cf8dd75b6692c68d279df0e4b8799dc5f9996ab9aeff0c1d42d5d4402404e002e2ece9d9b2660ffb5dc551cf21107c9d3ef5c025e275072e48be69c7e42123e9e8be880ba05a6063613cf94ab4568296956fca4f3b834371d9474eb368bf0febe503aa7e92fc65116bd73a97fd6a1998a910717c704ca3ea9abf4be9145623a6055aab7e8020ae70ebf3cb113ee661f948',
    '90ffb0561074d2eeee95376ccb9408ec526fa6f9bdf82fd629d12c9d5db65aa4e4ed93309b14d5b0e26b89d8c5704a2869a8b7f8c0b4b75a31dd712991db74c11dd1ac5d0135953c1775db08cf8f49b1e1ff89f32358b1a9b3c6a9c9cdf8d4ec500ad90aaf00d482f1b1777e94da8cb86eaf06c0f1c0973794a29ba202b6651faca1b265b1aacbf0f39e7216c9dcee441c36dc790be58844355e2b04f5b9295836484473009cf5b0693bc9cdc6592ff9f9e483450d814558e535291433c46619c25110ae793feb5b0b62a5c95b93c8f16beb73028d62bbaf60c210440aaa4191a83f25b8ce410defe3cc18372df3cd501280fd971152fbca4d9621db1c58d6ea364acd9c2daa5969ccab4ac701f6913dcf74c6820e05cc8175d33357a3a04c8b485fc81edf009f94a960892935143d13cacbe95298eb0d9efd7ab4e47e250d3804c2464e20e420e5f9af3fbfb2dd320c735a831cb45ce41b86e78537045f422fd66d13a782df8f0b6180fe4b8d81cdde0674550e6547cd6ba1f773e2b9397b3d30a4abd344f09188346957be60783f9900908cc832cfaebab9c19539444da09db5f95bc00ce875972403ef926af086739fd96ff99693eefafd229b3f0fb87a34ad8d6e980d22b15a6c4553e5560e5c4918cdf8e63d2eafbc46dc545b59cb887085cda7991b3de5dfe200cbc5d67ea6447ce9bf8a450cd0c8bbd3b9110ccadad4',
    'e62e3bf7d1db5524d4a1b9512c2ccadf00e719044dfd4428863950cb1554da30abd850295ec6ebf01785f3f92121b5986fb7485c1dc49176eedf2254902c7d0c26ec91183ea1c82694d485c2a0f230958c4933a1544c160a9e26d83af872744acf8676f14cece62920a9a9f1b0d9513f03c0b9f9aed423c1baf596239d9b6a9dae368030dff337cb3d68c86daef0b0913962eb5159e664d9f48030556f29aa16502a71576013a83b9b5073140405bcd935c4516eea7d348c150fdae45362',
    '64325fc7cdc5531a3df823c994b32cba4e1488c86b75a580a773c0a19485e5c05b72bd0c511b872b8e1564c34d479914ed1cd222c981f761db75acf29dfa09db89123fa36714c6fa9b6bcfe26a73b82cbe8057af52248a8bcb33223b07b7bfe3791c720e4fd12eab46d95d17c70c1ef9b75b7df9f4d6162ecd51f8e16b23f644c5aac68fb1a447758e75695d1a0d1d1ad5960441b0122595b7eb9d3dc905dcb6bb914ab11b4e19f2c0f570db34ca02b1aa9ac62f07cced81a0574d75a3336c6056e8593366153757ee643a30c820a983f57b498691cd18a63f8f65a370bfc1a3d2da737ae783ab1799116c6cf0f2a31fe64eed920d56b37545fae99e4dba1af5',
    '170792e80d2a35edd05e1f669cff5bc1bff3dd33097626ef040d3fb04c9efd8d435438051d7a275344a43ec89c609f384b86d2f94bfe2ee169f9495733c49295b854b91217da893a9f7cf5da93a0de87c6aa5846719801c36637282d53a511c9baa3018e76b8cca6d4dcf4dc0f0905ded410939bd1915f0f64b8854f2aa8274727d577339b3979188b6de61bda2f21c10fff54c20c3af037d380082fc654e8ebf27264dbfe44349523f69bf80717defc764a33f1bd5fb5d96a2aac93193c04cb40091c5d4726c83a17a4302dcdc6410b9115e4b0da5a8d5309663b15c52cce4ded2b96e765bd1c5858ba11d565994d8ac93fa409aaf076aceac052e02b9a17d0be64ca8d65023ed6221f030daae8444ed755b24a19dba8c50bb5ff979672306bee8021f45fb42663fa5975bdc9110600df93f841f73c63ee3f8bed9447a88455c81bf5ad1a3c589c7e2e39c57fdc637704a9abb693dc9233d620c3db64d1538ee4b461719f55dcd4348353baaa88252ecef04c67e85d793cca2c18890a036bb3bfc0dda51c9948c86f5c7c363ad915f092dc3e9108c1ba91b349b568706a59278d0a4b75b7278804ff38648516cd2ef534f7d4185797bec5cb8fa8692c1ed16227754a17c294722e5fbe40436397c63a399b5a85b4a3d1b685a11d5848305cf6730fe052a210c352c820740ea19475c5fe745db763f57e36f3738981fb11ad63',
    'c27cd9c9e1d01bd6c83d410b8884470cc11cd10e1639f9b551d0085f68ebe2883f2714f4c6ca1819e781806983ff02d31a00a3fe31144a6eebcb3874c819e1c86f66ea04f5949f35548f0d649cb8e7bc4a5eac5f58d1bdfd21b79c4bdf374cf458dacc5573ba679fab90b387225a451152b49895a80ed074f7391c803040e7288ecdb63a7bd759d9d03a872a1a6fcb3f1452d7a2940837a9ef97c1b8401a4e71734e6a4a2671dd55720c6e01a1971cf853d2cbbb60c4e57244309f7801fa',
    '24620e2e838350a030023f2dc42bcc20d43713bbbee7d6da1ea5559b55902a89d9dc7361e06cf544a77600d904876410724d04918e66f7f736de2983e350fd0f77c77216287f5fbac9ba99935af099e1a03309be8ee1cd676ea7be4e3f64c73fce2e8501176c0f5d1e7cb7262cafc62d84534bf7d6f3747ba86ffbe657cd7f8bfd29bd21ce79d0b8095d86227740ec9db7dd687a1b1c8430df2646adad2df2c5c724b23c807bf2cc689f1a26274ad960667eac5ac91d13d76bd8ea246c90b04de59449edbcb5a52291e6fd54622200698895fe7ee28f9a907176a42934dd742550e55486526ce2739a2d6bb0db36d4800e0d974006e929ae95fb056db616830a'
  ];

  test('OAEP sha256', () {
    for (var t = 0; t < vectors.length;) {
      final vectorSeed = createUint8ListFromHexString(vectors[t++]);
      final vectorMsg = createUint8ListFromHexString(vectors[t++]);
      final vectorCipherText = createUint8ListFromHexString(vectors[t++]);

      // Verify successful decryption
      var rsaesOaep = OAEPEncoding.withSHA256(RSAEngine());
      rsaesOaep.init(false, privKey);
      var pt = Uint8List(vectorMsg.length);
      var size = rsaesOaep.processBlock(
          vectorCipherText, 0, vectorCipherText.length, pt, 0);
      expect(pt, equals(vectorMsg, size));

      //
      // Verify unsuccessful decryption after vandalising cipher text.
      //
      // Flip bit
      var copyOfCipherText = Uint8List.fromList(vectorCipherText);
      copyOfCipherText[0] ^= 1;
      expect(() {
        rsaesOaep.processBlock(
            copyOfCipherText, 0, copyOfCipherText.length, pt, 0);
      }, throwsA(TypeMatcher<ArgumentError>()));

      // One byte too long
      copyOfCipherText = Uint8List(vectorCipherText.length + 1);
      copyOfCipherText.setRange(0, vectorCipherText.length, vectorCipherText);
      expect(() {
        rsaesOaep.processBlock(
            copyOfCipherText, 0, copyOfCipherText.length, pt, 0);
      }, throwsA(TypeMatcher<ArgumentError>()));

      // Leading zero added
      copyOfCipherText = Uint8List(vectorCipherText.length + 1);
      copyOfCipherText.setRange(
          1, vectorCipherText.length + 1, vectorCipherText);
      expect(() {
        rsaesOaep.processBlock(
            copyOfCipherText, 0, copyOfCipherText.length, pt, 0);
      }, throwsA(TypeMatcher<ArgumentError>()));

      // truncated
      copyOfCipherText = Uint8List(vectorCipherText.length - 1);
      copyOfCipherText.setRange(0, copyOfCipherText.length, vectorCipherText);
      expect(() {
        rsaesOaep.processBlock(
            copyOfCipherText, 0, copyOfCipherText.length, pt, 0);
      }, throwsA(TypeMatcher<ArgumentError>()));

      //
      // Verify encryption operation, can we reproduce the vector's cipher text?
      //

      //---
      // Do not use in the real world, only for testing!
      // This only returns the seed value.
      var fixedEntropySource = _OAEPTestEntropySource();
      fixedEntropySource.seed(KeyParameter(vectorSeed));
      //--

      // Does it match vector?
      rsaesOaep.init(true, ParametersWithRandom(pubKey, fixedEntropySource));
      final ct = Uint8List(rsaesOaep.outputBlockSize);
      size = rsaesOaep.processBlock(vectorMsg, 0, vectorMsg.length, ct, 0);
      expect(ct, equals(vectorCipherText, size));
    }

    //
    // Message too long.
    //
    var rsaesOaep = OAEPEncoding.withSHA256(RSAEngine());
    rsaesOaep.init(true, pubKey);
    final ct = Uint8List(rsaesOaep.outputBlockSize);
    var msg = Uint8List(rsaesOaep.inputBlockSize + 1);
    expect(() {
      rsaesOaep.processBlock(msg, 0, msg.length, ct, 0);
    }, throwsA(TypeMatcher<ArgumentError>()));
  });
}

void rsaesOaepFromBC() {
  var vectors = [
    Vector(
        '65537',
        '18329217279129047599928806658090795218965128603117317816991794458216724011503245770495015436599417624674453700179115901853297370103589780033452305875387523631943137116091358449115603692042654878721127101284026952253675215007943515373405972137692442962135092549484760763266587118899791409102037013921404939390181223751472627827705346551953516256888392767851186631216835634474071675505958586396771252034180754174943415153548216160756132208337030301019869021256167058990556822778603285874688909024436599331568169985447428984275783284744039529640106023038139189061819173687874637953173824018096822256369541752055251546359',
        '871474755355999089390392626250986738823799391600371733795358828322982620807240395820108764521473142171377965573006471919295582727967190359403655722839121773000515971950816682598291363724383365153959321415399361936348199794997512762310343915361546184140454222564269260697601133138406549441719140872775650260752864939310738163191807920999918084807656911787448990430355564553967601350369480153793796995880979379659219366469559690644199335318891335629688926962152206313343604012636149694175054409987470880735437923545376913490821847333390299732957408602797271633303370756312629740218231012737703014343181534686846307393',
        '18329217279129047599928806658090795218965128603117317816991794458216724011503245770495015436599417624674453700179115901853297370103589780033452305875387523631943137116091358449115603692042654878721127101284026952253675215007943515373405972137692442962135092549484760763266587118899791409102037013921404939390181223751472627827705346551953516256888392767851186631216835634474071675505958586396771252034180754174943415153548216160756132208337030301019869021256167058990556822778603285874688909024436599331568169985447428984275783284744039529640106023038139189061819173687874637953173824018096822256369541752055251546359',
        '139938602947854926673274376453107989073071827438226512797650594061983297161783711276901852736597785930143401375196002497817729904598157413814575098620989414422686350708665981330220682164718216656819685880412277133946504812497734067927436542166773583464532860288061057630436091686749633450714718228505170499039',
        '130980422078095429561752625252772990524110726095230822580220780407796115924674034028988759464767902261255001063231695869052365128259353804033624087488011680139885948265015821069772931331044159596841425313188756863343401896929103897656562392424149690632009352791193293004161928133083118699425976206871054587881',
        '737847bf7c49b797e0a17056e2d8c0a6c2dc8a4c3a255f3e011cf1ddc744025333734a36be34dd4ea4fb187b93580f6844dab0fc89465ed520b56c9cf7f5a448',
        '1c10adaaf46a8a7b0e56b9093beda5d88b5e08cf35ef2f4051c3cfee435ec41cc18f70abef80d96c20e53b01f879abd5e5ce5a6029a244254dd999ef0f1d84567035eaeb88a3770c6890efffaa4a00d8e6832af98e22af0e07dcffd23951016e71db04434db2601384e480cfdfdf13124cffa42479c7f5a8ccda04a05ed864d2a588a3f88ee5733640e7719514ac26c430717d247610ed8848eef197b8bc31e2cc248d8d78459fab384abb5ae525189f0be0f0d5ad50014d9577cad7363c0be0da1271dd69ad75409bf7a9f9f5db08327a87e4d021f04533a397e884dc731627e25b862d09cfa5abd00771c711159ed6c6b64ba63855e54d018ba6bd177f12f6',
        'd791eea439318769a5fb4e593c537a211c509c4f2512b4403f0e1e0b68a31924525ac75469bd0ffd90dc58f7f24a6dd4bdf42b451dc5601629a76259d4a772ee26005ca45ba401cfc58dac895f4d145cc909234e2b0cf970679fc27db3bd2f8fb0a427fa86d7e8707eef1d749ff96b3837404764265cbf8f667d2f0458bdecc148855fc417de77a7031585091b2dc5e28cf0b2c0466d6ddd21471c4b2728298d1334109f1ca266d1a325bc24a96d3066220f13144c0deefea4db897670e6a98e873af91039564946bf1fcd84c0c77ecb0d1144bac6dd0188040b194cf03eed651d10b177f47aed560c2716c5a2d6a66ac3a0abf115e49ac387158bda372004feb93c38d55fe848eb8c118baa2aba44347de5a5f4b0e98a21f94feaa3e4042526607837f7f6b39206fb6327535ed2d15c5e241534975fc8ee9ab2179a530c8618b36463df692f61e06e9f01729f3f4d8e91be814bc05b5061f55658c6f39dbf72e85936a79f41dd27376579df4533144c514f35e407e72c600cb07430d839ee1776968f25e8b48e7a76e27fde1b17b8f4c366d0f3b8e5e7223532ab10bbc40ef708f2f9d94f0752ab6a299c4bd3aaada46a520c40610eb0dddb8b2c23f9c24d83fa131876d27fe1de046ea23dd31f1b5491dce981b15e4702e01f6c5902fc237209c56994426b07309764649eb1a286f0c8f93033b290cd237a099688a02760f09c7f079af95dce1564e99ff99169820a38adecae449a0b27b8f88779443c251cc301a7208dffed0c5e11d0749927390bf0200f1199b8062a212c4a5b913469b400585e4a32572594abc43528a5f580cf3900045e4b5aabe6bafd7ed293e2f3684a09c58629f17c7844215f4e1dfc1baadfc4f3dfa66cd6fe96b3765352d4621b2b37f75d83da97d1b6f1fa97b683b0c5e33e22b370bbc3d49e44d694ae5eedaee5b54057828d8b377276115a8bbb0718d86941a9fa0075613bb02476b2725caa2f951af799f0b27cfc99efe18b1b52dbff6f2de28deb346ec115ec7d83a49ee3ae8ac6203da2ec82a28190947925055500f98a258d0c300e9536abc13eb1dbf6afad1c09037b2d0893a35207348ea0c5cf6b8de71f7b5243c6c5840da61544cc14aa6c94bfa085710057c685bd9705f451410b69ae93c665ee2267d44661271ef5709d9cd3f63e82f5babff5a388f9e04741fffd3bddd774269abe4738777d201ce7475e1c0b81ab8a9627e97b9ca9d22492580f1a732423e948963613bfbbe41e167657220f123df82e6802cd2820c0eb294ad0a893d13ed66cc32ad5da596de7656c432b00a0cc41299ac5b4df92ac216550f51d077d3955506aa27860f29d51487fa3f91430054c2ba2b89520d9c33095ca02a727b3278fa5cb4187e17baf53983bf9e55c86bb5c432bd4f0b1072d2c2f9adda99a266e9a988392d3877ea4',
        true),
    Vector(
        '65537',
        '19569948865068536220796258723086637852008297300026106349963994132199477810199047175899658629239003270723655738566573526731538394167442667834888430144306066982129214011881836514687558246034685766252347057089991537170837477708330723082763394365944677788766871193438382040109729808702973595504627972224944777527374865550366057217706136258645711267799610223058431864733347367267901540839952258620469468571043208682852319667438096213018666218650237356899215935657286247127436286944431950409154631150939504050756036262766929390373805529061561721863375350515301920898024498859456381733320558487139634893131924469609086155977',
        '2682331479434432362441942613253681068177175222726238717291592051680956700788340800148201146707915477212764065880478025348241855901362522307915285195824729895840841008365222194368214349673742673097689404871677395677576641483200448643845352712829234698064385190241521984082208148666045685109467887109626969503204467048981076846824468472108268455623568524243811843709827875184517129418949264059283188441904126749091302309131019673249568789886447460474056002292397200076608255581488013318454785670653593214955554015114552210995629053705858542326148168308882683141875279870689522709904562759304842005687816887434236438205',
        '19569948865068536220796258723086637852008297300026106349963994132199477810199047175899658629239003270723655738566573526731538394167442667834888430144306066982129214011881836514687558246034685766252347057089991537170837477708330723082763394365944677788766871193438382040109729808702973595504627972224944777527374865550366057217706136258645711267799610223058431864733347367267901540839952258620469468571043208682852319667438096213018666218650237356899215935657286247127436286944431950409154631150939504050756036262766929390373805529061561721863375350515301920898024498859456381733320558487139634893131924469609086155977',
        '145835548171723582860236439983550505455458319012470930607600001888971140083509449385071620383937906218977079837244074075213020960325842524264393644936862389772991896271099001511991775592998084484547129514354779854138169376007322466721134239392894573044786118173646871095974390695636022494704640684100152620549',
        '134191897040251275842789384044745185132072042826768949353713249326752714554591714787345489954150944972550569831193756481324390655581570283683976700869116039434467184801636650007449650971637165464898935582726540090128314754515834948172908500679141710373727071021688918409017946527796904483060335428738729149173',
        '8f16739968fac7fa464ec3877251c8de49757cb248bd59cd9f75c3fee3b74ce6b9ab32be1e5dc1177937fafa4a4d9e171b141efb929e962f0b070eb68ccfc46d',
        '555878e6f80def184ebcb1e75af080febc0c2e5a2335880371ad8f399944058462672ed6d1c5ae1df76c2ea87c15b64392aa4e104cfa3c50ad481ee87f1ad183e40852dcbfd3b9edc68ad0c7e9f761b86ffd3ce1afa7ab992bfb5a2bf110e91eae8cd137cd494564f841fd542b0d0859f83d54f894476524ee7d432a8cd394fe78025221045908036423354eb14e8608ffc08960877e1cbee573b867ede2f767ce9156d18453b6eb2a71a8db05c6e0fe2809aed3785d86c01f671d87f1dbacd220053a175bd983f7a75d275fe47d68f232c2263f5ac52d09b59710ef5036078ff678117346b505ee3b8657826bca741cbab45ef7459dff495590ccf1c0220338',
        '61ec0b784fc5e0be21617a983c692fe14cd37e2201bb746c0d8ca9d41ca9baac0fd000174647417310ef56e16f2e2ca05839e0ba406ec175714f228ef990c739cd3af8585565203451020369326d3509eb950f0f68df0525e7a62e71d5b0599542f4c47bf4ba9a79d5fc819e897d2392824fc27109022d90baf6e07061ed21f22650c6bce9a8a465adcc0ef040cb602ad71f53941dbc36d9499468283591be66ec06c8a8587fa1e40068ea0cfdb30cce72eb575f296f3cc6acd4e0fb7537fe2680139bd11931acc5456e8166ecd33df25713ff228516b3b3d8e71c3ba0f725012b1386a7898424864eef8334bb6211c52cb8f6cb674a56f495d7e0890eabebd5cd1cf3d2a37d12ae26985c520139a3bac61a8345231a35d6914bcf4f82f52147b81cd7373ae91a3d30de04eb74e7a0fbe335fa4104fc83ed638c89d24c38c79aea676e23fef0f41b21d16b775428aa1fbd17ae95810de60ad476dac580e61baf997e69639136ed64b00a83a9823b8eed2552df46c32f2baeb00d969c9c9e3905d01ec4f44544443f94b360c088049149aea4bed3ea067a841b254be03cac97c6042d76273f44ea104ec4ad9abd5bb1a7f79e7fdc8a1215e20b2b4116d153f7be73b12c449844db55dfed0420130f411ca37cb9466b6c367efcb096b236e743cdd03a49c2497ca7c41881465272a2431eb836bcdeb9fc695ea8918a550510650a594a9528fcdb4eba17c7cf27fef18a2def9d97eb10b6644d4d80ea2390fb90b1b2b0120b21ee4b3600e392f843a269658bd62a9a3633dcf324af6d4193db925df3db4f05c8c37bca1835ff778ef0eb6fd6102cbe0decbd4a6383a8fb0bcd22f5f46afdeee4698684642bc9b3d4abd56df8beadff796ace4a1c22fe91a1a54213ec6e3a16e10e07b8eae6054d51216b159046741a9ad513ed9f803f3744d419b2232cdf47c4d098a023b8fcfe22a7189822fb05656b303d59052570087ae2d4a881cfcdcf606d31ccf9bea6d90e8def705ca1184f727868c3e9df25c0e92bb4d82bc17502d7a7d3f7eda05576b8b62839cdaeedf0cc8414dd39965d1938207fb67a4db98f9e0d07d476535273dc762d8b688000fc69c93e19df8f356637188c0e4e037d747fc86689bfdcdea0a1bd96791438ec8d1839df88c0c91b317309e5ed551da0cdc149f0d44b1fdda38d0ca4c2a45d2a486717f4d0a202c19801fb88bfc3639cf5ad943afee6473ab43dd6c7b63d81704861f14a2455b66854cb9765d5f35a488efb0daec7779e3a558f04792ecab446fdce65a26b07c324581eb33fc02303fab6f57de244a6b3461ea215c284936be8a6010a909bb48a33526553c983db969479a58bc89991bf29f0f234a0f266d5e3ada6eea2753f9ac11da6456558f078e23f44712c6f7ba254b4bcc5b1bff2b910048064967031b11924768ec6e3',
        true),
    Vector(
        '65537',
        '25038673729224910830580845003347508937183878430568252243060597923803411041332607392164911183519327652692450873138929631978784266430522568470440784639525241788766657600645728222394583470757090752138061009477637438276248151511155162669718467468969624965875279908416587064343777130044791689157602777585816549468054593978537853426172535223238597429205435261183451278722801708117303065362678921575924256921065606924997047752902527599978846787772561984540047895607090694150885414144427290157212302653880114246899270943264626275367221662673432429915006601395866677114630755313736395334714474264115548734012399991539649701577',
        '3665330669541655679705891050107041272351615632288084135020867774409707107096521082267758924987236975571329181442186950223483857303017011631037296147755394485725317322370492319355448604186579175173177332036499750880613328403194300042153463650768685468000762418502092438600303825951252273797332066580159719264783444433878126847045099946979594428364397610142426110395907309438977364343811577257119310923578509600802934471264322715095052241970187830259542463962252933510334746936487458581694276279360082463055558123500983154145931168559475784322023134231491373519253341861719350553980757285805374865832745904859709420973',
        '25038673729224910830580845003347508937183878430568252243060597923803411041332607392164911183519327652692450873138929631978784266430522568470440784639525241788766657600645728222394583470757090752138061009477637438276248151511155162669718467468969624965875279908416587064343777130044791689157602777585816549468054593978537853426172535223238597429205435261183451278722801708117303065362678921575924256921065606924997047752902527599978846787772561984540047895607090694150885414144427290157212302653880114246899270943264626275367221662673432429915006601395866677114630755313736395334714474264115548734012399991539649701577',
        '158583983905122960678499673913480078252467523039334679557106796515538961502086148476206838376197850276185195302545375580630295818784775624880828695801409778458680887001891232052530710022670791150445348537084374277944129929052319716841620177999129668752076023437539741074161532918847704356315936511958042206421',
        '157889044736099932616410509564681645236482925020553863320318772062766368147198184049572451248600417630406962137054228993505221845131088005864338734847330895786869459001654903908616676980872205245637285247625574944835533063249009575393914877011929175520203590185877323732215545619943872773049618568385174784037',
        '6b857a09b8d1f3e9111bc397dec0c2a6f7fbfcfe8c3c57463401da788dea9395b00d9ec7d4afda75ef3d32756fef370b56c15c90423d5fe07976c6f95f94517e',
        '84f754144c94f2698a72b0725bb7ea141405c0b945b740795c552c5622c2886718483b15d00db96f921dbb3684144a408977396309783607cd4539ef3f0c2682e01e526043786d521ad8f34af4a6526bbd17e0fcf03b7b5357fabe3d0b90cfca14e0bb7e6001d34b78d7d2a9c64a4c192a86270950e333fde8138a19ad8448b8871e82778dbe421ba387342c57e4e5fa5137da0f6af163f0ee78f02c1301f4a9b8810afd73434c58940b27e566b164369989c6f882a0b37647469ecc6054fa01a07b0b0d50c39fbab878994c9fff176749688297e64a338f6d2611c50a0cd71114625572871c7e03c286219e03b412296a30376df0a4c9fedfed6c72765a768c',
        '4de17fe9b8d931f8cb1dd7a0ae53bb9f9be9e39cd4c7961c47c9bfbaea71070ca358013c2ad32b7dcab98106a7d7641796988477ba68310c75a7b60b9d3eb528d2586fc4dc58e0b7da191822a2b223a50c0d5a6c4a293f8c51a1087b7d338cf39fc3dd5ab6207dbe0e130686e0c6528d8192879698d5e50e4c0c6aa0b509dfffc69ca1fae12e25c47f9b5c84d90f868c2b425460bd9252e2fb786b0183168ba400967e82c76120a749890026aeb60cc0d09b965001a35244f6b66dc57f285d2dfbfdadb8c15bbb8af8eff76b552a2d3c1dabb4d8837da847b7cd44a31f958eb1bc2a06b4c5eea1053efbb1497b59f3433f63443407696d49447175778976d391d2b40018f72333e5934d3fe63306a0f43de404b38172d0b53e2613384e4dc9c2744de0a25ae1352ebbbb8273ecd7e427eed17caa4ce1735468ab425efc159e74b7b05ce77f6f4051a0ebfac8c08420d7c56f280065b61a302412bfb62717438dabb2f66533c58929783a20a8f700522b67f1191717d2f2f79235a13c4f9d795b1110a41e055b42bb9c12cdc44d0ec483cba6128c90a816293ffe345fdce3d573c5f6e2a09a03c014f5a6fe254780e3497868affe89ef789b2ab273e86aebb95508fbf0d3b3248f4cc40557f3483c3a8c870c6dd16565e368c0f7d965889f0020612e30c4786be30edbee4cbcaded196e70e97c44b57ff1768c8aedc7a6cc3b5f081279008bbc03433a5ab197fb063e1262de1d98e478c4f318f85b821369b299c3427661942272e34a7c43599b6011d3ef668b008981e1e3e0ac0e456e967c37e63e5d75faea0217df8792e084311e6f7584f2ca607aa0f68a2692af55a511c542e91956367b99eba3b0eb936c072081b26473d1d093d8280e288dd4cc866e9f648064e18f4af162960a80d1f5a2f6df4f40afca4a4dbdaa28859c175dd2bdac2996b84dac4d363e205017071835b198411d30a8c7d4344c95b1788c213604dd5a187dd3617a4225242623333908b183741d459db5e7f95a24dd4acbf6dd0178fb9484f72d6be29418bc98ead119583979fda6f8dcdb24b81f27f382778168e1960dda3957af056d212808ccfac962e423ac71f4c67176f10acccab770e7bd53839ac717a5b20eb83c7a18917ab7dacf54c461134d1d0552d43d3b918046184ca61ee111117bff36bfe9f2a286a950b1996ecd5b409fb928b3e3015783b939399c48681b96026d68c783167cd448deda74b2e6bd45ae89f245558228ba5d93c911766965647f894a9666cef9208e7b057c7904152ad57aded1b16fb7e15d3222f2d4a66fb86378f517a7ab84224fb2f864ff3973d7fde599d872049983e21ff0e83f7ce6abb1fa6e7a7bfcd695f94164b2f134df2823b5d82c0502f151eebec4170df8bdf2314b4cbc1afde6cb53af6bdc745f9ebf39af1b4f594aebdd5e1b92',
        true),
    Vector(
        '65537',
        '22377459671281353965131212059619673838961415245047239906044065787317026019550162295776162977886441782909112037021910251864823212318259140264845928628765361552813744914531741082140103654983928466248301346776937933372471886774127215995131177331827369160858191425381482384322222165889127695048650274770382571650257015391038914125990875590647465590777650206166252700879824083695711659488360010479679975024220544900609370342937871163039034870042207608160414978548690820812868418116997353059705020786146152181252384973149600694580587289841168513121028225279691504647227615589306270627773759154255872151170005378619199091701',
        '1262771250199193239695170705750588252967316429462491082872856500040463881022747458933891884783784524937823764578838153802490072827988317663907043568281990500195619548275669170816143123993695905986010138799154608888646440080322359599881323132115875509442423711840586922469823343913771147311375816743117113811116699549417259752263685394147635043038343176888699851180964135666452256843221772370051198785714917638978243596905106549255085426156569956141467273641576421455741689780300838706642238502449715624921233898996244561234414979573934875148833292288206616437008596934610483929022522521437542157563397155603177616001',
        '22377459671281353965131212059619673838961415245047239906044065787317026019550162295776162977886441782909112037021910251864823212318259140264845928628765361552813744914531741082140103654983928466248301346776937933372471886774127215995131177331827369160858191425381482384322222165889127695048650274770382571650257015391038914125990875590647465590777650206166252700879824083695711659488360010479679975024220544900609370342937871163039034870042207608160414978548690820812868418116997353059705020786146152181252384973149600694580587289841168513121028225279691504647227615589306270627773759154255872151170005378619199091701',
        '161415270007637405144210641021968266700579757366388996182532782565558011969294280148293042545882924750842202000212300412293303030249902732910614619556999585866339137201983073623280447180438077315476057185901523399059913766495765545278516852563644772868210228512955960778702649275181240366728565282943558397199',
        '138632854687307828358405998228135430179230620065196869564105040538143028810027679083228793427974907652084069830959896483528730332601255875346239443179888178294234709610895287462518258202999132870518279955448859176417653528971222289983904592090066387603120179060089069243599717364698650532060935008092275431099',
        '22f29db0d2fc5e53b3a2455c4e7377282b6b75cc46693226dc221053e4ecd7b87205a311a32376018c603a4a6fb95ab7af6c98753c7b4afcc40f677be7e424f9',
        '1624d9f7887d92f45ec101be790fae4686d2ac4299750bed54049e2e14a2f7af205992034a5ac87b83b3667f6f5d66565cf9a0a4796bc110f43738229a90a349653042021aa0b7c5b6517015a344f9456f7d7a9dd16fc530115cd9a8e0c69576e6cf171afc13ece7011f48ae30ca1ee30332899da832f31bcdef5350ff57013117284295d6c37ca8586ee645ec91fa9993f4182185634d586c573c10ed844d68ef08fcdef3092bd25268a3dba84867b3b741ac2c3069758b00a0dd255a9d7365f7106baa92aad6ead884e741ac7f60371a3be07be64b3a9c1a71bd00835fd74fd235a7ac595f06557f7312220e972bc5c57f214fec1d19dcfa6d5bb1458be78f',
        '721765d7af8d84b76f0a0bcfc3e71afc00482f207a716f8fa56c8d464a2eacbe2d5f6b714e2794728bcaf4c3a4d167294e5e285e41feccc422eb8acb47002f2168f79897ab73b27775acec2456e16eecff5b2faee07d234772ea7b2550dd984714f8b081f3ecdae76f2e8a781c302294dba27d7460f47240d3825f212e72616b2b0fffcf773b7ce6a4b837fa49ad185231ad8aea42c1c9e684553c7662ee71a554960863edc2956fa40851c81c232c462c89114a76a2914a03fb4a7de90e1e5458d34436a2ad5ae9efb831da45637f7f1c3dc545fe240ddd306ebd519477ac0e3fb32406fc1578e6fd67638409f042eac6909030c0a8d3a2a4ba6269612240e825b63a7936190bc7c28d597c0bc3ce17eb8279cd476b40b503663eb2bf888cb7cb18473fc88de4904602430e99b5aecfd9c77449ecce585d54b0e6d47704db5c187abde4d0efcb2d297d9aaaebe3efb66cef5185f35c77743fd7bb2015d0c6d42700012408a5e39fe2c5de38f5ef1fe20acd1e4e1d64b34b164be5451394375a4ec4485e698bb3627460338836c643e8efe6bc0d38980c99067fb99af72686adfb01710fe85a3b19c155e690df5c0acce6b4fb2228dff33cfb28ac1bb67717772268bcded83a154c346613f56b00f79fcd316c725a9aadf6c5661e3bf79e081cbfabdbc6446fbefe98e4720512a899a7be005d61db9bb19de60d401e481b23a1318a2dc5f8b7c34b5024eb32dd896d9d0e0ff302135404206e1e5d45d3445223cf741c8a97219fdc763d567d41d0136785c504487e75867d79ee4fed259a538f68d6d3095d256927adc2fa63e0d0c0f9d0a06274e56a4e839e38a28411a37c6b802f294ba590f908181e4d55d01fb1f237adcc6e15df966a41fcebdeaaf4f8d8da3369f8a46de274822dd9bb2095e4a68127891af32f859ea816d23318e5fc78fea64ebb9a58a430959e1750628d635e716844bc347c395b4e5ae682fda5a6b16a64dfae6505a0b932c80f8b71180f4941cd05f2f2d4a638bfcb5fb58ecc541a6b1d25565b9080ddde9eacaa09513ad1ea6bd0b30358c808267872fe833a593b2df02c2c9fb40cedb02925b4c7a5520195191d0f6fa9bb1332b4a2911829c42bae2c1c4d6e96a1aea5e1edb9d10f9aea531bcd0af8ecb3a4ff1c274633e8821a8214c618a2afabdb61bc86efb2da8f336b6e2d91f30903fdbce6625ed085453184cf77eeff18974ac4a59108e90dd0d054bd4fe693b3ac3d9d9013b9b59d04a0650c8d407f11e04f37ea7c88d0774d85918cb4f51882f0a856fb37739d1b77223cb1abe1ee885f6639484e8138cf7f514763517678e32c2682a1e55689cf62b13a04668570c84b873da40623055d24dd5bc966cf9ea72da0f842d5bf1af9d9e89dd99efc9e13f59b09630e9a7b7d1929f772909ac65376d7c5b05c5ba9381786',
        true),
    Vector(
        '65537',
        '28129352641375505356643068228346369122206917631697076074298991273249921505841487091111395134070533228704363412069841318981887522521613403060792331221119699315498137437494324929541463415308054771131442224145674318467905336902113620606216275734330708713091074269233326157611969167125583165714182090755000968260263262808380264919647596164122323609066994227500545139162817632525993939029178799478814656536161486030018209772692582538821476284795147327230179223321312624221875707979790780532244002925093395034132071532163845740812517078441495177989450682828244940088606499127171436418486648629540337581412637828729379670081',
        '8150975347300632230271910328370412481732005878888922642003372045938212526613710737503256928049292175102769632069095649299258968162209123561133051040704848403969778583193249272540048537290501764364735242040960497808333556623580400569485179125269806732318477286263873543130294344695338314364331217396018217003221961418850427372329749618577006564097725812273814140419322297150605329783619583710578755949281619424610467926798189197173091819249382872478178196923092566803612074409770564278503744096429932617307495064326949516699102063461358588482765167601676896403199319865135667032339046014866550373640280291160478443011',
        '28129352641375505356643068228346369122206917631697076074298991273249921505841487091111395134070533228704363412069841318981887522521613403060792331221119699315498137437494324929541463415308054771131442224145674318467905336902113620606216275734330708713091074269233326157611969167125583165714182090755000968260263262808380264919647596164122323609066994227500545139162817632525993939029178799478814656536161486030018209772692582538821476284795147327230179223321312624221875707979790780532244002925093395034132071532163845740812517078441495177989450682828244940088606499127171436418486648629540337581412637828729379670081',
        '171645616681325885303748314087282148555768773376435124068142909342311681227647514859071069302286718395907305442273370696624376561592751710375261245064410308453876613043310549717568962964667800781916581384935637356410687193120724153999378511319378206822617062393591960233790639613811871649808580747802635630603',
        '163880401872422686676603662010435515892987042339851711171074744859824460585603496639427116964631225219182585617453627712493673349060229517299752790834311149100016444632742389729906346305823109118044125305291698525477154287886945805412626565068220159475069038323774773291228008769483811402378231039391014294627',
        'dd314783a81450b22ea382a12f8eb58bc2749e1953980c1eb668c3660ef4803ef16318f4839eba14f90a52163d223493e9ab4df5092044791213086296f20de0',
        'b3067e0a86fcdee4a959d0ac478d92c48da6fb6adcf028a716a8b0779ced7ebc26ab606cfac0e2010e21d2561f80123a26c713fc0af02fd5bef897590522f123c50344c4c729bef033907684249cda420a5054c203d3982355bb2abeb239aae85e684f1dfa05bac89957cb8d264af5f35d01907f66c295f8e8cc043d60915449826a6bec9738159ae781b251dc3efe2bb3dc9c69709cf3fcc0e6021ef2499bb6678a4ce0b2b593ee8d271dfb95ce1c3abcba0622ffc1e773a00f5306d50f9ddbb97d6309f56d81d207b74cd7bb01f10a0a3829c961799edc793cdfbf10680ecc59fd6ce14c9bd7438cda912506fe6447e17192d0fc740fd1f515d96d00ae168c',
        '679bf46b85267e19df2a6eb588cb9cec57940d12b3a3df4829ede4d6ae178fb804a67c52db1ed27a78fc5e432260938419e69f3af642932f81ca5f083cdb8eb0c77b6b09074df266913173212ce89ecfe3d6bbdb0ffd81bc3eab7c939ab5e676943ac3beb3de8c4884aef400e9098bc613773f332decedbc022d90ad301bf207319f5e1b8f6103d13791f22e45d173a8553d9bf154bc1ce72e3abb4c997ae66fc9482c51ba6a4031b650e22b37fad0e91dd7bc1ad3396cc8975cd41b6a46056870c83b729f6671070a7bbb7ca795aab0edf4c9b7c6aaa3247360635ba1f26fd784d6a8b643e258cb65215cf69a9dcc3fc7a157e8536d948304f532db5da1e00e54d4b76980495ea0c82d4ab05e098a54a76764a7e79248390e1221a0c3761a3a7b2502541ad4153ddab94a75d62be88c7ca155a578f74e5dab96f2d91fe65b2c5246d0bc20f2c6c33aa5c40fbbb39f03bbb85e2c4f863d430467504ec82400217122bdd0bfb6a0ebaca5fa86322d4dc4d1ca5849f68fcfea34eb94c17b0e92f1c02786c11f4632842496ebafa5136f036d5c8eb6865651efd57a0c57835cde94a8f38bd8b87c74c8b23cff900920dc5c6ff59bbe9f6f563427f3d38af3364cd928521585396a4108f3d0e269ada2ce5cc429594b94ba2f63903c07bf66336c06c666cc82eac9ef959cac5c33133a77f3dd0458aa679bc43f3bbfd55d8421bc37392e9fce65af95dd708ee3459e9a6a3df01d61599d78c96d1e2257367331063c66e9d4ad6ebe7b5ad8b483474ecf2dbe714a815fe3eebe3e6ce8bb857a2050dc7b4fdcbb61770c435546fa4c98dcc33e0b2f9a5e69c007d54845663221dac19cb69d3f1c3c0d215118e728a1cbc6a23d96aed6005aec299584c74fb1854d2036dafcf398555d5bb51e6f36120d4911e81f6da3b7bc84fb93bc18f8a2081c66a434bd9f68b4fd91b5aa0c5fd79794c0d3a41d5081492a22446dad2d2ae9dd4868a4f84002e4be30f79e6bf9fc65a49b0dadf78a744a69115d535a010619cfec25bc6ad3b619f4f4060abb21d8800c5f87bf23fdde9d9c4d2b5c66c28d061d17ff6b2e911221454b9d4055fafe81b912d72045c6c7b51933ba8afab7ca94aaff1a5650763f63f5b10c9a06b077b43f09d5864baf96a0ce6887aa9f0343bb3b2a5460887faddadaf3057d3ea76dd6d9883097d6c77ef4382a4186b0cdaf2f02d9d5a055cec3757e094ea5982080aeda69c90eba26804a07964d17d3fee699a706811a2a8a32dacb8e77918554031b5976a0a0154e2d9fa8b16523ba7a3cf0197c2d861e532b2a9daaade7a7e363ba755d72162b7a2a2314721428964ebb9366246bc4eae7f94b45876a80e354d93ee2c16650b691fc5b7d2b42a113a85781ccf8e4c7f5681e6daa2597dafce12f8f1e07d02f703f02add87c791614556574a36814',
        true),
    Vector(
        '65537',
        '22153633830724302419135060306139611845587049196237992027439716728092941178232388452789357258811867968464947963726567991153260493994105321900660034926373398334373484478989203978510010719939481845444433163631308560641169805529369541163926996464195389014257999150361968445200323802465060080420230444766321058144923888053545658583813043413292534440889236461046409180217617316533807323188580624769631086433791797307635085373516378383440539868144746072790796451064353518909092022708037537867380767711914415255801335970995736063101534804398810277527110322364738289940676319709948398491924216241801677057085849033425266531737',
        '2728978365193190624646836653096775163356652677760331406480679053213990963112705052534065944734204519476228436297969837093232313434795024594797840066908437087876908263796629649953593089299348907846004386592932357654855180833182652196606926367243044386159445952527060538385306988384816792983239588467645844218286384286582969604447996746451848547821594474254308223321900329955642842531285697337256305951380433128854676213840066603478772892051034297418220474000805527549410180077344896549253517272403338708124881856282697738009220065476445426852532910798779657493214841346351242529514255953308907664519427151581739013873',
        '22153633830724302419135060306139611845587049196237992027439716728092941178232388452789357258811867968464947963726567991153260493994105321900660034926373398334373484478989203978510010719939481845444433163631308560641169805529369541163926996464195389014257999150361968445200323802465060080420230444766321058144923888053545658583813043413292534440889236461046409180217617316533807323188580624769631086433791797307635085373516378383440539868144746072790796451064353518909092022708037537867380767711914415255801335970995736063101534804398810277527110322364738289940676319709948398491924216241801677057085849033425266531737',
        '152406091741333016211432270545267093450294091567620771671272133830593839419349963908600605874648928704766886351283891672489917019252771953369807037122410736836134335651122325363541262632859699413128899770287274371047239707548161977913686636535454630956013180484057499348941443242116936197134491886550401594857',
        '145359241074982349614974893189035773100153231542165597448117182479884231345556959984137514931133956816447337828278912971885720592783139591292425170902129592136508669888352544993002281391635332528976639069461371915058366577085402011511300979316053353107716968156345787224515538513410109709113274343349287201841',
        '3309899a146dc2a6669562c49afa1b64f1ac89265a615fb1635486120cda9150fa01b901b60508aaaaccdb6f7b7d287482646463c33c3d683cbc6efd06a7ae3c',
        '0db7eec4f1c26ccbbf0658b17d2a127bacc30214c00b2a4790a809927c408579a0b9dadb0118af51c04f8844f0f7521ce304e5cc3f6e40a2cf0c5fff4d2cf0aa8074872ee650f311b576982c620dfee0dafd68d4b63f135c632ad673e5d9c27cc7ec9e211db6532cbdb93a96e5a23d82867e67a5f80e716b34b8bfac47abc966ec37b72e7aab56c39ece8f9b12e30237c7bf20d1c51f9e92262d697be81ea8606eca0b0b224b23721428362c9115d150c448a6472885542823bdd789b88d54a01f02e22b05f7a5f580683de7fbe0ace600c916248a7074717cdf02189537addb87cec953f8f49adfcea31940a3e45becd3424c12e2ae0c4f86044f0d0df4f9f3',
        '03734451015420b9f771d99b8ef6dc65169452591e4b87272c562cb0e82c0a134f64c1750cc71a9836c8522eece98c9cbbcef07cac96ef4cc50f5dcb57b54d3c59a66f2b850fb05742821a3e26cffc8717ef925b443c8529837f2aeb8e58880e7b6c213792162b65302eca2d513a98164b94aee367868b8ccf9be41167b0e48562f2c50bb4e58c465480be56e415b065d18f2868d3ab12e30d180915f14f6226fb181b8949309a83f002abfdf3ed313025367887dff59605543b4be27847f0b50ca901e67331658250bdae800e4e841eb3120cd3fa30e16775fa25a6094d7c7d8304648c42f101eb8159c8fae5d14b9226a4b045577580f815722b51717b4f4553ba42fe499855c3df0084adb044a26d9679a459a67e109fd5a5b2e49009b8012d7a75af260aa9b331afcac3ca31f88815bcc36371720fd2d82c1f1dffa7823c125c9d186b8de3132da8ddd70cb4a15310db8458e4732b6a20622a6bce46738080f45a38619907ac3ced05c1936c6de450906adf435b8f74ad246c6a4ff6c8a2fa7802aadf88c19d816a3d0972a216acba2e5a86f37c9e1b270574ff43876599d72177e0745311c5de486cc3a1350c1360214c5f3d7ede4b73e5444f9abc9cb4dc1cfb5d31faea04cfa717be4c8315f0c54905c1c85b1d8fe1194715c67b9268c03980fa087bb7a20965e43c4c05808170ad39c2cdd3e03449417f2ff79332fc732b9e639b4a493947c3ad04dedc9d2aaec69e2f95e79d38f5dce10d9fa5f0c1ea7f1d78455eccb393714ff4697f1eb00c1d801dda020c6f25c2504376f6e5fa498db24fcc771911cfe9b9f8f92ce64ad8de485652d6ccfbd75aa71f9c6d21abf61903f3c6b107a809bd2139986d1ee9a2387b247fb68176505c74b128e975a60d12ac491565167d348d4529e29cd59b74a20211da69c7d782fad16f239640fea04eda9291ccf69249444cdc7f5a98852b3da9637e1659e98cfdd15028bde8fe9735dc53b6d16a3432dcc9a0a575d04364fba302436de4851ccc42df865a960f13caeb97cd21f527fe34b07aad028ba8127dbfca898f2c8cfca2645b7467c32aa344cc31995ed263d6b30ba672e1c2708b71eba9ee6e4ed279d15c98a0f23854af36180f1f634cd0c3964dfecd953ef23e27fc885227a40c8f34d22ea24921f7a6af56114642409889f0b3fff40eb89ba51d3e321db166ab7b7c90ffd4f44612d70643d2e741c35cc2d050cfc2cc77c4f25ff207cb7a32e98e0b87ef908fb2bd2bde8c1e9ae5faaacd0e2fc8fbf79ed3adef6acf6522c0cb1dc5177f3373dcaacab593d041f4bdc7107489f3b720c4309bed64ae47e5170372a1da272f8297840ed1b76a64c945789381250ab9f136381bd36c67e60fa9c0a1c2f6afa2685e073d9511b19cdaa7c586074a13b664309dc664e46985dc26632ef17564b71a751e',
        true),
    Vector(
        '65537',
        '24403652649370286954984240122355375245189755729088482283397439989278196714295886611538338760984491677115300254313346094874828806114535832521859289662277764964070777902833688155056671348777246555882757172619125701428050997098337387202066871320020622040458916470076875100543290181367350416120292471622438347165415471757648264353314441413666981900764459548059587126019453525002474958500114119204641841758705564228938689237024878215881250397803463369870434506624445065594388823091883952386092397245666260405517703636171714114072186275165517507559211010401040333495420756143981786353678848070447887008266619091991873631141',
        '532162074431892018898075761312678713557397928572085074653811673782397903757345468234584042961312703920493033911379862483630375374368277175049819913683277626598200933692741104377651316209965525570181953389212491781275620042270052950611272979245063972353133127342785773152864739382549385544190753502625285226098418451538484339407465070732594405901267324964376553606462203399518534757046892336384271462291108545994325413187333020743631212659612020373956885483381073843357045784791746477157081775885125772849055855491648701469627051419688167387721661363286260811295702337862195942646817248688878022429537860909129416977',
        '24403652649370286954984240122355375245189755729088482283397439989278196714295886611538338760984491677115300254313346094874828806114535832521859289662277764964070777902833688155056671348777246555882757172619125701428050997098337387202066871320020622040458916470076875100543290181367350416120292471622438347165415471757648264353314441413666981900764459548059587126019453525002474958500114119204641841758705564228938689237024878215881250397803463369870434506624445065594388823091883952386092397245666260405517703636171714114072186275165517507559211010401040333495420756143981786353678848070447887008266619091991873631141',
        '166576510922917628427477482510426202519382465586246493638665528402986008341102747520024135667473333393885416609069418603312761782895012646726139548833871648530692800492231049253940792216644635223794350240772036779945494250235076603784246748586224469212735046630433479651089394742816026597511737428403439469779',
        '146501163424313431981199398548171346299905477781974843101800194784242699998268140842223464610903695703924650853824341133627313935928947438984350252925477649840121955507961897323064671959920824059526230723519102900149819125865594444096455500783244320547259369168154149520191289174167147026933174393215453133479',
        '34b32202116efa8b7be15f53e83f4487ffc001cf2b375c3fce60c436ddfe7759dd1c35514022e394e16906646d22b4e9908f1e1bb557e68af6496dbb85b89705',
        '3adcf002962505a951005d20f5a628f6d551b39025cde85edcb906be2992c9599eb342ff6b2f30c86a6d324fe2d2c5a92cab19ad9cfea7c409d3bf9b97161d23aefd55624dd1c5468e671962ce3287177fb5bc48b6f439e377d8a8da7b3ed65f12ca0e4cd4d493821d2cae73d52adb10ea24dfe6e766cd842ddb7a4964c1dd0c75dcd931cf5402fbbf4d8331364ab63d7038980da64561e629e542d9cd2ca99e4065f26fad61d2df7c1b3078b8fb3ae33b4cf07678be089f00ac0489232163bff93c2b11877e459c52d2972f3f869a3c8ef26ef5c9773bf3aa69faaeb5a132555e3f5168e12aa91de578bded5df48db8e634aef76ffc1cb83ee669250e9b9047',
        'd9b3e116e8715d4842c6acc90d592c4b2649c09145767aacf64450a8587609abd4df1ecb3d98b70a56b1d665bccb7ad43c120b4195b54adab605fd5c433d82a3826505492814a86a9c2abb4aa1e2581174ba5db2013694215a0681bcc8945f00f20a2c53ff1925a49af39d2c0c4eb8ae53a8cf79330e6b4bfdf9650f5ff4ad25ab94b67e0052e7d9068acb91a644add2fab9e49c3d5e1c58a644401ad36db62809c7b04dff2112e006844ae599d60ff3a5462d4191d53cdaf4c4a5b361ca70f80d8fd260ad3c1806bbfcfb361ae8d0d1fb911c18bd5d185e0714153c50e2540de818638838ca032976ce8f9962cc853fcbb33b97ff11bf49fbe74e9dc5424cd537fa0880d3ea3670fb32bae08e6ced0e98e2d4bce77212d11c5f1eba9e558237795013353cc58de505cba70c9c0ad3f97b6621d98875e5de4675556658a9876c2644a8d027323bc1b7a4cd74f8bc02f8d15564c786f5dffde220db32ca6511e59c86cd9d8675c78882376c031e5f53bf2f58957aa336a77c5c6cfce5a3495f73450e870a56826d0b9ee4e4d5c00164a2843f321df6aecbd5c6aba9535c01e7d477adb08d95e61972733afef4f5ed25c12340cd9d513dc0c42fc6a9931afc66cf67e839c2cb4f0a7fc709b7a32e7971cdd58f9fda041fef4683cc459dde9fe80419758479e1c97b66279065c0258b6b2283986c87cfe9074d176fcc618375d9cfa49f5449bf519f3b0ad49f797f8a67c308a24beb0caee1fd32d5bb9c02bac04f0569ef1dbb4e9adecc94d8cbe8b0b53f10cb815aa4aa877ee59cb980132088cafc342b6297d5cff2074dd521efb571ca1bf776bdb225e5505ad824584c69f352ce4ffd515561975c6eb6fa35fc4d2f78cd7799be5ef34341d8a40bc0b98b90cd7fd2108a3b4361304dbc4f662a285da9d6a474bb2c752b83b08b9e30af773c9c0a65ea0f91a598d70e7dcbc772b769d6744b5387402731fb7bc382025d76c45a2b51128c0b7bbf04db16e561c6572cb8d7d5208c6b4d08942b87960e19852b78c23548c5efdbd58364fe0757880aa726908f478388a8f83d5363e487c231a8457b228ae5b5e0f4e013ba3b3edf01419d7768a12c496fd9b54fa702d67c1a1dc07c2dac34687db2f1e00d87dd7e386ac69e812723421389c40da51ef775ad5f58a48be9d43eba95a1a6efbb56f589a308168beb9cf59dca17d1a7c40e538f024cafafcf13588d21df63ae54f82413702a4905983def3cb6c439eb4059a4627c45f4bf3edd7f175c08a64c602817eacd9aad6f1aa981afff1aa3b83cb8a8288301434bec1d0442bc5cd696a43acebd17e368659b4abe7f7676e66cb80ef49517301130ef269f2f26d3861ef799f0452ab768cabcc6d107e710841bec8571ca07a6133fff1daa39ee0176160e278c4dbbe2910d4790323ab35b0df7a2d8b40a5518',
        true),
    Vector(
        '65537',
        '25437088660618094737433615487460079456183535130995456484169502781350359544104665849424754258537968823702804617013708901891252522315408666745405637387514877349462004783611594150432154124783261025572863162532786224626191448531528813801177089548452282937325722171912012346828341593605210072429786422101625643084279257594758279515360495040782099857497189181390645401928008172126235595011054890199261109331431236946448560096249284348990983366611913272036536215064646634070462670886151507777135986556691374641484226554144815492482577786880422565269286219283308551049861189219835294012380190713104206601565970428643048328961',
        '1145924600784425025600790490336407503950993623765979305184278194175180455590195087566437958296954379283460645914083253153847962935197103127990838821168178645445345727194330997295205637090652606190416424326133299503888912105291448645293425685991890384731685340194897924115781859422311399939602078712984108955873472189294212548747632173620896311801622475344754765185733843294738856258059523553640264849516788155207430448545257263514657447699896103424961881348880086895777093047718832530931972764427968862782820147860298642940085199486269085721045658762515982401042295216171915569517384911293266156427124283054721553033',
        '25437088660618094737433615487460079456183535130995456484169502781350359544104665849424754258537968823702804617013708901891252522315408666745405637387514877349462004783611594150432154124783261025572863162532786224626191448531528813801177089548452282937325722171912012346828341593605210072429786422101625643084279257594758279515360495040782099857497189181390645401928008172126235595011054890199261109331431236946448560096249284348990983366611913272036536215064646634070462670886151507777135986556691374641484226554144815492482577786880422565269286219283308551049861189219835294012380190713104206601565970428643048328961',
        '176006989661994358766060024825787048341495969605625195995532581818774782759591236023620171097316716284455389659328944557809323089139183403828730484907670351481332753119435209042417818705719373095812820447314434953408209467006921031763453985650495227981324794053926944883704253242152445097016821693188688304271',
        '144523173252765373613277394159577412006617149371663937819266374751540062155119325786898885178030742946294291793677376344846439728120307794585760337269307181217857953578818612926667531398487312695855092588905847223004606865215725801592754961474904523916284362385032170196464565390127081890078059405229022529391',
        'b523ed0bb03f38a80c5ae883b6a4cee30e653c4b616b312f8c0d37efd2adbd6cf7b4f7869926fc8011c9dc75154022988e119945ea1efcd2643731efe030dc24',
        '3827cd34cf9b56951e52515760c93ff4398047ea4dbc9bdb07f07f414279498068c54ece69728add1c2367165505478894d93945524e31801ddfb1d18126ac64b0a21d758af2ae374552e1240aac67fa7241a346c8c6a4ec09404919b8376271a0cab808c29bb4f6bea63f9289fbe793494360797660c2718cb4ff26c641c0c140ad38b8869951c7d79b2d77bb809792d197b94a0a4317f18092a6e29a53ba090112c8db00dc3d03eef51c6091f48a33272b87e6755badebcc162ab0f10aa380ab07bb939bf8fa9335aadd1bf414f157444497f9538e05bfb97f0ae9eea81dc5f406b82c371782fed5aba377039c33c58e0d4c11af2ca25159941bc7371e976d',
        '56dafe804bb9e62e494730f76e925adda434ccef0d75da2fe854ae27965bea76f57b7bb44c6c1f26a6036917e60cb36796866064854d965ee31071e2de96c97dadbf2404892c6ac0b9dc616c45beeff53784d31c65bd5d7b1e09f530ecb1664cf66579525984d6c77ab8f78cabda2315daed322fb79c8c01ca2bdc399565ab3cf69d4b7942739a5bc23ed235f3fd275e4053685ced87f5187a0cd3c2bc713b06cebe2e58cbc3290c0f395a98181101f126bb8998aa5e23941ea714c82cb5e1f2a24c70ca728ba28d2fa26a00b0028e7017518b10ebe5456b20ca74f26570e126484ad959f6547df304ea51f20c223a988b60107e88e207094bc3f822273d180af71c599255e612e594f64570f74ed0c8080fa10321f9b500b94e950f36700ca3684d0d8dbcd62fd6bb5fe16c4b5ade542ef3c6943951c11aee87689bf379b549cb2df0e24f03cf440612ea596e1ba7546d34130d663c94446028decb7a23072707d5d7026e7ef876eede887ed8a3a04a0ecf065f74dee989d8a70f9117a92b9ed15553a1f08f3e6700315a078c962431625727e0f4145e19b497edce67b9203266fe842e1577f6c737bbdbdc4e21f79439c2b5b79dd7ee25678f40d47d8296000c7de33e5cd8bf6f82032e6665f691d96b1bcecb7705a85bab8dc09fde9b05c4b3b4acb03868bb7be611ccbd4e702b911f7a17e61684f51e5a0bcee232c33ddd7ba03982d517c5b8964b71e8460ada57ebd2591bbf553d49a880339a882f00f2b81d480dc3cc0f5b507c26104a03a62453863a2780d03b91c2332eb68bfa3a3de52730f672dcbb84b9d7033a74792f3713715005256f15a927fe8dfcd6f1a2164418cdf2f217d9e3a9991e01658ef2139eaebca743516ff7fd5518693cac7214c3079af8da958944709de86fcb1320ca77478f7bc3d957ae42f143a464fd17ddc1aa335f4e4bb17d6a1afdc3020265da8981b0d5755e8502152fc9c5e14cc0795eea997673b469df901a030693cf1a5d82d80ac910e9dbec0759f846512671175f84c6f689dc47a4ead2510cae820c570bad14d0520b6ca0c9d5497ea9b952f0ae6a477d23a3ba89fe5c4c2c7428ef3042be6ea4b43f41aa11380c542e8315a371d25675eef12022a934ccea86d16b8f7d6a4e803a6a4bd979b21ee8ef2d29562f740a035a76df483b33c7efd46c5e3d0277d9575707eda5d39bd986618c0a31e544eae7e4269f1b1c2b6a0a991eacd176785a7637634dd021348b3d10d2e0035166d4bb8b51d72e4438eddc59102708ca121e930934149072034475f6b8214d97c34fa0ff188ac50f206b7dabc763ed64d8ee4e6187a0437bcc0f6f4b3956f8d691063874208cf663254a4ac310c0a0165005fc98e106ddaa255ada092c88e0ed3c29f253753cf315789466055ad18deb7921387ab2dd4c47b27f51569a299e',
        true),
    Vector(
        '65537',
        '23658251522583925900718741979050794674251803924998997021682209681264940044908292496194981304861842930677076371499230472828807490161501087128196670370793623326467147049337260761819787418143886724324893161193789108053343665478230198531979010923873522545815808119111181976101120608281602943417963008114389614618578904417735537637729593085440099555585319591748940070535005184336494181205787620269807526416530811679279201002952927740931726856120510347220483278642060623286767202239646348666232888334302158044968241201147110380771969014926435886287788992344002905242385801758426435716767719929022228938915368182458157960843',
        '3009760472245349683342882818107878001687205932903232336974158463425949274828309026763899120028161426896564143115718358594537169068183092206407674126317833200854781856414688063256976633028284107665269950279280661128747925765975621103504508957959557108591166824741588411519341640165827922253799633491824822800552814589677969741253495771924708369978113475087556860377401252816984294834713005677637192372237846370495254641824801741056216278594303334589468026883698059566723344237904403713305882854473697804438397752310544011957812835892209662075303097763895915619975699566227238069452916258942930328876639365178207104473',
        '23658251522583925900718741979050794674251803924998997021682209681264940044908292496194981304861842930677076371499230472828807490161501087128196670370793623326467147049337260761819787418143886724324893161193789108053343665478230198531979010923873522545815808119111181976101120608281602943417963008114389614618578904417735537637729593085440099555585319591748940070535005184336494181205787620269807526416530811679279201002952927740931726856120510347220483278642060623286767202239646348666232888334302158044968241201147110380771969014926435886287788992344002905242385801758426435716767719929022228938915368182458157960843',
        '165590013140540647679878899493586781766816521021707211030299226928354057254308720369878209847888859898233724631502229118806735761559743227567693583847231815630984309079724281063902229464971010008597095518823091793269320318276491211501580861194554544041104616248113938228731470012174045166017739040609317694323',
        '142872453923320476402895306830517278375549809340340630592712445460110171257915331312785847123442343075420588400083738297854976551803962605231204558017986861050163965265524357718201406139658856221141247812078006843972911985901189697463372854609424778354342963924485270938382783906372282727789585474600365423241',
        '65c44a86df668a5f20dab63d01d07a20fa27f4c4ab838fb64457dec754f64e1c0b9b847a46d17af6cae81cef822ec73be025273d7992a83e1a79341bbd9d8395',
        '433d05bfb12d8c913da5207ff3af0fc29c248fae24febe0a928b6d12fedb074f44fb191b6907ed05bfc24b0ab7e3e4250eaa2105db04f762b9dab82bc16ca3c9a3e9793c6dfe3a31be8ab28f2043b4dab2e070f18fb7ec2d6a2dced66b7e273944388995ac09353b855e8d37344ac5965f4c8ba90b17b5cb270473525aa989ffa2f7173bbaccbbfda131e8f6fd0acae342797e7d570269689fd85732383a4eaaa534e951c836dd7cb6bf2a2427a9b5b403778b1db16c3e5e13d458a15379608d68d91c053ecf6d861fc7e083a907db614a934cb71f97d9f866e194e35d273555b24875d0bffb177d248bded9f1b0a190ac963be22c0bf80805808340bc5bf253',
        '54b5e2340613f23fff9ec8120c331416cc221da97472df2b4caeb0d3ee111c1d2b4c95075d669ed043cb3379cedab73a4d793329adefec66353929b6057716954873be42184479b9944ea52b2f28eafc8b7242042fa951265bb04250e65dca7c4fffa73aa5319734d4b4cb0dc69461de8f16da93e9e46c9d351bba142982d6405607d85abb9cf4516fbe4c7f556aa97a7110b250644639952496b18664707257a7e4c90706849cd2796c48969edf91e2c202a49fcfae610bd16ba7f5f166c61fbcce54e1365e14e1aef3d560dd62c66543368526f3776411bc517cfe1e14dd2f777ac6a88d909cc3f76978409e3e703ef529c1b988a8b1b9528dabd0979d0ea7cf0e7aa65450cd682dd8a6dfd1cc017ef66ee65840f4f3bed3e7d19531fc36e20875828e80b02046e724c2dc1f2945e31b3ccaa81d4062f0930607145fdd97cef74b807b088ffe9caf9021ddb50925d4a3c08588d9305a5570568f92fab762a80e3a9083c1b93a977199db26195fdc1be12afd507ca7ad7c008d5551a91ffa2081ec182cc1cf816792e9920c75b8e46837dba4e0719d4bca7c81aa85283593c8290155f22df7348d403ea3b3b22bda47c0fa0a338a52ed3eea172f0d723ef904107a228593dfa355bde6d6f33c0fcde92b741c3c5a6b7bd5bf0940131fb63739b9b659d889733cf56ed60005dccc0e431b827d3d7cb028d44a231047d8a8f100d9d724dda26622ed81ad900a90310000d4c273bc8e584092db92b6b78d1fbe9a69fabc47c5d530edf68eb303be4165b1826af3330657d72d8af4787782a48d09733817fb6f6c31f6703a42d0b1e463368424fed9b48f1da40beea3917d21cdc193945fc947f33bd82650d07b35e1bf49469991479a9d85c643352e2811f3dddeabc066d9c9cb1809d03330afc9fb1b4ddab186e3576644ffeb3a6a8853303685a7d84a752c673fb0184c39682cee2e4d45295a62e70350c44657591f13e15cb6dc073f6359f798c05426d15db2bb38341966ec887b91bcd39c623d1411c35815439014040d80b8672d1bda60d401cff9ab7fd7ba23b15b31cde2c3b28a8001e8ec7e574b0b040ad3b19cca85b0331be7567b54eca040e765ef0535819932bfc47a1b4588db44b00fe60403d1dcb919c2d33a1bf7d8e160d6010c142fe5bc4f8f0bb158eb65984697d1a978d7691d748b65331c547f689bbb5eeef9a6c3e00c5cc68047421d9b8d834956bab23e70c244cdd030c5ac923a502081bb0fc953877a8912a10e39394d62497e5acb80cd91c930eb848712e7e99ef472ecb62601e81f152de086eb00d119675a86831f0385397ba00849b028fce1dc0116edaef527af73e456625b4cd0e0690d4a910802e1901b47cdec199d96e15029979add7a503567dd7a967022b118158feb35734ec8146b16ffad012ef1394911d28292e7d2c6',
        true),
    Vector(
        '65537',
        '22863777756836055143600959840749450920440384456704349962957955148144126897132094433370209548824375989844046076857133821371508636666850758882851578033383651783618422036072419632732686157582055405562109922709901326246966123012779940638801924989478425633471958572537119027807706692988780579411816688566224513817250774335575958505773698753128001893291209436871060294845040743647053132079832745308356830002298113861195640612128927309500368668049733940067477120484141937395209454551385139891613730504379058183817440947369052529753197836772372884439231897004397488834752501181030419040390355982635808334470641448749691416183',
        '2255607597034095465629369758310047376689615113673527544524538184694536711375368975677176096524467140124459159099742110900369090595686765972764650163645604782138103783728675849297849800141092500795914089831406183146158040013109063677009534248126596593271174270270820194306891185490928190734807830689914469598600353406030453644843169521306845973935112914753357995065221191706901453116661352835469169409508970115248018229509809404657743355036733922945836679716996092794994744403038571209570423722421262617433701221885865122225656585415125141317614483711216050572551407767136716392847862790147219388705010554043573130093',
        '22863777756836055143600959840749450920440384456704349962957955148144126897132094433370209548824375989844046076857133821371508636666850758882851578033383651783618422036072419632732686157582055405562109922709901326246966123012779940638801924989478425633471958572537119027807706692988780579411816688566224513817250774335575958505773698753128001893291209436871060294845040743647053132079832745308356830002298113861195640612128927309500368668049733940067477120484141937395209454551385139891613730504379058183817440947369052529753197836772372884439231897004397488834752501181030419040390355982635808334470641448749691416183',
        '165753605475658965896905380941512780373501918722623039928392212300384638200828754218945657927975147434007515408820867595182498678712848089093708745610029028514780605885496621852402727633970979135328953451658504203008039089814570880017893747801344491417093420169338769217963611664808574246257897284558430343541',
        '137938343429842417908376247774337756675267630407222666317251541029569965860036381348765753221799669784544962152131139297790992522931746092548078408342093276445880775981341485116526468109550869527376048089827949530781527838543749512497666287942212179789741424088818092906786749935663701944131037153077866559163',
        '65e8ffb8dde91e1bd267f02e337dcb32caaad90360d2173008ee7766b5622a0a1c9cc3d8c58896baef60c0ad14454da97710797a52ac328af787cead7e90bc05',
        '95b6e1df81ec646c7a75ac46ac2ecf2fedfe43f5d868896faf81aca40f662e04d12fc28e74d13afa7d1dcf28a54762fdcf22e9da8c3f94be6b747dc561900dc52d195c53160f4581e717b490b886d4a8da7bd4d7fa4044669ad6ce4ecc8905c8554c9e998cb5be39f011ad2f1360560a815d8c3d91a15bb2bced97334a60f36bea2e9dc0926f22b1daeddb4049abc9a45f45a6de7c6e3ab037a6c86dacba041d48d290902e137fd651641b61332b6603dd15ba6b0ba57a1f0d273778545622476dcff6c89163cc8188fbf4298b0b5a098292b38bb4288ada64082e2d16b76b2ffd8f6dc389348540ddc6d75f44a713f6c43a92403b994c97aea9314e9feee9ca',
        '6583b7ab7db45485e3245754ebb36bc4ed4124644ae27b6139e4808c9033aa22a37d69f88a11c2d3b066cfecdb64a4579fb3f2b95e0c72db6331336d2276c135e28bec8d6ea4c137600a6944f9ce46f18802b790d50263d66d2601e713ce42959db2842a02c325d778f9fce37fa0a16da23224c6ae64bea279229ba8d10988cf27c81f6f3df102afd43202bcd7458cc0e15337a3d430d4bd501a24cb44afc89b4b43b02918e36fdce1dc7f6358f11e90db4d2d3c461ae30366e6a1b157ae17b32bff4c0ea92c04462d7f956d7e9e040f2f57ed5bf9a723eaa42b5b84f5e86e9b13326b834f01d19e6e373d6125b46daa3d3375d9863e2388e2bb3f75db864c8e278f29bcca51d7ccbc17be552d449ebbdb663eca1bb42ef45ca2d0b523c950531bf79e4fb378b7d772a43e5a538e59c830d812702f9a0aac85078c99ebbaae2124bc0b56e72bcf7a186be0e06f5e84f624d07418c1b4341bce6bbf2a3f2321477fc81d062d7769f7b5c4551539ca27c8224c55c4d352df91c1715e21270f44adddfbbe3cf1135bad4cc3c6b9c94674a6d4e56d684d8bf130c6bb0b3fc6ec10c037a424a6b946960aec49446c468243fa0180c2649dfc5b4105df4363cf9eee9d2b73a5a1fa87fad38722838eb98266d26002472100905182de92a12731c54439501f72e38e0a53e02c7e3ad2162c1390dffd3321481d51f523ade9a89885264c528479ac1888ec3780baf4887150e52c1cd6b622d2738b8dd6b2ffcb97c079650cea01dda064b64133ff9ee70c89239fac290885fe8655320cee527c0121e59142df87d7604289d5aa147e7adad69551f7850571b8f1d253f1cfad8499c2c482485d8cc620d4efc31c2085ce0ac1bd3c001b4f6aa282ec6de9aa98d7b681355e052412e40ac31b307f0509819e92b9b6ebbbe3899dcc0d9761e054b9972289b98837b4c41163556e368a38c1d5b6544ba7497595153d155006fef4ae7533051509cf2224634487a96d697dc26fd3f66574e28ca493cae4359b0a2f9d89c0ea23ff861a52a7ce95c04773dbeed5ed06bbb20cd8227d8b386eccd4ea5759e8f9189c625331de9fd7c29ceedeed5b4c67be81ed12819e18631216537a74674a624d946a861c62e247cccb3c423cea7ea1b6f62aab411ca6284c652378408cef75d619462619f4e22b25d8bdfb0351bd62e3dbcc7e25b77f346ceef928591f0bd143ce5ee63c49b8e38d9f3b0f64098f93745c210bd6f921545bd7b2dc79c565dd652a3bacd86ce3aa611ec3bcea8263627022c5dce13516594334d9f393b1247fc4d65551a7a5aca08dff460ea54399550456b7cc2b7534349e5c752ec9a48e74b3e7ad7f8c9fc42af855cba400eb82c5b8b52d4bc170ea7744b4c338867a85e9c2c58257feff8ff990f19f55de30aa5f13496e3148b44a0f795fa6fafd7bd5bf0d',
        true),
  ];

  test('RSAESOAEP decryption vectors from BC', () {
    vectors.forEach((Vector v) {
      var rsaesOaep = OAEPEncoding(RSAEngine());
      rsaesOaep.init(
          false, PrivateKeyParameter<RSAPrivateKey>(v.getPrivateKey()));
      final output = Uint8List(v.pt!.length);
      final size = rsaesOaep.processBlock(v.ct!, 0, v.ct!.length, output, 0);
      expect(output, equals(v.pt, size));
    });
  });

  test('RSAESOAEP encryption vectors from BC', () {
    vectors.forEach((Vector v) {
      var rng = _OAEPTestEntropySource();
      rng.seed(KeyParameter(v.seed!));

      var rsaesOaep = OAEPEncoding(RSAEngine());
      rsaesOaep.init(
          true,
          ParametersWithRandom(
              PublicKeyParameter<RSAPublicKey>(v.getPublicKey()), rng));
      final output = Uint8List(v.ct!.length);
      final size = rsaesOaep.processBlock(v.pt!, 0, v.pt!.length, output, 0);
      expect(output, equals(v.ct, size));
    });
  });
}

// ----

///
/// For testing only.
/// Reads through the seed and then resets to the beginning of
/// the seed when exhausted.
///
class _OAEPTestEntropySource extends SecureRandomBase {
  var _next = 0;
  Uint8List? _values;

  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      SecureRandom, '_oaep_rand', () => _OAEPTestEntropySource());

  @override
  String get algorithmName => '_oaep_rand';

  @override
  BigInt nextBigInteger(int bitLength) {
    throw UnimplementedError();
  }

  @override
  int nextUint8() {
    if (_values != null && _values!.isNotEmpty) {
      if (_next >= _values!.length) {
        _next = 0;
      }
      return _values![_next++];
    } else {
      return 0;
    }
  }

  @override
  void seed(covariant KeyParameter params) {
    _values = (params).key;
    _next = 0;
  }
}

/// Broke RSA Engine that allows us to modify the output len;
class _RSABroken extends RSAEngine {
  var wrongSizeDelta = 0;

  @override
  int get outputBlockSize {
    return super.outputBlockSize + wrongSizeDelta;
  }
}

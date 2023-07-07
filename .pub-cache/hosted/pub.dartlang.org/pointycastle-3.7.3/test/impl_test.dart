// See file LICENSE for more information.

library test.impl_test;

import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:test/test.dart';
import 'test/runners/registry.dart';

void main() {
  group('impl:', () {
    test('AsymmetricBlockCipher returns valid implementations', () {
      testAsymmetricBlockCipher('RSA');
      testAsymmetricBlockCipher('RSA/PKCS1');
      testAsymmetricBlockCipher('RSA/OAEP');
    });

    test('BlockCipher returns valid implementations', () {
      testBlockCipher('AES');
    });

    test('Digest returns valid implementations', () {
      testDigest('Blake2b');
      testDigest('MD2');
      testDigest('MD4');
      testDigest('MD5');
      testDigest('RIPEMD-128');
      testDigest('RIPEMD-160');
      testDigest('RIPEMD-256');
      testDigest('RIPEMD-320');
      testDigest('SHA-1');
      testDigest('SHA-224');
      testDigest('SHA-256');
      testDigest('SHA3-224');
      testDigest('SHA3-256');
      testDigest('SHA3-384');
      testDigest('SHA3-512');
      testDigest('Keccak/128');
      testDigest('Keccak/224');
      testDigest('Keccak/256');
      testDigest('Keccak/288');
      testDigest('Keccak/384');
      testDigest('Keccak/512');
      testDigest('SHAKE-128');
      testDigest('SHAKE-256');
      testDigest('CSHAKE-128');
      testDigest('CSHAKE-256');
      testDigest('SHA-384');
      testDigest('SHA-512');
      testDigest('SHA-512/448');
      testDigest('Tiger');
      testDigest('Whirlpool');
    });

    test('ECDomainParameters returns valid implementations', () {
      testECDomainParameters('prime192v1');
    });

    test('KeyDerivator returns valid implementations', () {
      testKeyDerivator('SHA-1/HMAC/PBKDF2');
      testKeyDerivator('scrypt');
    });

    test('KeyGenerator returns valid implementations', () {
      testKeyGenerator('EC');
      testKeyGenerator('RSA');
    });

    if (Platform.instance.fullWidthInteger) {
      test(
          'Mac returns valid implementations on platforms with full width integer',
          () {
        testMac('SHA-1/HMAC');
        testMac('SHA-256/HMAC');
        testMac('SHA3-256/HMAC');
        testMac('RIPEMD-160/HMAC');
        testMac('AES/Poly1305');
        testMac('AES/CMAC');
        testMac('AES/CBC_CMAC');
        testMac('AES/CBC_CMAC/PKCS7');
        testMac('SHAKE-128/HMAC');
        testMac('CSHAKE-128/HMAC');
        testMac('SHA3-256/HMAC');
      });
    } else {
      test(
          'Mac returns valid implementations on platforms without full width integer',
          () {
        testMac('SHA-1/HMAC');
        testMac('SHA-256/HMAC');
        testMac('SHA3-256/HMAC');
        testMac('RIPEMD-160/HMAC');
        // testMac('AES/Poly1305');
        testMac('AES/CMAC');
        testMac('AES/CBC_CMAC');
        testMac('AES/CBC_CMAC/PKCS7');
        testMac('SHAKE-128/HMAC');
        testMac('CSHAKE-128/HMAC');
        testMac('SHA3-256/HMAC');
      });
    }

    test('BlockCipher returns valid implementations for modes of operation',
        () {
      testBlockCipher('AES/CBC');
      testBlockCipher('AES/CFB-64');
      testBlockCipher('AES/CTR');
      testBlockCipher('AES/ECB');
      testBlockCipher('AES/OFB-64/GCTR');
      testBlockCipher('AES/OFB-64');
      testBlockCipher('AES/SIC');
      testBlockCipher('AES/GCM');
    });

    test('PaddedBlockCipher returns valid implementations', () {
      testPaddedBlockCipher('AES/SIC/PKCS7');
    });

    test('Padding returns valid implementations', () {
      testPadding('PKCS7');
      testPadding('ISO7816-4');
    });

    test('SecureRandom returns valid implementations', () {
      testSecureRandom('AES/CTR/AUTO-SEED-PRNG');
      testSecureRandom('AES/CTR/PRNG');
      testSecureRandom('Fortuna');
    });

    test('Signer returns valid implementations', () {
      testSigner('SHA-1/ECDSA');
      testSigner('MD2/RSA');
      testSigner('MD4/RSA');
      testSigner('MD5/RSA');
      testSigner('RIPEMD-128/RSA');
      testSigner('RIPEMD-160/RSA');
      testSigner('RIPEMD-256/RSA');
      testSigner('SHA-1/RSA');
      testSigner('SHA-224/RSA');
      testSigner('SHA-256/RSA');
      testSigner('SHA-384/RSA');
      testSigner('SHA-512/RSA');
    });

    if (Platform.instance.fullWidthInteger) {
      test(
          'StreamCipher returns valid implementations full width integer platforms',
          () {
        testStreamCipher('Salsa20');
        testStreamCipher('AES/SIC');
        testStreamCipher('AES/CTR');
        testStreamCipher('ChaCha20/20');
        testStreamCipher('ChaCha7539/20');
        testAEADCipher('ChaCha20-Poly1305');
        testAEADCipher('AES/EAX');
      });
    } else {
      test(
          'StreamCipher returns valid implementations on platforms without full width integer',
          () {
            testStreamCipher('Salsa20');
        testStreamCipher('AES/SIC');
        testStreamCipher('AES/CTR');
        testStreamCipher('ChaCha20/20');
        testStreamCipher('ChaCha7539/20');
        //testAEADCipher('ChaCha20-Poly1305');
        testAEADCipher('AES/EAX');
      });
    }
  });
}

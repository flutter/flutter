/// Encrypt and decrypt using AES

/// Note: this example use Pointy Castle WITH the registry.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

// Code convention: variable names starting with underscores are examples only,
// and should be implemented according to the needs of the program.

//----------------------------------------------------------------

Uint8List aesCbcEncrypt(
    Uint8List key, Uint8List iv, Uint8List paddedPlaintext) {
  if (![128, 192, 256].contains(key.length * 8)) {
    throw ArgumentError.value(key, 'key', 'invalid key length for AES');
  }
  if (iv.length * 8 != 128) {
    throw ArgumentError.value(iv, 'iv', 'invalid IV length for AES');
  }
  if (paddedPlaintext.length * 8 % 128 != 0) {
    throw ArgumentError.value(
        paddedPlaintext, 'paddedPlaintext', 'invalid length for AES');
  }

  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = BlockCipher('AES/CBC')
    ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

  // Encrypt the plaintext block-by-block

  final cipherText = Uint8List(paddedPlaintext.length); // allocate space

  var offset = 0;
  while (offset < paddedPlaintext.length) {
    offset += cbc.processBlock(paddedPlaintext, offset, cipherText, offset);
  }
  assert(offset == paddedPlaintext.length);

  return cipherText;
}

//----------------------------------------------------------------

Uint8List aesCbcDecrypt(Uint8List key, Uint8List iv, Uint8List cipherText) {
  if (![128, 192, 256].contains(key.length * 8)) {
    throw ArgumentError.value(key, 'key', 'invalid key length for AES');
  }
  if (iv.length * 8 != 128) {
    throw ArgumentError.value(iv, 'iv', 'invalid IV length for AES');
  }
  if (cipherText.length * 8 % 128 != 0) {
    throw ArgumentError.value(
        cipherText, 'cipherText', 'invalid length for AES');
  }

  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = BlockCipher('AES/CBC')
    ..init(false, ParametersWithIV(KeyParameter(key), iv)); // false=decrypt

  // Decrypt the cipherText block-by-block

  final paddedPlainText = Uint8List(cipherText.length); // allocate space

  var offset = 0;
  while (offset < cipherText.length) {
    offset += cbc.processBlock(cipherText, offset, paddedPlainText, offset);
  }
  assert(offset == cipherText.length);

  return paddedPlainText;
}

//================================================================
// Supporting functions
//
// These are not a part of AES, so different standards may do these
// things differently.

//----------------------------------------------------------------
/// Represent bytes in hexadecimal
///
/// If a [separator] is provided, it is placed the hexadecimal characters
/// representing each byte. Otherwise, all the hexadecimal characters are
/// simply concatenated together.

String bin2hex(Uint8List bytes, {String? separator, int? wrap}) {
  var len = 0;
  final buf = StringBuffer();
  for (final b in bytes) {
    final s = b.toRadixString(16);
    if (buf.isNotEmpty && separator != null) {
      buf.write(separator);
      len += separator.length;
    }

    if (wrap != null && wrap < len + 2) {
      buf.write('\n');
      len = 0;
    }

    buf.write('${(s.length == 1) ? '0' : ''}$s');
    len += 2;
  }
  return buf.toString();
}

//----------------------------------------------------------------
// Decode a hexadecimal string into a sequence of bytes.

Uint8List hex2bin(String hexStr) {
  if (hexStr.length % 2 != 0) {
    throw const FormatException('not an even number of hexadecimal characters');
  }
  final result = Uint8List(hexStr.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hexStr.substring(2 * i, 2 * (i + 1)), radix: 16);
  }
  return result;
}

//----------------------------------------------------------------
/// Added padding

Uint8List pad(Uint8List bytes, int blockSizeBytes) {
  // The PKCS #7 padding just fills the extra bytes with the same value.
  // That value is the number of bytes of padding there is.
  //
  // For example, something that requires 3 bytes of padding with append
  // [0x03, 0x03, 0x03] to the bytes. If the bytes is already a multiple of the
  // block size, a full block of padding is added.

  final padLength = blockSizeBytes - (bytes.length % blockSizeBytes);

  final padded = Uint8List(bytes.length + padLength)..setAll(0, bytes);
  Padding('PKCS7').addPadding(padded, bytes.length);

  return padded;
}

//----------------------------------------------------------------
/// Remove padding

Uint8List unpad(Uint8List padded) =>
    padded.sublist(0, padded.length - Padding('PKCS7').padCount(padded));

//----------------------------------------------------------------
/// Derive a key from a passphrase.
///
/// The [passPhrase] is an arbitrary length secret string.
///
/// The [bitLength] is the length of key produced. It determines whether
/// AES-128, AES-192, or AES-256 will be used. It must be one of those values.

Uint8List passphraseToKey(String passPhrase,
    {String salt = '', int iterations = 30000, required int bitLength}) {
  if (![128, 192, 256].contains(bitLength)) {
    throw ArgumentError.value(bitLength, 'bitLength', 'invalid for AES');
  }
  final numBytes = bitLength ~/ 8;

  final kd = KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(
        Pbkdf2Parameters(utf8.encode(salt) as Uint8List, iterations, numBytes));

  return kd.process(utf8.encode(passPhrase) as Uint8List);
}

//----------------------------------------------------------------
/// Generate random bytes to use as the Initialization Vector (IV).

Uint8List? generateRandomBytes(int numBytes) {
  if (_secureRandom == null) {
    // First invocation: create _secureRandom and seed it
    _secureRandom = SecureRandom('Fortuna');
    _secureRandom!.seed(
        KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));
  }

  // Use it to generate the random bytes

  final iv = _secureRandom!.nextBytes(numBytes);
  return iv;
}

SecureRandom? _secureRandom;

//----------------------------------------------------------------
/// Run some of the test vectors from the NIST reference test vectors in the
/// AES Known Answer Test (KAT).
///
/// http://csrc.nist.gov/groups/STM/cavp/documents/aes/KAT_AES.zip

void katTest() {
  // Encryption tests

  [
    [
      'CBCGFSbox128.rsp: encrypt 0',
      '00000000000000000000000000000000', // key
      '00000000000000000000000000000000', // IV
      'f34481ec3cc627bacd5dc3fb08f273e6', // plaintext
      '0336763e966d92595a567cc9ce537f5e', // ciphertext
    ],
    [
      'CBCKeySbox128.rsp: encrypt 0',
      '10a58869d74be5a374cf867cfb473859',
      '00000000000000000000000000000000',
      '00000000000000000000000000000000',
      '6d251e6944b051e04eaa6fb4dbf78465',
    ],
    [
      'CBCVarKey128.rsp: encrypt 0',
      '80000000000000000000000000000000', // 8...
      '00000000000000000000000000000000',
      '00000000000000000000000000000000',
      '0edd33d3c621e546455bd8ba1418bec8',
    ],
    [
      'CBCVarTxt128.rsp: encrypt 0',
      '00000000000000000000000000000000',
      '00000000000000000000000000000000',
      '80000000000000000000000000000000', // 8...
      '3ad78e726c1ec02b7ebfe92b23d9ec34',
    ],
    [
      'CBCGFSbox192.rsp: encrypt 0',
      '000000000000000000000000000000000000000000000000',
      '00000000000000000000000000000000',
      '1b077a6af4b7f98229de786d7516b639',
      '275cfc0413d8ccb70513c3859b1d0f72',
    ],
    [
      'CBCGFSbox256.rsp: encrypt 0',
      '0000000000000000000000000000000000000000000000000000000000000000',
      '00000000000000000000000000000000',
      '014730f80ac625fe84f026c60bfd547d',
      '5c9d844ed46f9885085e5d6a4f94c7d7',
    ]
  ].forEach((testCase) {
    final name = testCase[0];
    final key = testCase[1];
    final iv = testCase[2];
    final plaintext = testCase[3];
    final cipherText = testCase[4];

    final cipher = aesCbcEncrypt(hex2bin(key), hex2bin(iv), hex2bin(plaintext));
    if (bin2hex(cipher) != cipherText) {
      print('$name: failed');
      throw AssertionError('$name: failed');
    }
  });

  // Decryption tests

  [
    [
      'CBCGFSbox128.rsp: decrypt 0',
      '00000000000000000000000000000000', // key
      '00000000000000000000000000000000', // IV
      '0336763e966d92595a567cc9ce537f5e', // ciphertext
      'f34481ec3cc627bacd5dc3fb08f273e6', // plaintext
    ],
    [
      'CBCGFSbox192.rsp: decrypt 3',
      '000000000000000000000000000000000000000000000000', // key
      '00000000000000000000000000000000', // IV
      '4f354592ff7c8847d2d0870ca9481b7c', // ciphertext
      '51719783d3185a535bd75adc65071ce1', // plaintext
    ],
    [
      'CBCGFSbox256.rsp: decrypt 4',
      '0000000000000000000000000000000000000000000000000000000000000000', // key
      '00000000000000000000000000000000', // IV
      '1bc704f1bce135ceb810341b216d7abe', // ciphertext
      '91fbef2d15a97816060bee1feaa49afe', // plaintext
    ]
  ].forEach((testCase) {
    final name = testCase[0];
    final key = testCase[1];
    final iv = testCase[2];
    final cipherText = testCase[3];
    final plaintext = testCase[4];

    final plain = aesCbcDecrypt(hex2bin(key), hex2bin(iv), hex2bin(cipherText));
    if (bin2hex(plain) != plaintext) {
      print('$name: failed');
      throw AssertionError('$name: failed');
    }
  });
}

//----------------------------------------------------------------
/// Demonstrates encryption and decryption.
///
/// This uses the custom key derivation, IV generation and padding functions
/// that have been implemented in this program.
///
/// The [aesSize] is either 128, 192 or 256 to use AES-128, AES-192 or AES-256.

void encryptAndDecryptTest(int aesSize) {
  const textToEncrypt = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt
in culpa qui officia deserunt mollit anim id est laborum.
''';
  const passphrase = 'p@ssw0rd';

  final randomSalt = latin1.decode(generateRandomBytes(32)!);

  // IV for both encrypt and decrypt (must ALWAYS be 128 bits for AES)
  final iv = generateRandomBytes(128 ~/ 8)!;

  // Encrypt (note must ALWAYS pad to 128-bit block size for AES)

  final cipherText = aesCbcEncrypt(
      passphraseToKey(passphrase, salt: randomSalt, bitLength: aesSize),
      iv,
      pad(utf8.encode(textToEncrypt) as Uint8List, 16));

  // If the encrypted data was to be stored or transmitted to the receiver,
  // it will have to store the cipher-text, Initialization Vector (IV) and
  // all the parameters used to convert the passphrase into a key (in this
  // example, that would be the salt and bit-length).

  // Decrypt

  final paddedDecryptedBytes = aesCbcDecrypt(
      passphraseToKey(passphrase, salt: randomSalt, bitLength: aesSize),
      iv,
      cipherText);
  final decryptedBytes = unpad(paddedDecryptedBytes);
  final decryptedText = utf8.decode(decryptedBytes);

  // Check decryption produced the original plaintext

  if (decryptedText != textToEncrypt) {
    print('decryption did not produce the original plaintext');
    throw AssertionError('encrypt/decrypt failed');
  }
}

//----------------------------------------------------------------

void main(List<String> args) {
  if (args.contains('-h') || args.contains('--help')) {
    print('Usage: aes-cbc-registry');
    return;
  }

  katTest();
  encryptAndDecryptTest(128);
  encryptAndDecryptTest(192);
  encryptAndDecryptTest(256);
  print('Ok');
}

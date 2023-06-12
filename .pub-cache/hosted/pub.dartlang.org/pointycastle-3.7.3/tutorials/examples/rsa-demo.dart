/// Demonstration of RSA
///
/// - key generation
/// - signing and verification
/// - encrypting and decrypting
///
/// Invoke with "-v" to print extra information.
/// Invoke with "-l" to use longer plaintext.

import 'dart:convert';
import 'dart:typed_data';

// For using the registry:
//import 'package:pointycastle/pointycastle.dart';

// When not using the registry:
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

//================================================================
// Test data

const shortPlaintext = 'What hath God wrought!';

const longPlaintext = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt
in culpa qui officia deserunt mollit anim id est laborum.''';

//================================================================
// Key generation

//----------------------------------------------------------------
/// Generate an RSA key pair.

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  // Create an RSA key generator and initialize it

  // final keyGen = KeyGenerator('RSA'); // Get using registry
  final keyGen = RSAKeyGenerator(); // Get directly

  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom));

  // Use the generator

  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types

  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  // The RSA numbers will always satisfy these properties

  assert(myPublic.modulus == myPrivate.modulus);
  assert(myPrivate.p! * myPrivate.q! == myPrivate.modulus, 'p.q != n');
  final phi = (myPrivate.p! - BigInt.one) * (myPrivate.q! - BigInt.one);
  assert((myPublic.exponent! * myPrivate.exponent!) % phi == BigInt.one);

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

//================================================================
// Signing and verifying

//----------------------------------------------------------------
/// Use an RSA private key to create a signature.

Uint8List rsaSign(RSAPrivateKey privateKey, Uint8List dataToSign) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');

  // '0609608648016503040201' is the BER encoding of the Object Identifier
  // 2.16.840.1.101.3.4.2.1 that identifies the SHA-256 digest algorithm.
  // <http://oid-info.com/get/2.16.840.1.101.3.4.2.1>

  // See _DIGEST_IDENTIFIER_HEXES in RSASigner for correct hex values to use
  // IMPORTANT: the correct digest identifier hex value must be used,
  // corresponding to the digest algorithm, otherwise the signature won't
  // verify.

  // initialize with true, which means sign
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

  final sig = signer.generateSignature(dataToSign);

  return sig.bytes;
}

//----------------------------------------------------------------
/// Use an RSA public key to verify a signature.

bool rsaVerify(
    RSAPublicKey publicKey, Uint8List signedData, Uint8List signature) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final sig = RSASignature(signature);
  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
  // See _DIGEST_IDENTIFIER_HEXES in RSASigner for correct hex values to use
  // IMPORTANT: the correct digest identifier hex value must be used,
  // corresponding to the digest algorithm, otherwise the signature won't
  // verify.

  // initialize with false, which means verify
  verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

  return verifier.verifySignature(signedData, sig);
}

//================================================================
// Encryption and decryption

//----------------------------------------------------------------
/// Schemes to use to encrypt/decrypt
///
/// rsa = use RSAEngine without an Asymmetric Block Cipher.

enum AsymBlockCipherToUse { rsa, pkcs1, oaep }

//----------------------------------------------------------------

AsymmetricBlockCipher _createBlockCipher(AsymBlockCipherToUse scheme) {
  switch (scheme) {
    case AsymBlockCipherToUse.rsa:
      return RSAEngine();
    case AsymBlockCipherToUse.pkcs1:
      return PKCS1Encoding(RSAEngine());
    case AsymBlockCipherToUse.oaep:
      return OAEPEncoding(RSAEngine());
  }
}

Uint8List rsaEncrypt(RSAPublicKey myPublic, Uint8List dataToEncrypt,
    AsymBlockCipherToUse scheme) {
  var encryptor = _createBlockCipher(scheme);

  encryptor.init(
    true,
    PublicKeyParameter<RSAPublicKey>(myPublic),
  ); // true=encrypt

  return _processInBlocks(encryptor, dataToEncrypt);
}

//----------------------------------------------------------------

Uint8List rsaDecrypt(RSAPrivateKey myPrivate, Uint8List cipherText,
    AsymBlockCipherToUse scheme) {
  var decryptor = _createBlockCipher(scheme);

  decryptor.init(
    false,
    PrivateKeyParameter<RSAPrivateKey>(myPrivate),
  ); // false=decrypt

  return _processInBlocks(decryptor, cipherText);
}

//----------------------------------------------------------------

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final numBlocks = input.length ~/ engine.inputBlockSize +
      ((input.length % engine.inputBlockSize != 0) ? 1 : 0);

  final output = Uint8List(numBlocks * engine.outputBlockSize);

  var inputOffset = 0;
  var outputOffset = 0;
  while (inputOffset < input.length) {
    final chunkSize = (inputOffset + engine.inputBlockSize <= input.length)
        ? engine.inputBlockSize
        : input.length - inputOffset;

    outputOffset += engine.processBlock(
        input, inputOffset, chunkSize, output, outputOffset);

    inputOffset += chunkSize;
  }

  return (output.length == outputOffset)
      ? output
      : output.sublist(0, outputOffset);
}

//================================================================
// Supporting functions
//
// These are not a part of RSA, so different implementations may do these
// things differently.

//----------------------------------------------------------------

SecureRandom getSecureRandom() {
// Create a secure random number generator and seed it with random bytes

//final result = SecureRandom('Fortuna'); // Get using registry
  final secureRandom = FortunaRandom(); // Get directly

  secureRandom.seed(
      KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));

  return secureRandom;
}

//----------------------------------------------------------------
// Modify one bit.
//
// Returns a new Uint8List with the modified bytes.

Uint8List tamperWithData(Uint8List original) {
// Tampered with data does not verify

  final tamperedData = Uint8List.fromList(original);
  tamperedData[tamperedData.length - 1] ^= 0x01; // XOR to flip one bit

  return tamperedData;
}

//----------------------------------------------------------------
// Print out the RSA key pair

String dumpRsaKeys(AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> k,
    {bool verbose = false}) {
  final bitLength = k.privateKey.modulus!.bitLength;
  final buf = StringBuffer('RSA key generated (bit-length: $bitLength)');

  if (verbose) {
    buf.write('''
  e = ${k.publicKey.exponent}
  n = ${k.publicKey.modulus}
Private:
  n = ${k.privateKey.modulus}
  d = ${k.privateKey.exponent}
  p = ${k.privateKey.p}
  q = ${k.privateKey.q}
''');
  }
  return buf.toString();
}

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
/// Tests two Uint8List for equality.
///
/// Returns true if they contain all the same bytes. Otherwise false.

bool isUint8ListEqual(Uint8List a, Uint8List b) {
  if (a.length == b.length) {
    for (var x = 0; x < a.length; x++) {
      if (a[x] != b[x]) {
        return false;
      }
    }
  }
  return true;
}

//================================================================

void _testSignAndVerify(AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> rsaPair,
    Uint8List bytesToSign, bool verbose) {
  final signatureBytes = rsaSign(rsaPair.privateKey, bytesToSign);
  if (verbose) {
    print('Signature:\n${bin2hex(signatureBytes, wrap: 64)}');
  }

  if (rsaVerify(rsaPair.publicKey, bytesToSign, signatureBytes)) {
    print('Signature verify: success');
  } else {
    print('fail: signature did not verify');
  }
  if (rsaVerify(
      rsaPair.publicKey, tamperWithData(bytesToSign), signatureBytes)) {
    print('fail: signature verifies when data was modified');
  } else {
    print('Signature verify: detected tampered text successfully');
  }

  try {
    if (rsaVerify(
        rsaPair.publicKey, bytesToSign, tamperWithData(signatureBytes))) {
      print('fail: signature verifies when signature was modified');
    } else {
      print('Signature verify: detected tampered signature successfully');
    }
  } catch (e, st) {
    print('fail: signature validation: threw exception: ${e.runtimeType}');
    if (verbose) {
      print('$e\n$st\n');
    }
  }
}

//----------------------------------------------------------------

void _testEncryptAndDecrypt(
    AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> rsaPair,
    AsymBlockCipherToUse scheme,
    Uint8List plaintext,
    bool verbose) {
  try {
    if (verbose) {
      print('\nEncrypting with $scheme:');
    }
    final cipherText = rsaEncrypt(rsaPair.publicKey, plaintext, scheme);
    if (verbose) {
      //print('\nPlaintext:\n"$plaintext"');
      print('Ciphertext:\n${bin2hex(cipherText, wrap: 64)}');
    }

    final decryptedBytes = rsaDecrypt(rsaPair.privateKey, cipherText, scheme);

    if (isUint8ListEqual(decryptedBytes, plaintext)) {
      if (verbose) {
        print('Decrypted:\n"${utf8.decode(decryptedBytes)}"');
      }
      print('Decrypt ($scheme): success');
    } else {
      print(plaintext);
      print(decryptedBytes);
      print(
          'Decrypted:\n"${utf8.decode(decryptedBytes, allowMalformed: true)}"');
      print('fail: decrypted does not match plaintext');
    }
  } catch (e, st) {
    print('fail: threw unexpected exception: ${e.runtimeType}');
    if (verbose) {
      print('$e\n$st\n');
    }
  }
}
//----------------------------------------------------------------

void main(List<String> args) {
  var longText = false;
  var verbose = false;
  for (final arg in args) {
    switch (arg) {
      case '--long':
      case '-l':
        longText = true;
        break;
      case '--help':
      case '-h':
        print('Usage: rsa-demo [-l] [-v] [-h]');
        return;
      case '--verbose':
      case '-v':
        verbose = true;
        break;
      default:
        print('Usage error: unknown argument: $arg (-h for help)');
        return;
    }
  }

  // Generate an RSA key pair

  final rsaPair = generateRSAkeyPair(getSecureRandom(), bitLength: 1024);
  print(dumpRsaKeys(rsaPair, verbose: verbose));

  // Use the key pair

  final plaintext = (longText) ? longPlaintext : shortPlaintext;
  if (verbose) {
    print('Plaintext: $plaintext\n');
  }
  final bytes = utf8.encode(plaintext);

  _testSignAndVerify(rsaPair, Uint8List.fromList(bytes), verbose);

  _testEncryptAndDecrypt(
      rsaPair, AsymBlockCipherToUse.rsa, Uint8List.fromList(bytes), verbose);
  _testEncryptAndDecrypt(
      rsaPair, AsymBlockCipherToUse.pkcs1, Uint8List.fromList(bytes), verbose);
  _testEncryptAndDecrypt(
      rsaPair, AsymBlockCipherToUse.oaep, Uint8List.fromList(bytes), verbose);
}

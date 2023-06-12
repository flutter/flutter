/// Demonstrates different approaches to importing Pointy Castle libraries.
///
/// - import-demo-1.dart - import 'package:pointycastle/pointycastle.dart';
///                        can only used registry
/// - import-demo-2.dart - import 'package:pointycastle/export.dart';
///                        can use registry and all constructors
/// - import-demo-3.dart - import 'package:pointycastle/api.dart' plus
///                        individual libraries; can use registry and
///                        constructors from individually imported libraries
/// - import-demo-4.dart - import 'package:pointycastle/api.dart' plus
///                        individual libraries; same as 3, but tries
///                        to use the registry for classes that have NOT
///                        been individually imported. This should not
///                        work, but strangely does.
///
/// The useRegistry and explicit functions are the same in all examples,
/// but they can or cannot be used depending on what imports were used.
///
/// To see the differences between the examples, run 'diff' on the files.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

void main() {
  useRegistry();
  useConstructors();
}

void useRegistry() {
  final sha256 = Digest('SHA-256');
  final sha1 = Digest('SHA-1');
  final md5 = Digest('MD5');

  final _digest = sha256.process(Uint8List.fromList(_data));

  final hmacSha256 = Mac('SHA-256/HMAC');
  final hmacSha512 = Mac('SHA-512/HMAC');
  final hmacMd5 = Mac('MD5/HMAC');

  final _hmacValue = hmacSha256.process(Uint8List.fromList(_data));

  //final kd = KeyDerivator('SHA-256/HMAC/PBKDF2');

  final _sGen = Random.secure();
  final _seed = Platform.instance.platformEntropySource().getBytes(32);
  final secRnd = SecureRandom('Fortuna')..seed(KeyParameter(_seed));

  // AES-CBC encryption

  final _salt = secRnd.nextBytes(32);

  final keyDerivator256 = KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(_salt, 10000, 256 ~/ 8));

  final aes256key = keyDerivator256.process(Uint8List.fromList(_secret));

  final _iv = secRnd.nextBytes(128 ~/ 8);
  final aesCbc = BlockCipher('AES/CBC')
    ..init(true, ParametersWithIV(KeyParameter(aes256key), _iv));

  final _paddedData = Uint8List(
      _data.length + (aesCbc.blockSize - (_data.length % aesCbc.blockSize)))
    ..setAll(0, _data);
  Padding('PKCS7').addPadding(_paddedData, _data.length);

  final _ciphertext = aesCbc.process(_paddedData);

  // RSA key generation and signing

  final keyGen = KeyGenerator('RSA');
  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64), secRnd));
  final _pair = keyGen.generateKeyPair();

  final signer = Signer('SHA-256/RSA')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(_pair.privateKey));

  final _signature =
      signer.generateSignature(Uint8List.fromList(_data)) as RSASignature;

  final verifier = Signer('SHA-256/RSA')
    ..init(false, PublicKeyParameter<RSAPublicKey>(_pair.publicKey));
  final sigOk = verifier.verifySignature(Uint8List.fromList(_data), _signature);

  print('''
Data: '${utf8.decode(Uint8List.fromList(_data))}'

SHA-256: ${bin2hex(_digest)}
SHA-1:   ${bin2hex(sha1.process(Uint8List.fromList(_data)))}
MD5:     ${bin2hex(md5.process(Uint8List.fromList(_data)), separator: ':')}

HMAC-SHA256: ${bin2hex(_hmacValue)}
HMAC-512:    ${bin2hex(hmacSha512.process(Uint8List.fromList(_data)))}
HMAC-MD5:    ${bin2hex(hmacMd5.process(Uint8List.fromList(_data)))}

AES-CBC ciphertext:
${bin2hex(_ciphertext, wrap: 64)}

Signature:
${bin2hex(_signature.bytes, wrap: 64)}
Verifies: $sigOk
''');
}

void useConstructors() {
  // Digest

  final sha256 = SHA256Digest();
  final sha1 = SHA1Digest();
  final md5 = MD5Digest();

  final _digest = sha256.process(Uint8List.fromList(_data));

  // HMAC

  final hmacSha256 = HMac(SHA256Digest(), 64)
    ..init(KeyParameter(Uint8List.fromList(_secret)));
  final hmacSha512 = HMac(SHA512Digest(), 128)
    ..init(KeyParameter(Uint8List.fromList(_secret)));
  final hmacMd5 = HMac(MD5Digest(), 64)
    ..init(KeyParameter(Uint8List.fromList(_secret)));

  final _hmacValue = hmacSha256.process(Uint8List.fromList(_data));

  // Secure random number generator

  final _sGen = Random.secure();
  final _seed = Platform.instance.platformEntropySource().getBytes(32);
  final secRnd = FortunaRandom()..seed(KeyParameter(_seed));

  // AES-CBC encryption

  final _salt = secRnd.nextBytes(32);

  final keyDerivator256 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(_salt, 10000, 256 ~/ 8));

  final aes256key = keyDerivator256.process(Uint8List.fromList(_secret));

  final _iv = secRnd.nextBytes(128 ~/ 8);
  final aesCbc = CBCBlockCipher(AESEngine())
    ..init(true, ParametersWithIV(KeyParameter(aes256key), _iv));

  final _paddedData = Uint8List(
      _data.length + (aesCbc.blockSize - (_data.length % aesCbc.blockSize)))
    ..setAll(0, _data);
  PKCS7Padding().addPadding(_paddedData, _data.length);

  final _ciphertext = aesCbc.process(_paddedData);

  // RSA key generation and signing

  final keyGen = RSAKeyGenerator();
  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64), secRnd));
  final _pair = keyGen.generateKeyPair();

  final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(_pair.privateKey));

  final _signature = signer.generateSignature(Uint8List.fromList(_data));

  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(false, PublicKeyParameter<RSAPublicKey>(_pair.publicKey));
  final sigOk = verifier.verifySignature(Uint8List.fromList(_data), _signature);

  print('''
Data: '${utf8.decode(Uint8List.fromList(_data))}'

SHA-256: ${bin2hex(_digest)}
SHA-1:   ${bin2hex(sha1.process(Uint8List.fromList(_data)))}
MD5:     ${bin2hex(md5.process(Uint8List.fromList(_data)), separator: ':')}

HMAC-SHA256: ${bin2hex(_hmacValue)}
HMAC-512:    ${bin2hex(hmacSha512.process(Uint8List.fromList(_data)))}
HMAC-MD5:    ${bin2hex(hmacMd5.process(Uint8List.fromList(_data)))}

AES-CBC ciphertext:
${bin2hex(_ciphertext, wrap: 64)}

Signature:
${bin2hex(_signature.bytes, wrap: 64)}
Verifies: $sigOk
''');
}

//----------------------------------------------------------------

final _data = utf8.encode('Hello world!');

final _secret = utf8.encode('p@ssw0rd');

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

// See file LICENSE for more information.

library impl.signer.rsa_signer;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/src/registry/registry.dart';

// TODO: implement full ASN1 encoding (for now I will do a little ad-hoc implementation of just what is needed here)
class RSASigner implements Signer {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig =
      DynamicFactoryConfig.suffix(Signer, '/RSA', (_, Match match) {
    final digestName = match.group(1);
    final digestIdentifierHex = _digestIdentifierHexes[digestName!];
    if (digestIdentifierHex == null) {
      throw RegistryFactoryException(
          'RSA signing with digest $digestName is not supported');
    }
    return () => RSASigner(Digest(digestName), digestIdentifierHex);
  });

  static final Map<String, String> _digestIdentifierHexes = {
    'MD2': '06082a864886f70d0202',
    'MD4': '06082a864886f70d0204',
    'MD5': '06082a864886f70d0205',
    'RIPEMD-128': '06052b24030202',
    'RIPEMD-160': '06052b24030201',
    'RIPEMD-256': '06052b24030203',
    'SHA-1': '06052b0e03021a',
    'SHA-224': '0609608648016503040204',
    'SHA-256': '0609608648016503040201',
    'SHA-384': '0609608648016503040202',
    'SHA-512': '0609608648016503040203'
  };

  final AsymmetricBlockCipher _rsa = PKCS1Encoding(RSAEngine());
  final Digest _digest;
  late Uint8List
      _digestIdentifier; // DER encoded with trailing tag (06)+length byte
  late bool _forSigning;

  RSASigner(this._digest, String digestIdentifierHex) {
    _digestIdentifier = _hexStringToBytes(digestIdentifierHex);
  }

  @override
  String get algorithmName => '${_digest.algorithmName}/RSA';

  @override
  void reset() {
    _digest.reset();
    _rsa.reset();
  }

  @override
  void init(bool forSigning, CipherParameters params) {
    _forSigning = forSigning;

    AsymmetricKeyParameter akparams;
    if (params is ParametersWithRandom) {
      akparams = params.parameters as AsymmetricKeyParameter<AsymmetricKey>;
    } else {
      akparams = params as AsymmetricKeyParameter<AsymmetricKey>;
    }
    var k = akparams.key as RSAAsymmetricKey;

    if (forSigning && (k is! RSAPrivateKey)) {
      throw ArgumentError('Signing requires private key');
    }

    if (!forSigning && (k is! RSAPublicKey)) {
      throw ArgumentError('Verification requires public key');
    }

    reset();

    _rsa.init(forSigning, params);
  }

  @override
  RSASignature generateSignature(Uint8List message, {bool normalize = false}) {
    if (!_forSigning) {
      throw StateError('Signer was not initialised for signature generation');
    }

    var hash = Uint8List(_digest.digestSize);
    _digest.reset();
    _digest.update(message, 0, message.length);
    _digest.doFinal(hash, 0);

    var data = _derEncode(hash);
    var out = Uint8List(_rsa.outputBlockSize);
    var len = _rsa.processBlock(data, 0, data.length, out, 0);
    return RSASignature(out.sublist(0, len));
  }

  @override
  bool verifySignature(Uint8List message, covariant RSASignature signature) {
    if (_forSigning) {
      throw StateError('Signer was not initialised for signature verification');
    }

    var hash = Uint8List(_digest.digestSize);
    _digest.reset();
    _digest.update(message, 0, message.length);
    _digest.doFinal(hash, 0);
    var sig = Uint8List(_rsa.outputBlockSize);

    try {
      final len =
          _rsa.processBlock(signature.bytes, 0, signature.bytes.length, sig, 0);
      sig = sig.sublist(0, len);
    } on ArgumentError {
      // Signature was tampered with so the RSA 'decrypted' block is totally
      // different to the original, causing [PKCS1Encoding._decodeBlock] to
      // throw an exception because it does not recognise it.
      return false;
    }

    var expected = _derEncode(hash);

    if (sig.length == expected.length) {
      for (var i = 0; i < sig.length; i++) {
        if (sig[i] != expected[i]) {
          return false;
        }
      }
      return true; //return Arrays.constantTimeAreEqual(sig, expected);

    } else if (sig.length == expected.length - 2) {
      // NULL left out
      var sigOffset = sig.length - hash.length - 2;
      var expectedOffset = expected.length - hash.length - 2;

      expected[1] -= 2; // adjust lengths
      expected[3] -= 2;

      var nonEqual = 0;

      for (var i = 0; i < hash.length; i++) {
        nonEqual |= (sig[sigOffset + i] ^ expected[expectedOffset + i]);
      }

      for (var i = 0; i < sigOffset; i++) {
        nonEqual |= (sig[i] ^ expected[i]); // check header less NULL
      }

      return nonEqual == 0;
    } else {
      return false;
    }
  }

  Uint8List _derEncode(Uint8List hash) {
    var out = Uint8List(2 + 2 + _digestIdentifier.length + 2 + 2 + hash.length);
    var i = 0;

    // header
    out[i++] = 48;
    out[i++] = out.length - 2;

    // algorithmIdentifier.header
    out[i++] = 48;
    out[i++] = _digestIdentifier.length + 2;

    // algorithmIdentifier.bytes
    out.setAll(i, _digestIdentifier);
    i += _digestIdentifier.length;

    // algorithmIdentifier.null
    out[i++] = 5;
    out[i++] = 0;

    // hash.header
    out[i++] = 4;
    out[i++] = hash.length;

    // hash.bytes
    out.setAll(i, hash);

    return out;
  }

  Uint8List _hexStringToBytes(String hex) {
    var result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var num = hex.substring(i, i + 2);
      var byte = int.parse(num, radix: 16);
      result[i ~/ 2] = byte;
    }
    return result;
  }
}

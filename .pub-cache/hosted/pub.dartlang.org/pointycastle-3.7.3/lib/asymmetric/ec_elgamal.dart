// See file LICENSE for more information.

library impl.asymmetric.ecc.elgamal;

import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

BigInt _generateK(BigInt n, SecureRandom random) {
  var nBitLength = n.bitLength;
  BigInt k;
  do {
    k = random.nextBigInteger(nBitLength);
  } while ((k == BigInt.zero) || (k.compareTo(n) >= 0));
  return k;
}

SecureRandom _newSecureRandom() => FortunaRandom()
  ..seed(KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));

/// The basic ElGamal encryptor using Elliptic Curve
class ECElGamalEncryptor implements ECEncryptor {
  ECPublicKey? _key;
  late SecureRandom _random;

  /// Process a single EC [point] using the basic ElGamal algorithm.
  @override
  ECPair encrypt(ECPoint point) {
    if (_key == null) {
      throw StateError('ECElGamalEncryptor is not initialised');
    }
    var key = _key!;
    var ec = key.parameters!;
    var k = _generateK(ec.n, _random);
    return ECPair(
      (ec.G * k)!,
      ((key.Q! * k)! + point)!,
    );
  }

  @override
  void init(CipherParameters params) {
    AsymmetricKeyParameter akparams;
    if (params is ParametersWithRandom) {
      akparams = params.parameters as AsymmetricKeyParameter<AsymmetricKey>;
      _random = params.random;
    } else {
      akparams = params as AsymmetricKeyParameter<AsymmetricKey>;
      _random = _newSecureRandom();
    }
    var k = akparams.key as ECAsymmetricKey;
    if (!(k is ECPublicKey)) {
      throw ArgumentError('ECPublicKey is required for encryption.');
    }
    _key = k;
  }
}

/// The basic ElGamal decryptor using Elliptic Curve
class ECElGamalDecryptor implements ECDecryptor {
  ECPrivateKey? _key;

  /// Decrypt an EC [pair] producing the original [ECPoint].
  @override
  ECPoint decrypt(ECPair pair) {
    if (_key == null) {
      throw StateError('ECElGamalEncryptor is not initialised');
    }
    return (pair.y - (pair.x * _key!.d)!)!;
  }

  @override
  void init(CipherParameters params) {
    var akparams = params as AsymmetricKeyParameter<AsymmetricKey>;
    var k = akparams.key as ECAsymmetricKey;
    if (!(k is ECPrivateKey)) {
      throw ArgumentError('ECPrivateKey is required for decryption.');
    }
    _key = k;
  }
}

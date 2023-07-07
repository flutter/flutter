// See file LICENSE for more information.

library api.asymmetric;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';

/// Base class for asymmetric keys in RSA
abstract class RSAAsymmetricKey implements AsymmetricKey {
  // The parameters of this key
  final BigInt? modulus;
  final BigInt? exponent;

  /// Create an asymmetric key for the given domain parameters
  RSAAsymmetricKey(this.modulus, this.exponent);

  /// Get modulus [n] = p·q
  BigInt? get n => modulus;
}

/// Private keys in RSA
class RSAPrivateKey extends RSAAsymmetricKey implements PrivateKey {
  // The secret prime factors of n
  final BigInt? p;
  final BigInt? q;
  BigInt? _pubExp;

  /// Create an RSA private key for the given parameters.
  ///
  /// The optional public exponent parameter has been deprecated. It does not
  /// have to be provided, because it can be calculated from the other values.
  /// The optional parameter is retained for backward compatibility, but it
  /// does not need to be provided.

  RSAPrivateKey(
      BigInt modulus,
      BigInt privateExponent,
      this.p,
      this.q,
      [@Deprecated('Public exponent is calculated from the other values')
          BigInt? publicExponent])
      : super(modulus, privateExponent) {
    // Check RSA relationship between p, q and modulus hold true.

    if (p! * q! != modulus) {
      throw ArgumentError.value('modulus inconsistent with RSA p and q');
    }

    // Calculate the correct RSA public exponent

    _pubExp =
        privateExponent.modInverse(((p! - BigInt.one) * (q! - BigInt.one)));

    // If explicitly provided, the public exponent value must be correct.
    if (publicExponent != null && publicExponent != _pubExp) {
      throw ArgumentError(
          'public exponent inconsistent with RSA private exponent, p and q');
    }
  }

  /// Get private exponent [d] = e^-1
  @Deprecated('Use privateExponent.')
  BigInt? get d => exponent;

  /// Get the private exponent (d)
  BigInt? get privateExponent => exponent;

  /// Get the public exponent (e)
  BigInt? get publicExponent => _pubExp;

  /// Get the public exponent (e)
  @Deprecated('Use publicExponent.')
  BigInt? get pubExponent => publicExponent;

  @override
  bool operator ==(other) {
    if (other is RSAPrivateKey) {
      return other.privateExponent == privateExponent &&
          other.modulus == modulus;
    }
    return false;
  }

  @override
  int get hashCode => modulus.hashCode + privateExponent.hashCode;
}

/// Public keys in RSA
class RSAPublicKey extends RSAAsymmetricKey implements PublicKey {
  /// Create an RSA public key for the given parameters.
  RSAPublicKey(BigInt modulus, BigInt exponent) : super(modulus, exponent);

  /// Get public exponent [e]
  @Deprecated('Use get publicExponent')
  BigInt? get e => exponent;

  /// Get the public exponent.
  BigInt? get publicExponent => exponent;

  @override
  bool operator ==(other) {
    if (other is RSAPublicKey) {
      return (other.modulus == modulus) &&
          (other.publicExponent == publicExponent);
    }
    return false;
  }

  @override
  int get hashCode => modulus.hashCode + publicExponent.hashCode;
}

/// A [Signature] created with RSA.
class RSASignature implements Signature {
  final Uint8List bytes;

  RSASignature(this.bytes);

  @override
  String toString() => bytes.toString();
  @override
  bool operator ==(other) {
    if (other is! RSASignature) return false;
    if (other.bytes.length != bytes.length) return false;

    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => bytes.hashCode;
}

/// A [Signature] created with PSS.
class PSSSignature implements Signature {
  final Uint8List bytes;

  PSSSignature(this.bytes);

  @override
  String toString() => bytes.toString();

  @override
  bool operator ==(other) {
    if (other is! PSSSignature) return false;
    if (other.bytes.length != bytes.length) return false;

    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => bytes.hashCode;
}

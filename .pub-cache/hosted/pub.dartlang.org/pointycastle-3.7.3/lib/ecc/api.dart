// See file LICENSE for more information.

library api.ecc;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';

export 'ecdh.dart';

/// Standard ECC curve description
abstract class ECDomainParameters {
  /// Get this domain's standard name.
  String get domainName;

  ECCurve get curve;

  List<int>? get seed;

  ECPoint get G;

  BigInt get n;

  /// Create a curve description from its standard name
  factory ECDomainParameters(String domainName) =>
      registry.create<ECDomainParameters>(domainName);
}

/// Type for coordinates of an [ECPoint]
abstract class ECFieldElement {
  BigInt? toBigInteger();

  String get fieldName;

  int get fieldSize;

  int get byteLength;

  ECFieldElement operator +(ECFieldElement b);

  ECFieldElement operator -(ECFieldElement b);

  ECFieldElement operator *(ECFieldElement b);

  ECFieldElement operator /(ECFieldElement b);

  ECFieldElement operator -();

  ECFieldElement invert();

  ECFieldElement square();

  ECFieldElement? sqrt();
}

/// An elliptic curve point
abstract class ECPoint {
  ECCurve get curve;

  ECFieldElement? get x;

  ECFieldElement? get y;

  bool get isCompressed;

  bool get isInfinity;

  @override
  bool operator ==(other);

  Uint8List getEncoded([bool compressed = true]);

  ECPoint? operator +(ECPoint? b);

  ECPoint? operator -(ECPoint b);

  ECPoint operator -();

  ECPoint? twice();

  /// Multiply this point by the given number [k].
  ECPoint? operator *(BigInt? k);

  @override
  int get hashCode => super.hashCode;
}

/// An elliptic curve
abstract class ECCurve {
  ECFieldElement? get a;

  ECFieldElement? get b;

  int get fieldSize;

  ECPoint? get infinity;

  /// Create an [ECFieldElement] on this curve from its big integer value.
  ECFieldElement fromBigInteger(BigInt x);

  /// Create an [ECPoint] on its curve from its coordinates
  ECPoint createPoint(BigInt x, BigInt y, [bool withCompression = false]);

  ECPoint decompressPoint(int yTilde, BigInt x1);

  /// Decode a point on this curve from its ASN.1 encoding. The different encodings are taken account of, including point
  /// compression for Fp (X9.62 s 4.2.1 pg 17).
  ECPoint? decodePoint(List<int> encoded);
}

/// Base class for asymmetric keys in ECC
abstract class ECAsymmetricKey implements AsymmetricKey {
  /// The domain parameters of this key
  final ECDomainParameters? parameters;

  /// Create an asymmetric key for the given domain parameters
  ECAsymmetricKey(this.parameters);
}

/// Private keys in ECC
class ECPrivateKey extends ECAsymmetricKey implements PrivateKey {
  /// ECC's d private parameter
  final BigInt? d;

  /// Create an ECC private key for the given d and domain parameters.
  ECPrivateKey(this.d, ECDomainParameters? parameters) : super(parameters);
  @override
  bool operator ==(other) {
    if (other is! ECPrivateKey) return false;
    return (other.parameters == parameters) && (other.d == d);
  }

  @override
  int get hashCode {
    return parameters.hashCode + d.hashCode;
  }
}

/// Public keys in ECC
class ECPublicKey extends ECAsymmetricKey implements PublicKey {
  /// ECC's Q public parameter
  final ECPoint? Q;

  /// Create an ECC public key for the given Q and domain parameters.
  ECPublicKey(this.Q, ECDomainParameters? parameters) : super(parameters);
  @override
  bool operator ==(other) {
    if (other is! ECPublicKey) return false;
    return (other.parameters == parameters) && (other.Q == Q);
  }

  @override
  int get hashCode {
    return parameters.hashCode + Q.hashCode;
  }
}

/// A [Signature] created with ECC.
class ECSignature implements Signature {
  final BigInt r;
  final BigInt s;

  ECSignature(this.r, this.s);

  /// Returns true if s is in lower-s form, false otherwise.
  bool isNormalized(ECDomainParameters curveParams) {
    return !(s.compareTo(curveParams.n >> 1) > 0);
  }

  ///
  /// 'normalize' this signature by converting its s to lower-s form if necessary
  /// This is required to validate this signature with some libraries such as libsecp256k1
  /// which enforce lower-s form for all signatures to combat ecdsa signature malleability
  ///
  /// Returns this if the signature was already normalized, or a copy if it is changed.
  ///
  ECSignature normalize(ECDomainParameters curveParams) {
    if (isNormalized(curveParams)) {
      return this;
    }
    return ECSignature(r, curveParams.n - s);
  }

  @override
  String toString() => '(${r.toString()},${s.toString()})';
  @override
  bool operator ==(other) {
    if (other is! ECSignature) return false;
    return (other.r == r) && (other.s == s);
  }

  @override
  int get hashCode {
    return r.hashCode + s.hashCode;
  }
}

/// A pair of [ECPoint]s.
class ECPair {
  final ECPoint x;
  final ECPoint y;

  const ECPair(this.x, this.y);

  @override
  bool operator ==(other) {
    if (other is! ECPair) return false;
    return (other.x == x) && (other.y == y);
  }

  @override
  int get hashCode => x.hashCode + y.hashCode * 37;
}

/// The encryptor using Elliptic Curve
abstract class ECEncryptor {
  ECPair encrypt(ECPoint point);

  /// Initialize the encryptor.
  void init(CipherParameters params);
}

/// The decryptor using Elliptic Curve
abstract class ECDecryptor {
  ECPoint decrypt(ECPair pair);

  /// Initialize the decryptor.
  void init(CipherParameters params);
}

abstract class ECDHAgreement {
  /// initialise the agreement engine.
  void init(ECPrivateKey param);

  /// return the field size for the agreement algorithm in bytes.
  int getFieldSize();

  /// given a public key from a given party calculate the next
  /// message in the agreement sequence.
  BigInt calculateAgreement(ECPublicKey pubKey);
}

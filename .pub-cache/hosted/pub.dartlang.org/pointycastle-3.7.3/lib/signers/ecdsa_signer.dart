// See file LICENSE for more information.

library impl.signer.ecdsa_signer;

import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/utils.dart' as utils;

bool _testBit(BigInt i, int n) {
  return (i & (BigInt.one << n)) != BigInt.zero;
}

class ECDSASigner implements Signer {
  /// Intended for internal use.
  // ignore: non_constant_identifier_names
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
      Signer, r'^(.+)/(DET-)?ECDSA$', (_, final Match match) {
    // ignore: omit_local_variable_types
    final String? digestName = match.group(1);
    // ignore: omit_local_variable_types
    final bool withMac = match.group(2) != null;
    return () {
      var underlyingDigest = Digest(digestName!);
      var mac = withMac ? Mac('$digestName/HMAC') : null;
      return ECDSASigner(underlyingDigest, mac);
    };
  });

  ECPublicKey? _pbkey;
  ECPrivateKey? _pvkey;
  SecureRandom? _random;
  final Digest? _digest;
  final Mac? _kMac;

  /// If [_digest] is not null it is used to hash the message before signing and verifying, otherwise, the message needs to be
  /// hashed by the user of this [ECDSASigner] object.
  /// If [_kMac] is not null, RFC 6979 is used for k calculation with the given [Mac]. Keep in mind that, to comply with
  /// RFC 69679, [_kMac] must be HMAC with the same digest used to hash the message.
  ECDSASigner([this._digest, this._kMac]);

  @override
  String get algorithmName =>
      '${_digest!.algorithmName}/${_kMac == null ? '' : 'DET-'}ECDSA';

  @override
  void reset() {}

  /// Init this [Signer]. The [params] argument can be:
  /// -A [ParametersWithRandom] containing a [PrivateKeyParameter] or a raw [PrivateKeyParameter] for signing
  /// -An [PublicKeyParameter] for verifying.
  @override
  void init(bool forSigning, CipherParameters params) {
    _pbkey = _pvkey = null;

    if (forSigning) {
      PrivateKeyParameter pvparams;

      if (params is ParametersWithRandom) {
        _random = params.random;
        pvparams = params.parameters as PrivateKeyParameter<PrivateKey>;
      } else if (_kMac != null) {
        _random = null;
        pvparams = params as PrivateKeyParameter<PrivateKey>;
      } else {
        _random = SecureRandom();
        pvparams = params as PrivateKeyParameter<PrivateKey>;
      }

      _pvkey = pvparams.key as ECPrivateKey;
    } else {
      PublicKeyParameter pbparams;

      pbparams = params as PublicKeyParameter<PublicKey>;

      _pbkey = pbparams.key as ECPublicKey;
    }
  }

  @override
  Signature generateSignature(Uint8List message) {
    message = _hashMessageIfNeeded(message);

    var n = _pvkey!.parameters!.n;
    var e = _calculateE(n, message);
    BigInt r;
    BigInt s;

    dynamic kCalculator;
    if (_kMac != null) {
      kCalculator = _RFC6979KCalculator(_kMac!, n, _pvkey!.d!, message);
    } else {
      kCalculator = _RandomKCalculator(n, _random!);
    }

    // 5.3.2
    do {
      // generate s
      BigInt? k;

      do {
        // generate r
        k = kCalculator.nextK() as BigInt?;

        var p = (_pvkey!.parameters!.G * k)!;

        // 5.3.3
        var x = p.x!.toBigInteger()!;

        r = x % n;
      } while (r == BigInt.zero);

      var d = _pvkey!.d!;

      s = (k!.modInverse(n) * (e + (d * r))) % n;
    } while (s == BigInt.zero);

    return ECSignature(r, s);
  }

  @override
  bool verifySignature(Uint8List message, covariant ECSignature signature) {
    message = _hashMessageIfNeeded(message);

    var n = _pbkey!.parameters!.n;
    var e = _calculateE(n, message);

    var r = signature.r;
    var s = signature.s;

    // r in the range [1,n-1]
    if (r.compareTo(BigInt.one) < 0 || r.compareTo(n) >= 0) {
      return false;
    }

    // s in the range [1,n-1]
    if (s.compareTo(BigInt.one) < 0 || s.compareTo(n) >= 0) {
      return false;
    }

    var c = s.modInverse(n);

    var u1 = (e * c) % n;
    var u2 = (r * c) % n;

    var G = _pbkey!.parameters!.G;
    var Q = _pbkey!.Q!;

    var point = _sumOfTwoMultiplies(G, u1, Q, u2)!;

    // components must be bogus.
    if (point.isInfinity) {
      return false;
    }

    var v = point.x!.toBigInteger()! % n;

    return v == r;
  }

  Uint8List _hashMessageIfNeeded(Uint8List message) {
    if (_digest != null) {
      _digest!.reset();
      return _digest!.process(message);
    } else {
      return message;
    }
  }

  BigInt _calculateE(BigInt n, Uint8List message) {
    var log2n = n.bitLength;
    var messageBitLength = message.length * 8;

    if (log2n >= messageBitLength) {
      return utils.decodeBigIntWithSign(1, message);
    } else {
      var trunc = utils.decodeBigIntWithSign(1, message);

      trunc = trunc >> (messageBitLength - log2n);

      return trunc;
    }
  }

  ECPoint? _sumOfTwoMultiplies(ECPoint P, BigInt a, ECPoint Q, BigInt b) {
    var c = P.curve;

    if (c != Q.curve) {
      throw ArgumentError('P and Q must be on same curve');
    }

    // Point multiplication for Koblitz curves (using WTNAF) beats Shamir's trick
    // TODO: uncomment this when F2m available
    /*
    if( c is ECCurve.F2m ) {
      ECCurve.F2m f2mCurve = (ECCurve.F2m)c;
      if( f2mCurve.isKoblitz() ) {
        return P.multiply(a).add(Q.multiply(b));
      }
    }
    */

    return _implShamirsTrick(P, a, Q, b);
  }

  ECPoint? _implShamirsTrick(ECPoint P, BigInt k, ECPoint Q, BigInt l) {
    var m = max(k.bitLength, l.bitLength);

    var Z = P + Q;
    var R = P.curve.infinity;

    for (var i = m - 1; i >= 0; --i) {
      R = R!.twice();

      if (_testBit(k, i)) {
        if (_testBit(l, i)) {
          R = R! + Z;
        } else {
          R = R! + P;
        }
      } else {
        if (_testBit(l, i)) {
          R = R! + Q;
        }
      }
    }

    return R;
  }
}

class NormalizedECDSASigner implements Signer {
  final ECDSASigner signer;
  final bool enforceNormalized;

  /// Wraps ECDSASigner and enforces normalisation on verify if
  /// [enforceNormalized] is true.
  ///
  /// Always generates normalized signatures.
  NormalizedECDSASigner(this.signer, {this.enforceNormalized = false});

  @override
  String get algorithmName => signer.algorithmName;

  @override
  Signature generateSignature(Uint8List message) {
    return (signer.generateSignature(message) as ECSignature)
        .normalize(signer._pvkey!.parameters!);
  }

  @override
  void init(bool forSigning, CipherParameters params) {
    signer.init(forSigning, params);
  }

  @override
  void reset() {
    signer.reset();
  }

  @override
  bool verifySignature(Uint8List message, Signature signature) {
    var isNormalized =
        (signature as ECSignature).isNormalized(signer._pbkey!.parameters!);
    var isVerified = signer.verifySignature(message, signature);

    // Constant time.
    return (isNormalized | !enforceNormalized) & isVerified;
  }
}

class _RFC6979KCalculator {
  final Mac _mac;
  // ignore: non_constant_identifier_names
  late Uint8List _K;
  // ignore: non_constant_identifier_names
  late Uint8List _V;
  final BigInt _n;

  _RFC6979KCalculator(this._mac, this._n, BigInt d, Uint8List message) {
    _V = Uint8List(_mac.macSize);
    _K = Uint8List(_mac.macSize);
    _init(d, message);
  }

  void _init(BigInt d, Uint8List message) {
    _V.fillRange(0, _V.length, 0x01);
    _K.fillRange(0, _K.length, 0x00);

    var x = Uint8List((_n.bitLength + 7) ~/ 8);
    var dVal = _asUnsignedByteArray(d);

    x.setRange((x.length - dVal.length), x.length, dVal);

    var m = Uint8List((_n.bitLength + 7) ~/ 8);

    var mInt = _bitsToInt(message);

    if (mInt > _n) {
      mInt -= _n;
    }

    var mVal = _asUnsignedByteArray(mInt);

    m.setRange((m.length - mVal.length), m.length, mVal);

    _mac.init(KeyParameter(_K));

    _mac.update(_V, 0, _V.length);
    _mac.updateByte(0x00);
    _mac.update(x, 0, x.length);
    _mac.update(m, 0, m.length);
    _mac.doFinal(_K, 0);

    _mac.init(KeyParameter(_K));
    _mac.update(_V, 0, _V.length);
    _mac.doFinal(_V, 0);

    _mac.update(_V, 0, _V.length);
    _mac.updateByte(0x01);
    _mac.update(x, 0, x.length);
    _mac.update(m, 0, m.length);
    _mac.doFinal(_K, 0);

    _mac.init(KeyParameter(_K));
    _mac.update(_V, 0, _V.length);
    _mac.doFinal(_V, 0);
  }

  BigInt nextK() {
    var t = Uint8List((_n.bitLength + 7) ~/ 8);

    for (;;) {
      var tOff = 0;

      while (tOff < t.length) {
        _mac.update(_V, 0, _V.length);
        _mac.doFinal(_V, 0);

        if ((t.length - tOff) < _V.length) {
          t.setRange(tOff, t.length, _V);
          tOff += (t.length - tOff);
        } else {
          t.setRange(tOff, tOff + _V.length, _V);
          tOff += _V.length;
        }
      }

      var k = _bitsToInt(t);

      // ignore: unrelated_type_equality_checks
      if ((k == 0) || (k >= _n)) {
        _mac.update(_V, 0, _V.length);
        _mac.updateByte(0x00);
        _mac.doFinal(_K, 0);

        _mac.init(KeyParameter(_K));
        _mac.update(_V, 0, _V.length);
        _mac.doFinal(_V, 0);
      } else {
        return k;
      }
    }
  }

  BigInt _bitsToInt(Uint8List t) {
    var v = utils.decodeBigIntWithSign(1, t);
    if ((t.length * 8) > _n.bitLength) {
      v = v >> ((t.length * 8) - _n.bitLength);
    }

    return v;
  }

  Uint8List _asUnsignedByteArray(BigInt value) {
    var bytes = utils.encodeBigInt(value);

    if (bytes[0] == 0) {
      return Uint8List.fromList(bytes.sublist(1));
    } else {
      return Uint8List.fromList(bytes);
    }
  }
}

class _RandomKCalculator {
  final BigInt _n;
  final SecureRandom _random;

  _RandomKCalculator(this._n, this._random);

  BigInt nextK() {
    BigInt k;
    do {
      k = _random.nextBigInteger(_n.bitLength);
    } while (k == BigInt.zero || k >= _n);
    return k;
  }
}

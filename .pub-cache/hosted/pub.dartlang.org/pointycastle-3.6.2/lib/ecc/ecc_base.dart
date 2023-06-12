// See file LICENSE for more information.

library impl.ecc.ecc_base;
//TODO I think this stuff might be moved to src/impl

import 'dart:typed_data';

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/src/utils.dart' as utils;

/// Implementation of [ECDomainParameters]
class ECDomainParametersImpl implements ECDomainParameters {
  @override
  final String domainName;
  @override
  final ECCurve curve;
  @override
  final List<int>? seed;
  @override
  final ECPoint G;
  @override
  final BigInt n;
  BigInt? _h;

  ECDomainParametersImpl(this.domainName, this.curve, this.G, this.n,
      [this._h, this.seed]) {
    _h ??= BigInt.one;
  }

  BigInt? get h => _h;
}

/// Base implementation for [ECFieldElement]
abstract class ECFieldElementBase implements ECFieldElement {
  @override
  BigInt? toBigInteger();

  @override
  String get fieldName;

  @override
  int get fieldSize;

  @override
  int get byteLength => ((fieldSize + 7) ~/ 8);

  @override
  ECFieldElementBase operator +(covariant ECFieldElementBase b);

  @override
  ECFieldElementBase operator -(covariant ECFieldElementBase b);

  @override
  ECFieldElementBase operator *(covariant ECFieldElementBase b);

  @override
  ECFieldElementBase operator /(covariant ECFieldElementBase b);

  @override
  ECFieldElementBase operator -();

  @override
  ECFieldElementBase invert();

  @override
  ECFieldElementBase square();

  @override
  ECFieldElementBase? sqrt();

  @override
  String toString() => toBigInteger().toString();
}

/// Base implementation for [ECPoint]
abstract class ECPointBase implements ECPoint {
  @override
  final ECCurveBase curve;
  @override
  final ECFieldElementBase? x;
  @override
  final ECFieldElementBase? y;
  @override
  final bool isCompressed;
  final ECMultiplier _multiplier;

  PreCompInfo? _preCompInfo;

  ECPointBase(this.curve, this.x, this.y, this.isCompressed,
      [this._multiplier = _fpNafMultiplier]);

  @override
  bool get isInfinity => (x == null && y == null);

  set preCompInfo(PreCompInfo preCompInfo) {
    _preCompInfo = preCompInfo;
  }

  @override
  bool operator ==(other) {
    if (other is ECPointBase) {
      if (isInfinity) {
        return other.isInfinity;
      }
      return x == other.x && y == other.y;
    }
    return false;
  }

  @override
  String toString() => '($x,$y)';

  @override
  int get hashCode {
    if (isInfinity) {
      return 0;
    }
    return x.hashCode ^ y.hashCode;
  }

  @override
  Uint8List getEncoded([bool compressed = true]);

  @override
  ECPointBase? operator +(covariant ECPointBase? b);

  @override
  ECPointBase? operator -(covariant ECPointBase b);

  @override
  ECPointBase operator -();

  @override
  ECPointBase? twice();

  /// Multiplies this <code>ECPoint</code> by the given number.
  /// @param k The multiplicator.
  /// @return <code>k * this</code>.
  @override
  ECPointBase? operator *(BigInt? k) {
    if (k!.sign < 0) {
      throw ArgumentError('The multiplicator cannot be negative');
    }

    if (isInfinity) {
      return this;
    }

    if (k.sign == 0) {
      return curve.infinity;
    }

    return _multiplier(this, k, _preCompInfo);
  }
}

/// Base implementation for [ECCurve]
abstract class ECCurveBase implements ECCurve {
  ECFieldElementBase? _a;
  ECFieldElementBase? _b;

  ECCurveBase(BigInt? a, BigInt? b) {
    _a = fromBigInteger(a);
    _b = fromBigInteger(b);
  }

  @override
  ECFieldElementBase? get a => _a;

  @override
  ECFieldElementBase? get b => _b;

  @override
  int get fieldSize;

  @override
  ECPointBase? get infinity;

  @override
  ECFieldElementBase fromBigInteger(BigInt? x);

  @override
  ECPointBase createPoint(BigInt x, BigInt y, [bool withCompression = false]);

  @override
  ECPointBase decompressPoint(int yTilde, BigInt x1);

  /// Decode a point on this curve from its ASN.1 encoding. The different
  /// encodings are taken account of, including point compression for
  /// <code>F<sub>p</sub></code> (X9.62 s 4.2.1 pg 17).
  /// @return The decoded point.
  @override
  ECPointBase? decodePoint(List<int> encoded) {
    ECPointBase? p;
    var expectedLength = (fieldSize + 7) ~/ 8;

    switch (encoded[0]) {
      case 0x00: // infinity
        if (encoded.length != 1) {
          throw ArgumentError('Incorrect length for infinity encoding');
        }

        p = infinity;
        break;

      case 0x02: // compressed
      case 0x03: // compressed
        if (encoded.length != (expectedLength + 1)) {
          throw ArgumentError('Incorrect length for compressed encoding');
        }

        var yTilde = encoded[0] & 1;
        var x1 = _fromArray(encoded, 1, expectedLength);

        p = decompressPoint(yTilde, x1);
        break;

      case 0x04: // uncompressed
      case 0x06: // hybrid
      case 0x07: // hybrid
        if (encoded.length != (2 * expectedLength + 1)) {
          throw ArgumentError(
              'Incorrect length for uncompressed/hybrid encoding');
        }

        var x1 = _fromArray(encoded, 1, expectedLength);
        var y1 = _fromArray(encoded, 1 + expectedLength, expectedLength);

        p = createPoint(x1, y1, false);
        break;

      default:
        throw ArgumentError(
            'Invalid point encoding 0x' + encoded[0].toRadixString(16));
    }

    return p;
  }

  BigInt _fromArray(List<int> buf, int off, int length) {
    return utils.decodeBigIntWithSign(1, buf.sublist(off, off + length));
  }
}

/// Interface for classes storing precomputation data for multiplication algorithms.
abstract class PreCompInfo {}

/// Interface for functions encapsulating a point multiplication algorithm for [ECPointBase]. Multiplies [p] by [k], i.e. [p] is
/// added [k] times to itself.
typedef ECMultiplier = ECPointBase? Function(
    ECPointBase p, BigInt? k, PreCompInfo? preCompInfo);

bool _testBit(BigInt i, int n) {
  return i & (BigInt.one << n) != BigInt.zero;
}

/// Function implementing the NAF (Non-Adjacent Form) multiplication algorithm.
ECPointBase? _fpNafMultiplier(
    ECPointBase p, BigInt? k, PreCompInfo? preCompInfo) {
  // TODO Probably should try to add this
  // BigInt e = k.mod(n); // n == order of p
  var e = k;
  var h = e! * BigInt.from(3);

  var neg = -p;
  ECPointBase? R = p;

  for (var i = h.bitLength - 2; i > 0; --i) {
    R = R!.twice();

    var hBit = _testBit(h, i);
    var eBit = _testBit(e, i);

    if (hBit != eBit) {
      R = R! + (hBit ? p : neg);
    }
  }

  return R;
}

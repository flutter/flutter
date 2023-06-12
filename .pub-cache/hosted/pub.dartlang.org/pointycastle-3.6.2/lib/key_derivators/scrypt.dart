// See file LICENSE for more information.

library impl.key_derivator.scrypt;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/src/impl/base_key_derivator.dart';
import 'package:pointycastle/src/registry/registry.dart';

///
/// Implementation of SCrypt password based key derivation function. See the next link for info on
/// how to choose N, r, and p:
/// * <http://stackoverflow.com/questions/11126315/what-are-optimal-scrypt-work-factors>
///
/// This implementation is based on Java implementation by Will Glozer, which can be found at:
/// * <https://github.com/wg/scrypt>
///
class Scrypt extends BaseKeyDerivator {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(KeyDerivator, 'scrypt', () => Scrypt());

  static final int _maxValue = 0x7fffffff;

  ScryptParameters? _params;

  @override
  final String algorithmName = 'scrypt';

  @override
  int get keySize => _params!.desiredKeyLength;

  void reset() {
    _params = null;
  }

  @override
  void init(covariant ScryptParameters params) {
    _params = params;

    final N = _params!.N;
    final r = _params!.r;
    final p = _params!.p;

    if (N < 2 || (N & (N - 1)) != 0) {
      throw ArgumentError('N must be a power of 2 greater than 1');
    }

    if (N > _maxValue ~/ 128 ~/ r) {
      throw ArgumentError('Parameter N is too large');
    }

    if (r > _maxValue ~/ 128 ~/ p) {
      throw ArgumentError('Parameter r is too large');
    }
  }

  @override
  int deriveKey(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if (_params == null) {
      throw StateError('Initialize first.');
    }

    _scryptJ(inp, inpOff, out, outOff, _params!.salt, _params!.N, _params!.r,
        _params!.p, _params!.desiredKeyLength);

    return keySize;
  }

  void _scryptJ(Uint8List pwd, int pwdOff, Uint8List dk, int dkOff,
      Uint8List salt, int N, int r, int p, int dkLen) {
    final b = Uint8List(128 * r * p);
    final xy = Uint8List(256 * r);
    final v = Uint8List(128 * r * N);

    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));

    pbkdf2.init(Pbkdf2Parameters(salt, 1, p * 128 * r));
    pbkdf2.deriveKey(pwd, pwdOff, b, 0);

    for (var i = 0; i < p; i++) {
      _smix(b, i * 128 * r, r, N, v, xy);
    }

    pbkdf2.init(Pbkdf2Parameters(b, 1, dkLen));
    pbkdf2.deriveKey(pwd, pwdOff, dk, dkOff);
  }

  void _smix(Uint8List B, int bi, int r, int N, Uint8List V, Uint8List xy) {
    const xi = 0;
    final yi = 128 * r;

    _arraycopy(B, bi, xy, xi, 128 * r);

    for (var i = 0; i < N; i++) {
      _arraycopy(xy, xi, V, i * (128 * r), 128 * r);
      _blockmixSalsa8(xy, xi, yi, r);
    }

    for (var i = 0; i < N; i++) {
      var j = _integerify(xy, xi, r) & (N - 1);
      _blockxor(V, j * (128 * r), xy, xi, 128 * r);
      _blockmixSalsa8(xy, xi, yi, r);
    }

    _arraycopy(xy, xi, B, bi, 128 * r);
  }

  final _b32 = List<int>.filled(16, 0);
  final _x = List<int>.filled(16, 0);

  void _blockmixSalsa8(Uint8List by, int bi, int yi, int r) {
    final byByteData = by.buffer.asByteData(by.offsetInBytes, by.length);

    for (var i = 0; i < 16; ++i) {
      _b32[i] =
          byByteData.getUint32(bi + (2 * r - 1) * 64 + i * 4, Endian.little);
    }

    for (var i = 0; i < 2 * r; i++) {
      for (var j = 0; j < 16; ++j) {
        _b32[j] ^= byByteData.getUint32(i * 64 + j * 4, Endian.little);
        _x[j] = _b32[j];
      }
      _salsa20_8();
      for (var j = 0; j < 16; ++j) {
        byByteData.setUint32(yi + (i * 64) + j * 4, _b32[j], Endian.little);
      }
    }

    for (var i = 0; i < r; i++) {
      _arraycopy(by, yi + (i * 2) * 64, by, bi + (i * 64), 64);
    }

    for (var i = 0; i < r; i++) {
      _arraycopy(by, yi + (i * 2 + 1) * 64, by, bi + (i + r) * 64, 64);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _R(int sum, int n) =>
      ((sum << n) & 0xFFFFFFFF) | (sum & 0xFFFFFFFF) >> (32 - n);

  void _salsa20_8() {
    for (var i = 8; i > 0; i -= 2) {
      _x[4] ^= _R(_x[0] + _x[12], 7);
      _x[8] ^= _R(_x[4] + _x[0], 9);
      _x[12] ^= _R(_x[8] + _x[4], 13);
      _x[0] ^= _R(_x[12] + _x[8], 18);
      _x[9] ^= _R(_x[5] + _x[1], 7);
      _x[13] ^= _R(_x[9] + _x[5], 9);
      _x[1] ^= _R(_x[13] + _x[9], 13);
      _x[5] ^= _R(_x[1] + _x[13], 18);
      _x[14] ^= _R(_x[10] + _x[6], 7);
      _x[2] ^= _R(_x[14] + _x[10], 9);
      _x[6] ^= _R(_x[2] + _x[14], 13);
      _x[10] ^= _R(_x[6] + _x[2], 18);
      _x[3] ^= _R(_x[15] + _x[11], 7);
      _x[7] ^= _R(_x[3] + _x[15], 9);
      _x[11] ^= _R(_x[7] + _x[3], 13);
      _x[15] ^= _R(_x[11] + _x[7], 18);
      _x[1] ^= _R(_x[0] + _x[3], 7);
      _x[2] ^= _R(_x[1] + _x[0], 9);
      _x[3] ^= _R(_x[2] + _x[1], 13);
      _x[0] ^= _R(_x[3] + _x[2], 18);
      _x[6] ^= _R(_x[5] + _x[4], 7);
      _x[7] ^= _R(_x[6] + _x[5], 9);
      _x[4] ^= _R(_x[7] + _x[6], 13);
      _x[5] ^= _R(_x[4] + _x[7], 18);
      _x[11] ^= _R(_x[10] + _x[9], 7);
      _x[8] ^= _R(_x[11] + _x[10], 9);
      _x[9] ^= _R(_x[8] + _x[11], 13);
      _x[10] ^= _R(_x[9] + _x[8], 18);
      _x[12] ^= _R(_x[15] + _x[14], 7);
      _x[13] ^= _R(_x[12] + _x[15], 9);
      _x[14] ^= _R(_x[13] + _x[12], 13);
      _x[15] ^= _R(_x[14] + _x[13], 18);
    }

    for (var i = 0; i < 16; i++) {
      _b32[i] = (_x[i] + _b32[i]) & 0xFFFFFFFF;
    }
  }

  void _blockxor(Uint8List s, int si, Uint8List d, int di, int len) {
    for (var i = 0; i < len; i++) {
      d[di + i] ^= s[si + i];
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _integerify(Uint8List b, int bi, int r) {
    return b.buffer
        .asByteData(b.offsetInBytes, b.length)
        .getUint32(bi + (2 * r - 1) * 64, Endian.little);
  }

  void _arraycopy(
          List<int> inp, int inpOff, List<int> out, int outOff, int len) =>
      out.setRange(outOff, outOff + len, inp, inpOff);
}

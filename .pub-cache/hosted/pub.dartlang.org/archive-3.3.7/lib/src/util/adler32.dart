import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

/// Get the Adler-32 checksum for the given array. You can append bytes to an
/// already computed adler checksum by specifying the previous [adler] value.
int getAdler32(List<int> array, [int adler = 1]) {
  // largest prime smaller than 65536
  const base = 65521;

  var s1 = adler & 0xffff;
  var s2 = adler >> 16;
  var len = array.length;
  var i = 0;
  while (len > 0) {
    var n = 3800;
    if (n > len) {
      n = len;
    }
    len -= n;
    while (--n >= 0) {
      s1 = s1 + (array[i++] & 0xff);
      s2 = s2 + s1;
    }
    s1 %= base;
    s2 %= base;
  }

  return (s2 << 16) | s1;
}

/// A class to compute Adler-32 checksums.
class Adler32 extends crypto.Hash {
  int _hash = 1;

  /// Get the value of the hash directly. This returns the same value as [close].
  int get hash => _hash;

  @override
  int get blockSize => 4;

  Adler32();

  Adler32 newInstance() => Adler32();

  @override
  ByteConversionSink startChunkedConversion(Sink<crypto.Digest> sink) =>
      _Adler32Sink(sink);

  void add(List<int> data) {
    _hash = getAdler32(data, _hash);
  }

  List<int> close() {
    return [
      ((_hash >> 24) & 0xFF),
      ((_hash >> 16) & 0xFF),
      ((_hash >> 8) & 0xFF),
      (_hash & 0xFF)
    ];
  }
}

/// A [ByteConversionSink] that computes Adler-32 checksums.
class _Adler32Sink extends ByteConversionSinkBase {
  final Sink<crypto.Digest> _inner;

  var _hash = 1;

  /// Whether [close] has been called.
  var _isClosed = false;

  _Adler32Sink(this._inner);

  @override
  void add(List<int> data) {
    if (_isClosed) throw StateError('Hash.add() called after close().');
    _hash = getAdler32(data, _hash);
  }

  @override
  void close() {
    if (_isClosed) return;
    _isClosed = true;

    _inner.add(crypto.Digest([
      ((_hash >> 24) & 0xFF),
      ((_hash >> 16) & 0xFF),
      ((_hash >> 8) & 0xFF),
      (_hash & 0xFF)
    ]));
  }
}

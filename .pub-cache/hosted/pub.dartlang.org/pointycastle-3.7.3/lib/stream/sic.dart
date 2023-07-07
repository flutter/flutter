// See file LICENSE for more information.

library impl.stream_cipher.sic;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_stream_cipher.dart';
import 'package:pointycastle/src/ufixnum.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Implementation of SIC mode of operation as a [StreamCipher]. This implementation uses the IV as the initial nonce value and
/// keeps incrementing it by 1 for every block. The counter may overflow and rotate, and that would cause a two-time-pad
/// error, but this is so unlikely to happen for usual block sizes that we don't check for that event. It is the responsibility
/// of the caller to make sure the counter does not overflow.
class SICStreamCipher extends BaseStreamCipher {
  /// Intended for internal use.
  // ignore: non_constant_identifier_names
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      StreamCipher,
      '/SIC',
      (_, final Match match) => () {
            var digestName = match.group(1);
            return SICStreamCipher(BlockCipher(digestName!));
          });

  final BlockCipher underlyingCipher;

  late Uint8List _iv;
  late Uint8List _counter;
  late Uint8List _counterOut;
  late int _consumed;

  SICStreamCipher(this.underlyingCipher) {
    _iv = Uint8List(underlyingCipher.blockSize);
    _counter = Uint8List(underlyingCipher.blockSize);
    _counterOut = Uint8List(underlyingCipher.blockSize);
  }

  @override
  String get algorithmName => '${underlyingCipher.algorithmName}/SIC';

  @override
  void reset() {
    underlyingCipher.reset();
    _counter.setAll(0, _iv);
    _counterOut.fillRange(0, _counterOut.length, 0);
    _consumed = _counterOut.length;
  }

  @override
  void init(bool forEncryption, covariant ParametersWithIV params) {
    _iv.setAll(0, params.iv);
    reset();
    underlyingCipher.init(true, params.parameters);
  }

  @override
  void processBytes(
      Uint8List? inp, int inpOff, int len, Uint8List? out, int outOff) {
    for (var i = 0; i < len; i++) {
      out![outOff + i] = returnByte(inp![inpOff + i]);
    }
  }

  @override
  int returnByte(int inp) {
    _feedCounterIfNeeded();
    return clip8(inp) ^ _counterOut[_consumed++];
  }

  /// Calls [_feedCounter] if all [_counterOut] bytes have been consumed
  void _feedCounterIfNeeded() {
    if (_consumed >= _counterOut.length) {
      _feedCounter();
    }
  }

  // ignore: slash_for_doc_comments
  /// Fills [_counterOut] with a value got from encrypting [_counter] with
  /// the _underlyingCipher, resets [_consumed] to 0 and increments the
  /// [_counter].
  void _feedCounter() {
    underlyingCipher.processBlock(_counter, 0, _counterOut, 0);
    _incrementCounter();
    _consumed = 0;
  }

  /// Increments [_counter] by 1
  void _incrementCounter() {
    int i;
    for (i = _counter.lengthInBytes - 1; i >= 0; i--) {
      var val = _counter[i];
      val++;
      _counter[i] = val;
      if (_counter[i] != 0) break;
    }
  }
}

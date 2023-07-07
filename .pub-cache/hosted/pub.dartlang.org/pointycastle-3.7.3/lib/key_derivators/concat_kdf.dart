import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/src/impl/base_key_derivator.dart';
import 'package:pointycastle/src/registry/registry.dart';

class ConcatKDFDerivator extends BaseKeyDerivator {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig =
      DynamicFactoryConfig.suffix(KeyDerivator, '/ConcatKDF', (_, Match match) {
    final digestName = match.group(1);
    final digest = Digest(digestName!);
    return () {
      return ConcatKDFDerivator(digest);
    };
  });

  final Digest _digest;
  late final HkdfParameters _parameters;

  ConcatKDFDerivator(this._digest);

  @override
  String get algorithmName => '${_digest.algorithmName}/ConcatKDF';

  @override
  int deriveKey(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    _digest.reset();

    var reps = _getReps(_parameters.desiredKeyLength, _digest.digestSize * 8);
    var output = Uint8List(reps * _digest.digestSize);
    var counter = Uint8List(4);
    for (var i = 1; i <= reps; i++) {
      var counterInt = i.toUnsigned(32);
      counter[0] = (counterInt >> 24) & 255;
      counter[1] = (counterInt >> 16) & 255;
      counter[2] = (counterInt >> 8) & 255;
      counter[3] = (counterInt) & 255;
      _digest.update(counter, 0, 4);
      _digest.update(_parameters.ikm, 0, _parameters.ikm.length);
      _digest.update(_parameters.salt ?? inp.sublist(inpOff), 0,
          _parameters.salt?.length ?? inp.sublist(inpOff).length);
      _digest.doFinal(output, (i - 1) * _digest.digestSize);
    }

    out.setAll(outOff, output.getRange(0, keySize));
    return keySize;
  }

  int _getReps(int keydatalen, int messagedigestlen) {
    return (keydatalen / messagedigestlen).ceil();
  }

  @override
  void init(covariant HkdfParameters params) {
    _parameters = params;
  }

  @override
  int get keySize => (_parameters.desiredKeyLength / 8).ceil();
}

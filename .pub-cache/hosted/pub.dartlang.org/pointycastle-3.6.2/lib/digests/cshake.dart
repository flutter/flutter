// This file has been migrated.

library impl.digest.cshake;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/shake.dart';
import 'package:pointycastle/digests/xof_utils.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/utils.dart';

///
/// implementation of SHAKE based on following KeccakNISTInterface.c from http://keccak.noekeon.org/
///
/// Following the naming conventions used in the C source code to enable easy review of the implementation.
///
class CSHAKEDigest extends SHAKEDigest implements Xof {
  static final RegExp _cshakeREGEX = RegExp(r'^CSHAKE-([0-9]+)$');

  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig(
      Digest,
      _cshakeREGEX,
      (_, final Match match) => () {
            var bitLength = int.parse(match.group(1)!);
            return CSHAKEDigest(bitLength);
          });

  Uint8List? _diff;
  final _padding = Uint8List(100);

  CSHAKEDigest([int bitLength = 256, Uint8List? N, Uint8List? S]) {
    switch (bitLength) {
      case 128:
      case 256:
        init(bitLength);
        if ((N == null || N.isEmpty) && (S == null || S.isEmpty)) {
          _diff = null;
        } else {
          _diff = concatUint8List([
            XofUtils.leftEncode(rate ~/ 8),
            _encodeString(N),
            _encodeString(S)
          ]);
          _diffPadAndAbsorb();
        }

        break;
      default:
        throw StateError(
            'invalid bitLength ($bitLength) for CSHAKE must only be 128 or 256');
    }
  }

  @override
  String get algorithmName => 'CSHAKE-$fixedOutputLength';
  @override
  int doOutput(Uint8List out, int outOff, int outLen) {
    if (_diff != null) {
      if (!squeezing) {
        absorbBits(0x00, 2);
      }

      squeeze(out, outOff, (outLen) * 8);

      return outLen;
    } else {
      return super.doOutput(out, outOff, outLen);
    }
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    absorbRange(inp, inpOff, len);
  }

  @override
  void reset() {
    super.reset();

    if (_diff != null) {
      _diffPadAndAbsorb();
    }
  }

  // bytepad in SP 800-185
  void _diffPadAndAbsorb() {
    var blockSize = rate ~/ 8;
    absorbRange(_diff!, 0, _diff!.length);

    var delta = _diff!.length % blockSize;

    // only add padding if needed
    if (delta != 0) {
      var required = blockSize - delta;

      while (required > _padding.length) {
        absorbRange(_padding, 0, _padding.length);
        required -= _padding.length;
      }

      absorbRange(_padding, 0, required);
    }
  }

  Uint8List _encodeString(Uint8List? str) {
    if (str == null || str.isEmpty) {
      return XofUtils.leftEncode(0);
    }

    return concatUint8List([XofUtils.leftEncode(str.length * 8), str]);
  }
}

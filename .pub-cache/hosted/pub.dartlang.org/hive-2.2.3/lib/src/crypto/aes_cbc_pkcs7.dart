import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';

/// AES CBC implementation with PKCS7 padding
class AesCbcPkcs7 {
  static final _lastInputBlockBuffer = Uint8List(16);

  final Uint8List _keyBytes;

  late final List<Uint32List> _encryptionKey =
      AesEngine.generateWorkingKey(_keyBytes, true);
  late final List<Uint32List> _decryptionKey =
      AesEngine.generateWorkingKey(_keyBytes, false);

  /// Not part of public API
  AesCbcPkcs7(this._keyBytes);

  /// Not part of public API
  int encrypt(Uint8List iv, Uint8List inp, int inpOff, int inpLength,
      Uint8List out, int outOff) {
    var cbcV = Uint8List.fromList(iv);

    var inputBlocks = (inpLength + aesBlockSize) ~/ aesBlockSize;
    var remaining = inpLength % aesBlockSize;

    var offset = 0;
    for (var i = 0; i < inputBlocks - 1; i++) {
      // XOR the cbcV and the input, then encrypt the cbcV
      for (var i = 0; i < aesBlockSize; i++) {
        cbcV[i] ^= inp[inpOff + offset + i];
      }

      AesEngine.encryptBlock(_encryptionKey, cbcV, 0, out, outOff + offset);

      // copy ciphertext to cbcV
      cbcV.setRange(0, aesBlockSize, out, outOff + offset);
      offset += aesBlockSize;
    }

    var lastInputBlock = _lastInputBlockBuffer;
    lastInputBlock.setRange(0, remaining, inp, inpOff + offset);
    lastInputBlock.fillRange(remaining, aesBlockSize, aesBlockSize - remaining);

    for (var i = 0; i < aesBlockSize; i++) {
      cbcV[i] ^= lastInputBlock[i];
    }
    AesEngine.encryptBlock(_encryptionKey, cbcV, 0, out, outOff + offset);

    return offset + aesBlockSize;
  }

  /// Not part of public API
  int decrypt(Uint8List iv, Uint8List inp, int inpOff, int inpLength,
      Uint8List out, int outOff) {
    var inputBlocks = (inpLength + aesBlockSize - 1) ~/ aesBlockSize;

    var offset = 0;

    AesEngine.decryptBlock(_decryptionKey, inp, inpOff, out, outOff);
    for (var i = 0; i < aesBlockSize; i++) {
      out[outOff + i] ^= iv[i];
    }
    offset += aesBlockSize;

    for (var i = 0; i < inputBlocks - 1; i++) {
      AesEngine.decryptBlock(
          _decryptionKey, inp, inpOff + offset, out, outOff + offset);
      for (var i = 0; i < aesBlockSize; i++) {
        out[outOff + offset + i] ^= inp[inpOff - aesBlockSize + offset + i];
      }
      offset += aesBlockSize;
    }

    var lastDecryptedByte = out[outOff + offset - 1];
    if (lastDecryptedByte > aesBlockSize) {
      throw ArgumentError('Invalid or corrupted pad block');
    }
    for (var i = 0; i < lastDecryptedByte; i++) {
      if (out[outOff + offset - i - 1] != lastDecryptedByte) {
        throw ArgumentError('Invalid or corrupted pad block');
      }
    }

    return offset - lastDecryptedByte;
  }
}

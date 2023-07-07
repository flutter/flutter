// See file LICENSE for more information.

library impl.padded_block_cipher.padded_block_cipher_impl;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// The standard implementation of [PaddedBlockCipher].
class PaddedBlockCipherImpl implements PaddedBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
      PaddedBlockCipher,
      r'^(.+)/([^/]+)$',
      (_, final Match match) => () {
            var padding = Padding(match.group(2)!);
            var underlyingCipher = BlockCipher(match.group(1)!);
            return PaddedBlockCipherImpl(padding, underlyingCipher);
          });

  @override
  final Padding padding;
  @override
  final BlockCipher cipher;

  bool? _encrypting;

  PaddedBlockCipherImpl(this.padding, this.cipher);

  @override
  String get algorithmName =>
      cipher.algorithmName + '/' + padding.algorithmName;

  @override
  int get blockSize => cipher.blockSize;

  @override
  void reset() {
    _encrypting = null;
    cipher.reset();
  }

  @override
  void init(bool forEncryption, covariant PaddedBlockCipherParameters params) {
    _encrypting = forEncryption;
    cipher.init(forEncryption, params.underlyingCipherParameters);
    padding.init(params.paddingCipherParameters);
  }

  @override
  Uint8List process(Uint8List? data) {
    var inputBlocks = (data!.length + blockSize - 1) ~/ blockSize;

    int outputBlocks;
    if (_encrypting!) {
      outputBlocks = (data.length + blockSize) ~/ blockSize;
    } else {
      if ((data.length % blockSize) != 0) {
        throw ArgumentError(
            'Input data length must be a multiple of cipher\'s block size');
      }
      outputBlocks = inputBlocks;
    }

    var out = Uint8List(outputBlocks * blockSize);

    for (var i = 0; i < (inputBlocks - 1); i++) {
      var offset = (i * blockSize);
      processBlock(data, offset, out, offset);
    }

    var lastBlockOffset = ((inputBlocks - 1) * blockSize);
    var lastBlockSize = doFinal(data, lastBlockOffset, out, lastBlockOffset);

    return out.sublist(0, lastBlockOffset + lastBlockSize);
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    return cipher.processBlock(inp, inpOff, out, outOff);
  }

  @override
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if (_encrypting!) {
      var lastInputBlock = Uint8List(blockSize)..setAll(0, inp.sublist(inpOff));

      var remainder = inp.length - inpOff;

      if (remainder < blockSize) {
        // Padding goes embedded in last block of data
        padding.addPadding(lastInputBlock, (inp.length - inpOff));

        processBlock(lastInputBlock, 0, out, outOff);

        return blockSize;
      } else {
        // Padding goes alone in an additional block
        processBlock(inp, inpOff, out, outOff);

        padding.addPadding(lastInputBlock, 0);

        processBlock(lastInputBlock, 0, out, outOff + blockSize);

        return 2 * blockSize;
      }
    } else {
      // Decrypt last block and remove padding
      processBlock(inp, inpOff, out, outOff);

      var padCount = padding.padCount(out.sublist(outOff));

      var padOffsetInBlock = blockSize - padCount;

      out.fillRange(outOff + padOffsetInBlock, out.length, 0);

      return padOffsetInBlock;
    }
  }
}

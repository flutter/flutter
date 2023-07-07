library impl.block_cipher.modes.ccm;

import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/ufixnum.dart';
import 'package:pointycastle/src/utils.dart';

import '../../src/impl/base_aead_block_cipher.dart';
import '../../src/registry/registry.dart';

/// Implementation of the CCM block cipher mode. CCM is authenticated, meaning
/// that you can pass AEAD data (and that appending a MAC of the ciphertext is
/// unnecessary).
class CCMBlockCipher extends BaseAEADBlockCipher {
  late Uint8List _macBlock;
  @override
  late Uint8List nonce;

  @override
  Uint8List? aad;

  @override
  late int macSize;

  late KeyParameter _keyParam;

  var associatedText = BytesBuilder();
  var data = BytesBuilder();

  late bool _forEncryption;

  // ignore: non_constant_identifier_names
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      BlockCipher,
      '/CCM',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            return CCMBlockCipher(underlying);
          });

  CCMBlockCipher(BlockCipher underlyingCipher) : super(underlyingCipher) {
    _macBlock = Uint8List(blockSize);
    if (blockSize != 16) {
      throw ArgumentError('CCM requires a block size of 16');
    }
  }

  @override
  void reset() {
    underlyingCipher.reset();
    associatedText.clear();
    data.clear();
  }

  @override
  void init(forEncryption, covariant CipherParameters params) {
    _forEncryption = forEncryption;
    KeyParameter key;

    if (params is AEADParameters) {
      nonce = params.nonce;
      aad = params.associatedData;
      macSize = _getMacSize(forEncryption, params.macSize);
      key = params.parameters as KeyParameter;
    } else if (params is ParametersWithIV<KeyParameter>) {
      nonce = params.iv;
      aad = null;
      macSize = _getMacSize(forEncryption, 64);
      key = params.parameters!;
    } else {
      throw ArgumentError('Invalid parameter class');
    }

    if (nonce.length < 7 || nonce.length > 13) {
      throw ArgumentError('nonce must have length from 7 to 13 octets');
    }

    _keyParam = key;

    reset();
  }

  @override
  String get algorithmName => '${underlyingCipher.algorithmName}/CCM';

  @override
  int processBytes(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff) {
    data.write(inp, inpOff, len);
    return 0;
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    var len = _processPacket(data.toBytes(), 0, data.length, out, outOff);

    reset();

    return len;
  }

  @override
  void processAADBytes(Uint8List inp, int inpOff, int len) {
    associatedText.write(inp, inpOff, len);
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) =>
      processBytes(inp, inpOff, inp.length, out, outOff);

  int _processPacket(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff) {
    var n = nonce.length;
    var q = 15 - n;
    if (q < 4) {
      var limitLen = 1 << (8 * q);
      if (len >= limitLen) {
        throw StateError('CCM packet too large for choice of q.');
      }
    }

    var iv = Uint8List(blockSize);
    iv[0] = ((q - 1) & 0x7);
    arrayCopy(nonce, 0, iv, 1, nonce.length);

    BlockCipher ctrCipher =
        SICBlockCipher(blockSize, SICStreamCipher(underlyingCipher));
    ctrCipher.init(
        forEncryption, ParametersWithIV<KeyParameter>(_keyParam, iv));

    int outputLen;
    var inIndex = inpOff;
    var outIndex = outOff;

    if (forEncryption) {
      outputLen = len + macSize;
      if (out.length < (outputLen + outOff)) {
        throw ArgumentError('Output buffer too short.');
      }

      _calculateMac(inp, inpOff, len, _macBlock);

      var encMac = Uint8List(blockSize);

      ctrCipher.processBlock(_macBlock, 0, encMac, 0); // S0

      while (inIndex < (inpOff + len - blockSize)) // S1...
      {
        ctrCipher.processBlock(inp, inIndex, out, outIndex);
        outIndex += blockSize;
        inIndex += blockSize;
      }

      var block = Uint8List(blockSize);

      arrayCopy(inp, inIndex, block, 0, len + inpOff - inIndex);

      ctrCipher.processBlock(block, 0, block, 0);

      arrayCopy(block, 0, out, outIndex, len + inpOff - inIndex);

      arrayCopy(encMac, 0, out, outOff + len, macSize);
    } else {
      if (len < macSize) {
        throw InvalidCipherTextException('data too short');
      }
      outputLen = len - macSize;
      if (out.length < (outputLen + outOff)) {
        throw ArgumentError('Output buffer too short.');
      }

      arrayCopy(inp, inpOff + outputLen, _macBlock, 0, macSize);

      ctrCipher.processBlock(_macBlock, 0, _macBlock, 0);

      for (var i = macSize; i != _macBlock.length; i++) {
        _macBlock[i] = 0;
      }

      while (inIndex < (inpOff + outputLen - blockSize)) {
        ctrCipher.processBlock(inp, inIndex, out, outIndex);
        outIndex += blockSize;
        inIndex += blockSize;
      }

      var block = Uint8List(blockSize);

      arrayCopy(inp, inIndex, block, 0, outputLen - (inIndex - inpOff));

      ctrCipher.processBlock(block, 0, block, 0);

      arrayCopy(block, 0, out, outIndex, outputLen - (inIndex - inpOff));

      var calculatedMacBlock = Uint8List(blockSize);

      _calculateMac(out, outOff, outputLen, calculatedMacBlock);

      if (!(_macBlock.length == calculatedMacBlock.length)) {
        throw StateError('mac check in CCM failed');
      } else {
        for (var i = 0; i < _macBlock.length; i++) {
          if (_macBlock[i] != calculatedMacBlock[i]) {
            throw StateError('mac check in CCM failed');
          }
        }
      }
    }

    return outputLen;
  }

  int _calculateMac(
      Uint8List data, int dataOff, int dataLen, Uint8List macBlock) {
    Mac cMac = CBCBlockCipherMac(underlyingCipher, macSize * 8, null);

    cMac.init(ParametersWithIV<KeyParameter>(_keyParam, Uint8List(blockSize)));

    //
    // build b0
    //
    var b0 = Uint8List(16);

    if (_hasAssociatedText()) {
      b0[0] |= 0x40;
    }

    b0[0] |= (((cMac.macSize - 2) ~/ 2) & 0x7) << 3;

    b0[0] |= ((15 - nonce.length) - 1) & 0x7;

    arrayCopy(nonce, 0, b0, 1, nonce.length);

    var q = dataLen;
    var count = 1;
    while (q > 0) {
      b0[b0.length - count] = (q & 0xff);
      q = cshiftr32(q, 8);
      count++;
    }

    cMac.update(b0, 0, b0.length);

    //
    // process associated text
    //
    if (_hasAssociatedText()) {
      int extra;

      var textLength = _getAssociatedTextLength();
      if (textLength < ((1 << 16) - (1 << 8))) {
        cMac.updateByte((textLength >> 8));
        cMac.updateByte(textLength);

        extra = 2;
      } else {
        cMac.updateByte(0xff);
        cMac.updateByte(0xfe);
        cMac.updateByte((textLength >> 24));
        cMac.updateByte((textLength >> 16));
        cMac.updateByte((textLength >> 8));
        cMac.updateByte(textLength);

        extra = 6;
      }

      if (aad != null) {
        cMac.update(aad!, 0, aad!.length);
      }
      if (associatedText.length > 0) {
        cMac.update(associatedText.toBytes(), 0, associatedText.length);
      }

      extra = (extra + textLength) % 16;
      if (extra != 0) {
        for (var i = extra; i != 16; i++) {
          cMac.updateByte(0x00);
        }
      }
    }

    //
    // add the text
    //
    cMac.update(data, dataOff, dataLen);

    return cMac.doFinal(macBlock, 0);
  }

  int _getMacSize(bool forEncryption, int requestedMacBits) {
    if (forEncryption &&
        (requestedMacBits < 32 ||
            requestedMacBits > 128 ||
            0 != (requestedMacBits & 15))) {
      throw ArgumentError(
          'tag length in octets must be one of {4,6,8,10,12,14,16}');
    }

    return cshiftr32(requestedMacBits, 3);
  }

  @override
  Uint8List get mac {
    var out = Uint8List(macSize);
    arrayCopy(_macBlock, 0, out, 0, out.length);
    return out;
  }

  @override
  bool get forEncryption => _forEncryption;

  @override
  void prepare(KeyParameter keyParam) {
    // Unused artifact of class hierarchy.
  }

  @override
  int getOutputSize(int len) {
    var totalData = len + data.length;

    if (forEncryption) {
      return totalData + macSize;
    }

    return totalData < macSize ? 0 : totalData - macSize;
  }

  int _getAssociatedTextLength() {
    return associatedText.length + ((aad == null) ? 0 : aad!.length);
  }

  bool _hasAssociatedText() {
    return _getAssociatedTextLength() > 0;
  }

  @override
  Uint8List get remainingInput => data.toBytes();
}

extension WriteLen on BytesBuilder {
  void write(Uint8List b, int off, int len) {
    add(b.sublist(off, off + len));
  }
}

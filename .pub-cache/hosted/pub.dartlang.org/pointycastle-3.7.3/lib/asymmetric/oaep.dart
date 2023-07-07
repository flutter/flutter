// See file LICENSE for more information.

library impl.asymmetric_block_cipher.oeap;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/src/impl/base_asymmetric_block_cipher.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:pointycastle/src/registry/registry.dart';

typedef DigestFactory = Digest Function();

/// RSAES-OAEP v2.0
///
/// This implementation is based on the RSAES-OAEP (RSA Encryption Scheme -
/// Optimal Asymmetric Encryption Padding) as specified in section 7.1 of
/// [RFC 2437](https://tools.ietf.org/html/rfc2437#section-7.1)
/// _PKCS #1: RSA Cryptography Specifications Version 2.0_.
///
/// **Important:** this is **not** compatible with RSAES-OAEP v2.1 or later (as
/// specified in RFC 3447, RFC 8017, etc.) Those newer versions have an extra
/// 0x00 byte at the beginning of the encoded message (EM) that is passed
/// to the RSA encryption primitive. Therefore, this implementation is
/// incompatible with it, since this is an implementation of v2.0 which does
/// not have that 0x00 byte. A breaking change in the standard!
///
/// Currently, this implementation has the following restrictions:
///
/// - the hash function is hard-coded to be SHA-1 or SHA-256;
/// - the mask generation function is hard-coded to MGF1; and
/// - it cannot accept any _encoding parameters_ (that is, _P_ is always empty)

class OAEPEncoding extends BaseAsymmetricBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      AsymmetricBlockCipher,
      '/OAEP',
      (_, final Match match) => () {
            var underlyingCipher = AsymmetricBlockCipher(match.group(1)!);
            return OAEPEncoding(underlyingCipher);
          });

  /// Hash function used by the EME-OAEP (Encoding Method for Encryption OAEP).
  Digest hash;

  /// Hash function used by the MGF1 Mask Generation Function.
  late Digest mgf1Hash;

  /// Default hash of the encoding parameters,
  /// all zero octets
  Uint8List defHash;

  /// The encoding params, or P, as specified in
  /// [RFC 2437](https://tools.ietf.org/html/rfc2437#section-7.1.1)
  Uint8List? encodingParams;

  final AsymmetricBlockCipher _engine;
  late SecureRandom _random;
  late bool _forEncryption;

  OAEPEncoding._(DigestFactory digestFactory, this._engine,
      [this.encodingParams])
      : hash = digestFactory(),
        defHash = Uint8List(digestFactory().digestSize) {
    digestFactory().doFinal(defHash, 0);
  }

  factory OAEPEncoding(AsymmetricBlockCipher engine,
          [Uint8List? encodingParams]) =>
      OAEPEncoding.withSHA1(engine, encodingParams);

  factory OAEPEncoding.withSHA1(AsymmetricBlockCipher engine,
          [Uint8List? encodingParams]) =>
      OAEPEncoding._(() => SHA1Digest(), engine, encodingParams);

  factory OAEPEncoding.withSHA256(AsymmetricBlockCipher engine,
          [Uint8List? encodingParams]) =>
      OAEPEncoding._(() => SHA256Digest(), engine, encodingParams);

  factory OAEPEncoding.withCustomDigest(
          DigestFactory digestFactory, AsymmetricBlockCipher engine,
          [Uint8List? encodingParams]) =>
      OAEPEncoding._(digestFactory, engine, encodingParams);

  @override
  String get algorithmName => '${_engine.algorithmName}/OAEP';

  @override
  void reset() {}

  Uint8List _seed() {
    var seed = Platform.instance.platformEntropySource().getBytes(32);
    return seed;
  }

  // for compat cleaner translation from java source
  Uint8List _arraycopy(
      Uint8List src, int srcPos, Uint8List dest, int destPos, int length) {
    dest.setRange(
        destPos, destPos + length, src.sublist(srcPos, srcPos + length));
    return dest;
  }

  @override
  void init(bool forEncryption, CipherParameters params) {
    AsymmetricKeyParameter akparams;
    mgf1Hash = hash;
    if (params is ParametersWithRandom) {
      var paramswr = params;
      _random = paramswr.random;
      akparams = paramswr.parameters as AsymmetricKeyParameter<AsymmetricKey>;
    } else {
      _random = FortunaRandom();
      _random.seed(KeyParameter(_seed()));
      akparams = params as AsymmetricKeyParameter<AsymmetricKey>;
    }
    _engine.init(forEncryption, akparams);
    _forEncryption = forEncryption;

    // Check type of key provided is suitable
    // Note: the _engine can't do this check, because the engine could be used
    // for both encryption/decryption and signature/verification (which reverses
    // the keys), so its `init` method accepts both types of keys. For example,
    // [RSAEngine.init].

    if (forEncryption) {
      if (akparams.key is! PublicKey) {
        throw ArgumentError.value(
            'OAEP encryption needs PublicKey: not ${akparams.key.runtimeType}');
      }
    } else {
      if (akparams.key is! PrivateKey) {
        throw ArgumentError.value(
            'OAEP decryption needs PrivateKey: not ${akparams.key.runtimeType}');
      }
    }
  }

  @override
  int get inputBlockSize {
    var baseBlockSize = _engine.inputBlockSize;
    if (_forEncryption) {
      return baseBlockSize - 1 - 2 * defHash.length;
    } else {
      return baseBlockSize;
    }
  }

  @override
  int get outputBlockSize {
    var baseBlockSize = _engine.outputBlockSize;
    if (_forEncryption) {
      return baseBlockSize;
    } else {
      return baseBlockSize - 1 - (2 * defHash.length);
    }
  }

  @override
  int processBlock(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff) {
    if (_forEncryption) {
      return _encodeBlock(inp, inpOff, len, out, outOff);
    } else {
      return _decodeBlock(inp, inpOff, len, out, outOff);
    }
  }

  /// RSAES-OAEP encryption operation
  ///
  /// Implements the _RSA Encryption Scheme with Optimal Asymmetric Encryption
  /// Padding_ (RSAES-OAEP) **encryption operation**. This encryption operation
  /// combines the _Encoding Method for Encryption OAEP_ (EME-OAEP)
  /// **encoding operation** with the _RSA Encryption Primitive_ (RSAEP).
  ///
  /// This method performs the EME-OAEP encoding operation, and then invokes its
  /// [AsymmetricBlockCipher] engine to perform RSAEP to encrypt it.
  ///
  /// The RSAES-OAEP encryption operation is specified in section 7.1.1 of
  /// [RFC 2437](https://tools.ietf.org/html/rfc2437#section-7.1.1) and the
  /// EME-OAEP encoding operation it uses is specified in section 9.1.1.1 of
  /// [RFC 2437](https://tools.ietf.org/html/rfc2437#section-9.1.1.1).
  ///
  /// The message to be encoded and encrypted is the octet string consisting of
  /// [inpLen] bytes from [inp], starting at the [inpOff] offset.
  ///
  /// It returns the ciphertext.

  int _encodeBlock(
      Uint8List inp, int inpOff, int inpLen, Uint8List out, int outOff) {
    if (inpLen > inputBlockSize) {
      throw ArgumentError('message too long');
    }

    // The numbered steps below correspond to the steps in RFC 2437.
    // Names in _italics_ refers to names in the RFC 2437 and names in square
    // brackets refers to variables in this code.

    // 3. Generate PS (padding string containing just zero octets)
    //
    // In this implementation, the length of PS is always zero. That is, there
    // is no bytes in _PS_.

    // 4. Calculate _pHash_ = Hash(P)
    //
    // The result _pHash_ is stored into [pHash].
    //
    // Note: If no encodingParams are set
    // the [defHash] is used as is (which was initialized to be a hash of no
    // bytes)
    var pHash =
        encodingParams != null ? hash.process(encodingParams!) : defHash;

    // 5. Calculate _DB_ = pHash || PS || 01 || M
    //
    // It is the concatenation of _pHash_, _PS_, 0x01 and the message.
    // Note: RFC 2437 also includes 'other padding', but that is an error that
    // does not appear in subsequent versions of PKCS #1 (e.g. RFC 3447).
    //
    // The result _DB_ is stored into [block] starting at offset _hLen_ to the
    // end.

    var block = Uint8List(inputBlockSize + 1 + 2 * pHash.length);

    // M: copy the message into the end of the block.
    //
    // block.setRange(inpOff, block.length - inpLen, inp.sublist(inpLen));
    block = _arraycopy(inp, inpOff, block, block.length - inpLen, inpLen);

    // 01: add the sentinel byte
    //
    block[block.length - inpLen - 1] = 0x01;

    // PS: since a Uint8List is initialized with 0x00, PS is already zeroed

    // pHash: add the hash of the encoding params.
    //
    block = _arraycopy(pHash, 0, block, pHash.length, pHash.length);

    // 6. Generate a random octet string _seed_ of length _hLen_.
    //
    // The _seed_ is stored in [seed].

    var seed = _random.nextBytes(pHash.length);

    // 7. Calculate _dbMask_ = MGF(seed, emLen - hLen)
    //
    // The _seed_ comes from [seed]. The result _dbMask_ is stored into [mask].

    var mask = _maskGeneratorFunction1(
        seed, 0, seed.length, block.length - pHash.length);

    // 8. Calculate _maskedDB_ = DB XOR dbMask
    //
    // The _DB_ comes from [block], starting at offset _hLen_ to the end. The
    // _dbMask_ comes from [mask]. The result _maskedDB_ is stored into [block]
    // starting at offset _hLen_ to the end (overwriting the _DB_).

    for (var i = pHash.length; i != block.length; i++) {
      block[i] ^= mask[i - pHash.length];
    }

    // Temporally store the _seed_ in the first _hLen_ bytes of the [block]
    // so it can be used later.

    block = _arraycopy(seed, 0, block, 0, pHash.length);

    // 9. Calculate _seedMask_ = MGF(maskedDB, hLen)
    //
    // The _maskedDB_ comes from [block], starting at offset _hLen_ to the end.
    // The result _seedMask_ is stored into [mask] (replacing the _dbMask_ which
    // is no longer needed).

    mask = _maskGeneratorFunction1(
        block, pHash.length, block.length - pHash.length, pHash.length);

    // 10. Calculate _maskedSeed_ = seed XOR seedMask
    //
    // The _seed_ comes from [block], the first _hLen_ bytes (where it was
    // temporally stored). The _seedMask_ comes from [mask]. The result
    // _maskedSeed_ is stored into [block], the first _hLen_ bytes (overwriting
    // the temporary _seed_).

    for (var i = 0; i != pHash.length; i++) {
      block[i] ^= mask[i];
    }

    // 11. Calculate _EM_ = maskedSeed || maskedDB
    //
    // The [block] already contains the concatenated value, since they were both
    // calculated in the first.

    // EME-OAEP-ENCODE completed.

    // Use the [_engine] to finish the RSAES-OAEP. That is, it will convert the
    // _EM_ into an integer, apply the RSA Encryption Primitive (RSAEP) to the
    // public key, and convert the resulting integer ciphertext representation
    // into octets. The octets will be written into [out] starting at [outOff].
    //
    // Returns the number of bytes in the output ciphertext.

    return _engine.processBlock(block, 0, block.length, out, outOff);
  }

  /// RSAES-OAEP decryption operation
  ///
  /// Implements the _RSA Encryption Scheme with Optimal Asymmetric Encryption
  /// Padding_ (RSAES-OAEP) **decryption operation**. This decryption operation
  /// combines the _RSA Decryption Primitive_ (RSADP) with the _Encoding Method
  /// for Encryption OAEP_ (EME-OAEP) **decoding operation**.
  ///
  /// This method invokes its [AsymmetricBlockCipher] engine to perform RSADP,
  /// and then performs the EME-OAEP decoding operation on the decrypted data.
  ///
  /// The RSAES-OAEP decryption operation is specified in section 7.1.2 of
  /// [RFC 2437](https://tools.ietf.org/html/rfc2437#section-7.1.2) and the
  /// EME-OAEP decoding operation it uses is specified in section 9.1.1.2 of
  /// [RFC 2437](https://tools.ietf.org/html/rfc2437#section-9.1.1.2).
  ///
  /// The ciphertext to be decrypted and decoded is the octet string consisting
  /// of [inpLen] bytes from [inp], starting at the [inpOff] offset.
  ///
  /// It returns the message in [out] starting at offset [outOff].

  int _decodeBlock(
      Uint8List inp, int inpOff, int inpLen, Uint8List out, int outOff) {
    // The numbered steps below correspond to the steps from section 7.1.2 of
    // [RFC 2437](https://tools.ietf.org/html/rfc2437#section-7.1.2).
    //
    // Names in _italics_ refers to names in the RFC 2437 and names in square
    // brackets refers to variables in this code.

    // 1. Length checking

    if (inpLen != _engine.inputBlockSize) {
      throw ArgumentError.value(inpLen, 'inpLen', 'decryption error');
    }

    // 2, 3. RSA decryption

    var block = Uint8List(_engine.outputBlockSize);

    var decryptFailed = false;
    try {
      var len = _engine.processBlock(inp, inpOff, inpLen, block, 0);

      // 4. EM = I2OSP(m, k-1)

      if (len < block.length) {
        // Decrypted bytes is shorter than expected. Add 0x00 bytes at the
        // beginning of the block (i.e. ensure it is k-1 long). This is needed
        // when there were 0x00 in the leading bytes of the block that was
        // originally encrypted.

        // Note: do not use [_arrayCopy] or [SetRange], since the source and
        // destination may overlap. Those methods will corrupt the data.

        // Copy [len] data bytes from beginning of block to its end. I.e. from
        // block[block.length - 1] <- block[len - 1] through to
        // block[block.len - len] <- block[0]
        for (var x = 0; x < len; x++) {
          block[block.length - 1 - x] = block[len - 1 - x];
        }
        // Put 0x00 in those beginning bytes. Important: do this AFTER copying
        block.fillRange(0, block.length - len, 0x00);
      }
    } on ArgumentError {
      decryptFailed = true;
    }

    // 5. EME-OAEP decoding
    //
    // In these 5.x numbered steps, the x refers to steps from section 9.1.1.2
    // of [RFC 2437](https://tools.ietf.org/html/rfc2437#section-9.1.1.2)

    // 5.2 Check length

    var wrongData = (block.length < (2 * defHash.length) + 1);

    // 5.4 Calculate _seedMask_ = MGF(maskedDB, hLen)
    //
    // The _maskedDB_ comes from [block] starting at _hLen_ to the end.
    // The result _seedMask_ is stored in [mask].

    var mask = _maskGeneratorFunction1(
        block, defHash.length, block.length - defHash.length, defHash.length);

    // 5.5 Calculate _seed_ = maskedSeed XOR seedMask
    //
    // THe _maskedSeed_ comes from the first _hLen_ bytes of [block] and the
    // _seedMask_ comes from [mask].
    // The result _seed_ is stored in the first _hLen_ bytes of [block]
    // (overwriting the maskedSeed_ that was previously there).

    for (var i = 0; i != defHash.length; i++) {
      block[i] ^= mask[i];
    }

    // 5.6 Calculate _dbMask_ = MGF(seed, length of EM - hLen)

    mask = _maskGeneratorFunction1(
        block, 0, defHash.length, block.length - defHash.length);

    // 5.7 Calculate _DB_ = maskedDB XOR dbMask
    //
    // The _maskedDB_ comes from [block], from _hLen_ to the end, and the
    // _dbMask_ comes from [mask]. The result _DB_ is stored in [block] from
    // _hLen_ to the end (overwriting the _maskedDB_ that was previously there).

    for (var i = defHash.length; i != block.length; i++) {
      block[i] ^= mask[i - defHash.length];
    }

    // 5.8 pHash = Hash(P)
    var pHash =
        encodingParams != null ? hash.process(encodingParams!) : defHash;

    // 5.10 Check _pHash'_ to _pHash_
    //
    // check the hash of the encoding params.
    // long check to try to avoid this been a source of a timing attack.
    //
    // The _pHash'_ comes from the first _hLen_ bytes of [block]

    var pHashWrong = false;

    for (var i = 0; i != pHash.length; i++) {
      pHashWrong |= pHash[i] != block[pHash.length + i];
    }

    // 5.9 Split _DB_ into pHash1 || PS || 0x01 || M
    //
    // Skip over the _PS_ (which are all 0x00 bytes). Finding the first non-zero
    // byte from hash.digestLength * 2 to the end of [block]. Setting [start]
    // to that first non-zero byte (or will be block.length if none found).

    var start = block.length;
    for (var index = 2 * pHash.length; index != block.length; index++) {
      if ((block[index] != 0) & (start == block.length)) {
        start = index;
      }
    }

    // The data-start-is-wrong if the rest of the [block] contains all 0x00
    // bytes or that first non-zero byte is not 0x01.

    var dataStartWrong = (start > (block.length - 1)) |
        (start < block.length && block[start] != 0x01);
    start++;

    if (decryptFailed || pHashWrong || wrongData || dataStartWrong) {
      block.fillRange(0, block.length, 0);
      throw ArgumentError('decoding error');
    }

    // 5.11 Output M
    //
    // The _M_ are all the bytes from after the 0x01 byte (i.e. offset [start])
    // to the end of [block]. Copy those bytes into [out] starting at [outOff].

    final mLen = block.length - start;
    _arraycopy(block, start, out, outOff, mLen);
    return mLen;
  }

  // ignore: slash_for_doc_comments
  /// int to octet string.
  Uint8List _itoOSP(int i, Uint8List sp) {
    sp[0] = i >> 24;
    sp[1] = i >> 16;
    sp[2] = i >> 8;
    sp[3] = i >> 0;
    return sp;
  }

  /// Implementation of MGF1 (the Mask Generation Function from PKCS #1 v2.0).
  ///
  /// See section 10.2.1 of
  /// [RFC 2437](https://tools.ietf.org/html/rfc2437#section-10.2.1).
  ///
  /// MGF1 is defined to take a hash function as an option. This implementation
  /// uses [mgf1Hash] for that hash function.
  ///
  /// MGF1 hsa two inputs: a seed and an intended length. The seed is the
  /// sequence of bytes in [Z], starting at [zOff] for [zLen] bytes.
  /// The intended length is in [length].
  ///
  /// Returns the calculated mask. A Uint8List that contains [length] bytes.

  Uint8List _maskGeneratorFunction1(
      Uint8List Z, int zOff, int zLen, int length) {
    var mask = Uint8List(length);
    var hashBuf = Uint8List(mgf1Hash.digestSize);
    var C = Uint8List(4);
    var counter = 0;
    mgf1Hash.reset();

    while (counter < (length / hashBuf.length).floor()) {
      _itoOSP(counter, C);
      mgf1Hash.update(Z, zOff, zLen);
      mgf1Hash.update(C, 0, C.length);
      mgf1Hash.doFinal(hashBuf, 0);
      mask = _arraycopy(
          hashBuf, 0, mask, counter * hashBuf.length, hashBuf.length);
      counter++;
    }

    if ((counter * hashBuf.length) < length) {
      _itoOSP(counter, C);
      mgf1Hash.update(Z, zOff, zLen);
      mgf1Hash.update(C, 0, C.length);
      mgf1Hash.doFinal(hashBuf, 0);
      mask = _arraycopy(hashBuf, 0, mask, counter * hashBuf.length,
          mask.length - (counter * hashBuf.length));
    }
    return mask;
  }
}

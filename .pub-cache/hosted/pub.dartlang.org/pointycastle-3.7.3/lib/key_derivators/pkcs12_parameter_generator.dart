import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/src/registry/registry.dart';

class PKCS12ParametersGenerator implements PBEParametersGenerator {
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      PBEParametersGenerator,
      '/PKCS12',
      (_, final Match match) => () {
            var mac = Digest(match.group(1)!);
            return PKCS12ParametersGenerator(mac);
          });

  static final int KEY_MATERIAL = 1;

  static final int IV_MATERIAL = 2;

  static final int MAC_MATERIAL = 3;

  Digest digest;

  late int u;

  late int v;

  late Uint8List salt;

  late Uint8List password;
  late int iterationCount;

  PKCS12ParametersGenerator(this.digest) {
    u = digest.digestSize;
    v = digest.byteLength;
  }

  @override
  void init(Uint8List password, Uint8List salt, int iterationCount) {
    this.password = password;
    this.salt = salt;
    this.iterationCount = iterationCount;
  }

  ///
  /// Generates a derived key with the given [keySize] in bytes.
  ///
  @override
  KeyParameter generateDerivedParameters(int keySize) {
    var dKey = _generateDerivedKey(KEY_MATERIAL, keySize);

    return KeyParameter(dKey);
  }

  ///
  /// Generates a derived key with the given [keySize] in bytes and a derived IV with the given [ivSize].
  ///
  @override
  ParametersWithIV generateDerivedParametersWithIV(int keySize, int ivSize) {
    var dKey = _generateDerivedKey(KEY_MATERIAL, keySize);

    var iv = _generateDerivedKey(IV_MATERIAL, ivSize);

    return ParametersWithIV(KeyParameter(dKey), iv);
  }

  ///
  /// Generates a derived key with the given [keySize] in bytes used for mac generating.
  ///
  @override
  KeyParameter generateDerivedMacParameters(int keySize) {
    var dKey = _generateDerivedKey(MAC_MATERIAL, keySize);

    return KeyParameter(dKey);
  }

  Uint8List _generateDerivedKey(int idByte, int n) {
    var D = Uint8List(v);
    var dKey = Uint8List(n);
    for (var i = 0; i != D.length; i++) {
      D[i] = idByte;
    }
    Uint8List S;
    if (salt.isNotEmpty) {
      S = Uint8List((v * (((salt.length + v) - 1) ~/ v)));
      for (var i = 0; i != S.length; i++) {
        S[i] = salt[i % salt.length];
      }
    } else {
      S = Uint8List(0);
    }
    Uint8List P;
    if (password.isNotEmpty) {
      P = Uint8List((v * (((password.length + v) - 1) ~/ v)));
      for (var i = 0; i != P.length; i++) {
        P[i] = password[i % password.length];
      }
    } else {
      P = Uint8List(0);
    }
    var I = Uint8List((S.length + P.length));
    _arrayCopy(S, 0, I, 0, S.length);
    _arrayCopy(P, 0, I, S.length, P.length);
    var B = Uint8List(v);
    var c = (((n + u) - 1) ~/ u);
    var A = Uint8List(u);
    for (var i = 1; i <= c; i++) {
      digest.update(D, 0, D.length);
      digest.update(I, 0, I.length);
      digest.doFinal(A, 0);
      for (var j = 1; j < iterationCount; j++) {
        digest.update(A, 0, A.length);
        digest.doFinal(A, 0);
      }
      for (var j = 0; j != B.length; j++) {
        B[j] = A[j % A.length];
      }
      for (var j = 0; j != (I.length ~/ v); j++) {
        _adjust(I, j * v, B);
      }
      if (i == c) {
        _arrayCopy(A, 0, dKey, (i - 1) * u, dKey.length - ((i - 1) * u));
      } else {
        _arrayCopy(A, 0, dKey, (i - 1) * u, A.length);
      }
    }
    return dKey;
  }

  void _arrayCopy(Uint8List? sourceArr, int sourcePos, Uint8List? outArr,
      int outPos, int len) {
    for (var i = 0; i < len; i++) {
      outArr![outPos + i] = sourceArr![sourcePos + i];
    }
  }

  void _adjust(Uint8List a, int aOff, Uint8List b) {
    var x = (b[b.length - 1] & 0xff) + (a[aOff + b.length - 1] & 0xff) + 1;

    a[aOff + b.length - 1] = x;
    x >>>= 8;

    for (var i = b.length - 2; i >= 0; i--) {
      x += (b[i] & 0xff) + (a[aOff + i] & 0xff);
      a[aOff + i] = x;
      x >>>= 8;
    }
  }
}

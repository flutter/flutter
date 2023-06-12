import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/macs/hmac.dart';

class Uint8ListEquality {
  static bool equals(Uint8List mac, Uint8List computedMac) {
    if (mac.length != computedMac.length) {
      return false;
    }
    var v = 0;
    for (var i = 0; i < mac.length; i++) {
      v |= mac[i] ^ computedMac[i];
    }
    return v == 0;
  }
}

class AesCipherUtil {
  static HMac getMacBasedPRF(Uint8List derivedKey, int aesKeyStrength) {
    var mac = HMac(SHA1Digest(), 64);
    mac.init(KeyParameter(derivedKey));
    return mac;
  }

  static void prepareBuffAESIVBytes(Uint8List buff, int nonce) {
    buff[0] = nonce & 0xFF;
    buff[1] = (nonce >> 8) & 0xFF;
    buff[2] = (nonce >> 16) & 0xFF;
    buff[3] = (nonce >> 24) & 0xFF;

    for (int i = 4; i <= 15; ++i) {
      buff[i] = 0;
    }
  }
}

// AesDecrypt
class AesDecrypt {
  int nonce = 1;
  Uint8List iv = Uint8List(16);
  Uint8List counterBlock = Uint8List(16);
  Uint8List derivedKey;
  int aesKeyStrength;
  AESEngine? aesEngine;
  HMac? mac;

  int decryptData(Uint8List buff, int start, int len) {
    for (int j = start; j < start + len; j += 16) {
      int loopCount = j + 16 <= start + len ? 16 : start + len - j;
      mac?.update(buff, j, loopCount);
      AesCipherUtil.prepareBuffAESIVBytes(iv, nonce);
      aesEngine?.processBlock(iv, 0, counterBlock, 0);
      for (int k = 0; k < loopCount; ++k) {
        buff[j + k] ^= counterBlock[k];
      }
      ++nonce;
    }
    return len;
  }

  AesDecrypt(this.derivedKey, this.aesKeyStrength) {
    aesEngine = AESEngine();
    aesEngine!.init(true, KeyParameter(derivedKey));
    mac = AesCipherUtil.getMacBasedPRF(derivedKey, aesKeyStrength);
  }
}

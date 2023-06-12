import 'dart:typed_data';

import 'package:hive/src/crypto/aes_cbc_pkcs7.dart';
import 'package:hive/src/util/extensions.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';

import 'message.dart';

PaddedBlockCipherImpl getCipher() {
  var pcCipher = PaddedBlockCipherImpl(
    PKCS7Padding(),
    CBCBlockCipher(AESEngine()),
  );
  pcCipher.init(
    true,
    PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    ),
  );
  return pcCipher;
}

void main() {
  group('AesCbcPkcs7', () {
    test('.encrypt()', () {
      var out = Uint8List(1100);
      var cipher = AesCbcPkcs7(key);
      for (var i = 1; i < 1000; i++) {
        var input = message.view(0, i);
        var outLen = cipher.encrypt(iv, input, 0, i, out, 0);
        var pcOut = getCipher().process(input);

        expect(out.view(0, outLen), pcOut);
      }
    });

    test('.decrypt()', () {
      var out = Uint8List(1100);
      var cipher = AesCbcPkcs7(key);
      for (var i = 1; i < 1000; i++) {
        var input = message.view(0, i);
        var encrypted = getCipher().process(input);
        var outLen = cipher.decrypt(iv, encrypted, 0, encrypted.length, out, 0);
        expect(out.view(0, outLen), input);
      }
    });
  });
}

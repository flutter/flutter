@TestOn('vm')
library test.stream.chacha20poly1305_test;

import 'dart:typed_data';

import 'package:pointycastle/macs/poly1305.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/src/utils.dart';
import 'package:pointycastle/stream/chacha20poly1305.dart';
import 'package:pointycastle/stream/chacha7539.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

int i = 0;

void main() {
  //Test from BC
  var K = createUint8ListFromHexString(
      '808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f');
  var P = createUint8ListFromHexString(
      '4c616469657320616e642047656e746c656d656e206f66207468652063'
      '6c617373206f66202739393a204966204920636f756c64206f6666657220796f75206f6e6'
      'c79206f6e652074697020666f7220746865206675747572652c2073756e73637265656e20'
      '776f756c642062652069742e');
  var A = createUint8ListFromHexString('50515253c0c1c2c3c4c5c6c7');
  var N = createUint8ListFromHexString('070000004041424344454647');
  var C = createUint8ListFromHexString(
      'd31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a73'
      '6ee62d63dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b3692'
      'ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3ff4def08e4'
      'b7a9de576d26586cec64b6116');
  var T = createUint8ListFromHexString('1ae10b594f09e26a7e902ecbd0600691');
  runTest(K, P, A, N, C, T);
}

void runTest(Uint8List K, Uint8List P, Uint8List A, Uint8List N, Uint8List C,
    Uint8List T) {
  test('ChaChaPoly1305 Test #${++i}', () {
    var parameters = AEADParameters(KeyParameter(K), T.length * 8, N, A);
    var chaChaEngine = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305())
      ..init(true, parameters);
    var chaChaEngineDecrypt = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305())
      ..init(false, parameters);
    var enc = Uint8List(chaChaEngine.getOutputSize(P.length));
    var len = chaChaEngine.processBytes(P, 0, P.length, enc, 0);
    len += chaChaEngine.doFinal(enc, len);
    if (enc.length != len) {
      throw StateError('');
    }

    var mac = chaChaEngine.mac;
    var data = Uint8List(P.length);
    arrayCopy(enc, 0, data, 0, data.length);
    var tail = Uint8List(enc.length - P.length);
    arrayCopy(enc, P.length, tail, 0, tail.length);

    for (var i = 0; i < data.length; i++) {
      if (data[i] != C[i]) {
        throw StateError('');
      }
    }

    for (var i = 0; i < mac.length; i++) {
      if (T[i] != mac[i]) {
        throw StateError('');
      }
    }

    for (var i = 0; i < tail.length; i++) {
      if (T[i] != tail[i]) {
        throw StateError('');
      }
    }

    var dec = Uint8List(chaChaEngineDecrypt.getOutputSize(enc.length));
    len = chaChaEngineDecrypt.processBytes(enc, 0, enc.length, dec, 0);
    len += chaChaEngineDecrypt.doFinal(dec, len);
    mac = chaChaEngineDecrypt.mac;

    data = Uint8List(C.length);
    arrayCopy(dec, 0, data, 0, data.length);

    for (var i = 0; i < data.length; i++) {
      if (P[i] != data[i]) {
        throw StateError('');
      }
    }
  });
}

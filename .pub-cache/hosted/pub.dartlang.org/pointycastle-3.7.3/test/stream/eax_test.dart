// See file LICENSE for more information.

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:pointycastle/src/utils.dart';
import 'package:pointycastle/stream/eax.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

/// Ported from BouncyCastle's Java tests: https://github.com/bcgit/bc-java/blob/master/core/src/test/java/org/bouncycastle/crypto/test/EAXTest.java
void main() {
  group('eax vectors 1-11', () {
    checkVectors(1, K1, 128, N1, A1, P1, T1, C1);
    checkVectors(2, K2, 128, N2, A2, P2, T2, C2);
    checkVectors(3, K3, 128, N3, A3, P3, T3, C3);
    checkVectors(4, K4, 128, N4, A4, P4, T4, C4);
    checkVectors(5, K5, 128, N5, A5, P5, T5, C5);
    checkVectors(6, K6, 128, N6, A6, P6, T6, C6);
    checkVectors(7, K7, 128, N7, A7, P7, T7, C7);
    checkVectors(8, K8, 128, N8, A8, P8, T8, C8);
    checkVectors(9, K9, 128, N9, A9, P9, T9, C9);
    checkVectors(10, K10, 128, N10, A10, P10, T10, C10);
    checkVectors(11, K11, 32, N11, A11, P11, T11, C11);
  });

  group('eax ivParam', () {
    var eax = EAX(AESEngine());
    ivParamTest(1, eax, K1, N1);
  });

  group('eax throw behaviour', () {
    var eax = EAX(AESEngine());
    eax.init(false, AEADParameters(KeyParameter(K1), 32, N2, A2));
    var enc = Uint8List(C2.length);
    var len = eax.processBytes(C2, 0, C2.length, enc, 0);
    test('invalid cipher text picked up',
        () => expect(() => eax.doFinal(enc, len), throwsStateError));

    test(
        'illegal argument picked up',
        () => expect(
            () => eax.init(false, KeyParameter(K1)), throwsArgumentError));
  });

  group('eax random', () {
    randomTests();
  });

  /* AEADTestUtil from bouncycastle/java needs to be ported
  AEADTestUtil.testReset(this, new EAXBlockCipher(new AESEngine()), new EAXBlockCipher(new AESEngine()), new AEADParameters(new KeyParameter(K1), 32, N2));
  AEADTestUtil.testTampering(this, eax, new AEADParameters(new KeyParameter(K1), 32, N2));
  AEADTestUtil.testOutputSizes(this, new EAXBlockCipher(new AESEngine()), new AEADParameters(
  new KeyParameter(K1), 32, N2));
  AEADTestUtil.testBufferSizeChecks(this, new EAXBlockCipher(new AESEngine()), new AEADParameters(
  new KeyParameter(K1), 32, N2));*/
}

void checkVectors(int count, Uint8List k, int macSize, Uint8List n, Uint8List a,
    Uint8List p, Uint8List t, Uint8List c) {
  var fa = Uint8List(a.length ~/ 2);
  var la = Uint8List(a.length - (a.length ~/ 2));
  fa.setRange(0, fa.length, a);
  la.setRange(0, la.length, a.sublist(fa.length));

  _checkVectors(
      count, 'all initial associated data', k, macSize, n, a, null, p, t, c);
  _checkVectors(count, 'subsequent associated data', k, macSize, n,
      Uint8List(0), a, p, t, c);
  _checkVectors(count, 'split associated data', k, macSize, n, fa, la, p, t, c);
}

void _checkVectors(
    int count,
    String additionalDataType,
    Uint8List k,
    int macSize,
    Uint8List n,
    Uint8List a,
    Uint8List? sa,
    Uint8List p,
    Uint8List t,
    Uint8List c) {
  var encEax = EAX(AESEngine());
  var decEax = EAX(AESEngine());

  var parameters = AEADParameters(KeyParameter(k), macSize, n, a);
  encEax.init(true, parameters);
  decEax.init(false, parameters);

  _runCheckVectors(count, encEax, decEax, additionalDataType, sa, p, t, c);
  _runCheckVectors(count, encEax, decEax, additionalDataType, sa, p, t, c);

/* this java code seems to be obsolete since the KeyParam is not nullable

// key reuse test
parameters = AEADParameters(null, macSize, n, a);
encEax.init(true, parameters);
decEax.init(false, parameters);

runCheckVectors(count, encEax, decEax, additionalDataType, sa, p, t, c);
runCheckVectors(count, encEax, decEax, additionalDataType, sa, p, t, c);*/
}

void _runCheckVectors(
    int count,
    EAX encEax,
    EAX decEax,
    String additionalDataType,
    Uint8List? sa,
    Uint8List p,
    Uint8List t,
    Uint8List c) {
  test('test $count with $additionalDataType', () {
    var enc = Uint8List(c.length);

    if (sa != null) {
      encEax.processAADBytes(sa, 0, sa.length);
    }

    var len = encEax.processBytes(p, 0, p.length, enc, 0);

    len += encEax.doFinal(enc, len);
    expect(enc, orderedEquals(c),
        reason:
            'encrypted stream mismatch in test $count with $additionalDataType');

    var tmp = Uint8List(enc.length);

    if (sa != null) {
      decEax.processAADBytes(sa, 0, sa.length);
    }

    len = decEax.processBytes(enc, 0, enc.length, tmp, 0);

    len += decEax.doFinal(tmp, len);

    var dec = Uint8List(len);

    dec.setRange(0, len, tmp);

    expect(dec, orderedEquals(p),
        reason:
            'decrypted stream mismatch in test $count with $additionalDataType');
    expect(decEax.mac, orderedEquals(t),
        reason: 'MAC mismatch in test $count with $additionalDataType');
  });
}

void ivParamTest(int count, EAX eax, Uint8List k, Uint8List n) {
  test('ivParamTest $count', () {
    var p = createUint8ListFromString('hello world!!');

    eax.init(true, ParametersWithIV(KeyParameter(k), n));

    var enc = Uint8List(p.length + 8);

    var len = eax.processBytes(p, 0, p.length, enc, 0);
    len += eax.doFinal(enc, len);

    eax.init(false, ParametersWithIV(KeyParameter(k), n));

    var tmp = Uint8List(enc.length);

    len = eax.processBytes(enc, 0, enc.length, tmp, 0);
    len += eax.doFinal(tmp, len);

    var dec = Uint8List(len);
    dec.setRange(0, len, tmp);

    expect(dec, orderedEquals(p),
        reason: 'decrypted stream mismatch in test $count');
  });
}

void randomTests() {
  var srng = SecureRandom('Fortuna')
    ..seed(
        KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));
  for (var i = 0; i < 10; ++i) {
    randomTest(srng);
  }
}

void randomTest(SecureRandom srng) {
  test('randomTest', () {
    var DAT_LEN = unsignedShiftRight64(srng.nextUint32(), 22);
    var nonce = srng.nextBytes(NONCE_LEN);
    var authen = srng.nextBytes(AUTHEN_LEN);
    var datIn = srng.nextBytes(DAT_LEN);
    var key = srng.nextBytes(16);

    var engine = AESEngine();
    var sessKey = KeyParameter(key);
    var eaxCipher = EAX(engine);

    var params = AEADParameters(sessKey, MAC_LEN * 8, nonce, authen);
    eaxCipher.init(true, params);

    var intrDat = Uint8List(eaxCipher.getOutputSize(datIn.length));
    var outOff = eaxCipher.processBytes(datIn, 0, DAT_LEN, intrDat, 0);
    outOff += eaxCipher.doFinal(intrDat, outOff);

    eaxCipher.init(false, params);
    var datOut = Uint8List(eaxCipher.getOutputSize(outOff));
    var resultLen = eaxCipher.processBytes(intrDat, 0, outOff, datOut, 0);
    eaxCipher.doFinal(datOut, resultLen);

    expect(datIn, orderedEquals(datOut), reason: 'EAX roundtrip mismatch');
  });
}

const int NONCE_LEN = 8;
const int MAC_LEN = 8;
const int AUTHEN_LEN = 20;

Uint8List K1 = createUint8ListFromHexString('233952DEE4D5ED5F9B9C6D6FF80FF478');
Uint8List N1 = createUint8ListFromHexString('62EC67F9C3A4A407FCB2A8C49031A8B3');
Uint8List A1 = createUint8ListFromHexString('6BFB914FD07EAE6B');
Uint8List P1 = createUint8ListFromHexString('');
Uint8List C1 = createUint8ListFromHexString('E037830E8389F27B025A2D6527E79D01');
Uint8List T1 = createUint8ListFromHexString('E037830E8389F27B025A2D6527E79D01');

Uint8List K2 = createUint8ListFromHexString('91945D3F4DCBEE0BF45EF52255F095A4');
Uint8List N2 = createUint8ListFromHexString('BECAF043B0A23D843194BA972C66DEBD');
Uint8List A2 = createUint8ListFromHexString('FA3BFD4806EB53FA');
Uint8List P2 = createUint8ListFromHexString('F7FB');
Uint8List C2 =
    createUint8ListFromHexString('19DD5C4C9331049D0BDAB0277408F67967E5');
Uint8List T2 = createUint8ListFromHexString('5C4C9331049D0BDAB0277408F67967E5');

Uint8List K3 = createUint8ListFromHexString('01F74AD64077F2E704C0F60ADA3DD523');
Uint8List N3 = createUint8ListFromHexString('70C3DB4F0D26368400A10ED05D2BFF5E');
Uint8List A3 = createUint8ListFromHexString('234A3463C1264AC6');
Uint8List P3 = createUint8ListFromHexString('1A47CB4933');
Uint8List C3 =
    createUint8ListFromHexString('D851D5BAE03A59F238A23E39199DC9266626C40F80');
Uint8List T3 = createUint8ListFromHexString('3A59F238A23E39199DC9266626C40F80');

Uint8List K4 = createUint8ListFromHexString('D07CF6CBB7F313BDDE66B727AFD3C5E8');
Uint8List N4 = createUint8ListFromHexString('8408DFFF3C1A2B1292DC199E46B7D617');
Uint8List A4 = createUint8ListFromHexString('33CCE2EABFF5A79D');
Uint8List P4 = createUint8ListFromHexString('481C9E39B1');
Uint8List C4 =
    createUint8ListFromHexString('632A9D131AD4C168A4225D8E1FF755939974A7BEDE');
Uint8List T4 = createUint8ListFromHexString('D4C168A4225D8E1FF755939974A7BEDE');

Uint8List K5 = createUint8ListFromHexString('35B6D0580005BBC12B0587124557D2C2');
Uint8List N5 = createUint8ListFromHexString('FDB6B06676EEDC5C61D74276E1F8E816');
Uint8List A5 = createUint8ListFromHexString('AEB96EAEBE2970E9');
Uint8List P5 = createUint8ListFromHexString('40D0C07DA5E4');
Uint8List C5 = createUint8ListFromHexString(
    '071DFE16C675CB0677E536F73AFE6A14B74EE49844DD');
Uint8List T5 = createUint8ListFromHexString('CB0677E536F73AFE6A14B74EE49844DD');

Uint8List K6 = createUint8ListFromHexString('BD8E6E11475E60B268784C38C62FEB22');
Uint8List N6 = createUint8ListFromHexString('6EAC5C93072D8E8513F750935E46DA1B');
Uint8List A6 = createUint8ListFromHexString('D4482D1CA78DCE0F');
Uint8List P6 = createUint8ListFromHexString('4DE3B35C3FC039245BD1FB7D');
Uint8List C6 = createUint8ListFromHexString(
    '835BB4F15D743E350E728414ABB8644FD6CCB86947C5E10590210A4F');
Uint8List T6 = createUint8ListFromHexString('ABB8644FD6CCB86947C5E10590210A4F');

Uint8List K7 = createUint8ListFromHexString('7C77D6E813BED5AC98BAA417477A2E7D');
Uint8List N7 = createUint8ListFromHexString('1A8C98DCD73D38393B2BF1569DEEFC19');
Uint8List A7 = createUint8ListFromHexString('65D2017990D62528');
Uint8List P7 =
    createUint8ListFromHexString('8B0A79306C9CE7ED99DAE4F87F8DD61636');
Uint8List C7 = createUint8ListFromHexString(
    '02083E3979DA014812F59F11D52630DA30137327D10649B0AA6E1C181DB617D7F2');
Uint8List T7 = createUint8ListFromHexString('137327D10649B0AA6E1C181DB617D7F2');

Uint8List K8 = createUint8ListFromHexString('5FFF20CAFAB119CA2FC73549E20F5B0D');
Uint8List N8 = createUint8ListFromHexString('DDE59B97D722156D4D9AFF2BC7559826');
Uint8List A8 = createUint8ListFromHexString('54B9F04E6A09189A');
Uint8List P8 =
    createUint8ListFromHexString('1BDA122BCE8A8DBAF1877D962B8592DD2D56');
Uint8List C8 = createUint8ListFromHexString(
    '2EC47B2C4954A489AFC7BA4897EDCDAE8CC33B60450599BD02C96382902AEF7F832A');
Uint8List T8 = createUint8ListFromHexString('3B60450599BD02C96382902AEF7F832A');

Uint8List K9 = createUint8ListFromHexString('A4A4782BCFFD3EC5E7EF6D8C34A56123');
Uint8List N9 = createUint8ListFromHexString('B781FCF2F75FA5A8DE97A9CA48E522EC');
Uint8List A9 = createUint8ListFromHexString('899A175897561D7E');
Uint8List P9 =
    createUint8ListFromHexString('6CF36720872B8513F6EAB1A8A44438D5EF11');
Uint8List C9 = createUint8ListFromHexString(
    '0DE18FD0FDD91E7AF19F1D8EE8733938B1E8E7F6D2231618102FDB7FE55FF1991700');
Uint8List T9 = createUint8ListFromHexString('E7F6D2231618102FDB7FE55FF1991700');

Uint8List K10 =
    createUint8ListFromHexString('8395FCF1E95BEBD697BD010BC766AAC3');
Uint8List N10 =
    createUint8ListFromHexString('22E7ADD93CFC6393C57EC0B3C17D6B44');
Uint8List A10 = createUint8ListFromHexString('126735FCC320D25A');
Uint8List P10 =
    createUint8ListFromHexString('CA40D7446E545FFAED3BD12A740A659FFBBB3CEAB7');
Uint8List C10 = createUint8ListFromHexString(
    'CB8920F87A6C75CFF39627B56E3ED197C552D295A7CFC46AFC253B4652B1AF3795B124AB6E');
Uint8List T10 =
    createUint8ListFromHexString('CFC46AFC253B4652B1AF3795B124AB6E');

Uint8List K11 =
    createUint8ListFromHexString('8395FCF1E95BEBD697BD010BC766AAC3');
Uint8List N11 =
    createUint8ListFromHexString('22E7ADD93CFC6393C57EC0B3C17D6B44');
Uint8List A11 = createUint8ListFromHexString('126735FCC320D25A');
Uint8List P11 =
    createUint8ListFromHexString('CA40D7446E545FFAED3BD12A740A659FFBBB3CEAB7');
Uint8List C11 = createUint8ListFromHexString(
    'CB8920F87A6C75CFF39627B56E3ED197C552D295A7CFC46AFC');
Uint8List T11 = createUint8ListFromHexString('CFC46AFC');

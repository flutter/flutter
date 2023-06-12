// See file LICENSE for more information.

library test.asymmetric.ec_elgamal_test;

import 'package:pointycastle/asymmetric/ec_elgamal.dart';
import 'package:pointycastle/ecc/ecc_fp.dart' as fp;
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

SecureRandom _newSecureRandom() => FortunaRandom()
  ..seed(KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));

void main() {
  var n = BigInt.parse(
      '6277101735386680763835789423176059013767194773182842284081');
  var q = BigInt.parse(
      '6277101735386680763835789423207666416083908700390324961279');
  var a = BigInt.parse(
    'fffffffffffffffffffffffffffffffefffffffffffffffc',
    radix: 16,
  );
  var b = BigInt.parse(
    '64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1',
    radix: 16,
  );
  var curve = fp.ECCurve(q, a, b);
  var params = ECDomainParametersImpl(
    'test_elgamal',
    curve,
    curve.decodePoint(
      createUint8ListFromHexString(
        '03188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012',
      ),
    )!, // G
    n,
  );
  var pubKey = ECPublicKey(
    curve.decodePoint(
      createUint8ListFromHexString(
          '0262b12d60690cdcf330babab6e69763b471f994dd702d16a5'),
    ), // Q
    params,
  );
  var priKey = ECPrivateKey(
    BigInt.parse(
        '651056770906015076056810763456358567190100156695615665659'), // d
    params,
  );
  var secureRandom = _newSecureRandom();
  var pRandom = ParametersWithRandom<PublicKeyParameter>(
    PublicKeyParameter(pubKey),
    secureRandom,
  );

  test('ECElgamal encrypt and decrypt test: first', () {
    var value = BigInt.from(123);
    var data = (priKey.parameters!.G * value)!;
    var encryptor = ECElGamalEncryptor();
    encryptor.init(pRandom);
    var pair = encryptor.encrypt(data);
    var decryptor = ECElGamalDecryptor();
    decryptor.init(PrivateKeyParameter(priKey));
    var result = decryptor.decrypt(pair);
    expect(data, equals(result));
  });

  test('ECElgamal encrypt and decrypt test: second', () {
    var value =
        _newSecureRandom().nextBigInteger(pubKey.parameters!.n.bitLength - 1);
    var data = (priKey.parameters!.G * value)!;
    var encryptor = ECElGamalEncryptor();
    encryptor.init(pRandom);
    var pair = encryptor.encrypt(data);
    var decryptor = ECElGamalDecryptor();
    decryptor.init(PrivateKeyParameter(priKey));
    var result = decryptor.decrypt(pair);
    expect(data, equals(result));
  });
}

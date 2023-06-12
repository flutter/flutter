// See file LICENSE for more information.

library test.signers.ecdsa_vector_test;

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/utils.dart';
import 'package:test/test.dart';
import '../test/src/fixed_secure_random.dart';
import '../test/src/helpers.dart';
import 'ecdsa_vec.dart';

void main() {
  sigVer();
  sigGen();
}

void sigVer() {
  var vectors = sigVerVec;

  vectors[1]['testGroups'].forEach((grp) {
    String hashAlg = grp['hashAlg'];
    String curve = grp['curve'];

    ECDomainParameters domainParameters;
    switch (curve) {
      case 'P-192':
        domainParameters = ECCurve_secp192r1();
        break;

      case 'P-224':
        domainParameters = ECCurve_secp224r1();
        break;
      case 'P-256':
        domainParameters = ECCurve_secp256r1();
        break;
      case 'P-384':
        domainParameters = ECCurve_secp384r1();
        break;
      case 'P-521':
        domainParameters = ECCurve_secp521r1();
        break;
      default:
        throw ArgumentError('curve not supported in this test: ' + hashAlg);
    }

    String alg;

    switch (hashAlg) {
      case 'SHA2-224':
        alg = 'SHA-224/ECDSA';
        break;
      case 'SHA2-256':
        alg = 'SHA-256/ECDSA';
        break;
      case 'SHA2-384':
        alg = 'SHA-384/ECDSA';
        break;
      case 'SHA2-512':
        alg = 'SHA-512/ECDSA';
        break;
      default:
        throw ArgumentError('hash alg not supported in this test: ' + hashAlg);
    }

    group("ECDSA SigVer", () {
      grp['tests'].forEach((test) {
        checkSigVer(domainParameters, alg, grp, test);
      });
    });
  });
}

void checkSigVer(ECDomainParameters domainParameters, String alg, dynamic grp,
    dynamic vector) {
  group("${grp["tgId"]} ${grp["curve"]} ${grp["hashAlg"]}", () {
    test("test ${vector["tcId"]}", () {
      BigInt qX =
          decodeBigIntWithSign(1, createUint8ListFromHexString(vector['qx']));
      BigInt qY =
          decodeBigIntWithSign(1, createUint8ListFromHexString(vector['qy']));

      BigInt r =
          decodeBigIntWithSign(1, createUint8ListFromHexString(vector['r']));
      BigInt s =
          decodeBigIntWithSign(1, createUint8ListFromHexString(vector['s']));

      bool expectedResult = vector['testPassed'];

      var message = createUint8ListFromHexString(vector['message']);

      var pubKey = ECPublicKey(
          domainParameters.curve.createPoint(qX, qY), domainParameters);

      var params = PublicKeyParameter(pubKey);

      var signer = Signer(alg);
      signer.init(false, params);

      bool result = signer.verifySignature(message, new ECSignature(r, s));

      expect(expectedResult, equals(result));
    });
  });
}

void sigGen() {
  var vectors = sigGenVec;

  vectors[1]['testGroups'].forEach((grp) {
    String hashAlg = grp['hashAlg'];
    String curve = grp['curve'];
    BigInt d = decodeBigIntWithSign(1, createUint8ListFromHexString(grp['d']));
    BigInt qX =
        decodeBigIntWithSign(1, createUint8ListFromHexString(grp['qx']));
    BigInt qY =
        decodeBigIntWithSign(1, createUint8ListFromHexString(grp['qy']));

    // "P-224","P-256","P-384","P-521","B-233","B-283","B-409","B-571","K-233","K-283","K-409","K-571"

    ECDomainParameters domainParameters;
    switch (curve) {
      case 'P-224':
        domainParameters = ECCurve_secp224r1();
        break;
      case 'P-256':
        domainParameters = ECCurve_secp256r1();
        break;
      case 'P-384':
        domainParameters = ECCurve_secp384r1();
        break;
      case 'P-521':
        domainParameters = ECCurve_secp521r1();
        break;
      default:
        throw ArgumentError('curve not supported in this test: ' + hashAlg);
    }

    String alg;

    switch (hashAlg) {
      case 'SHA224':
        alg = 'SHA-224/ECDSA';
        break;
      case 'SHA256':
        alg = 'SHA-256/ECDSA';
        break;
      case 'SHA384':
        alg = 'SHA-384/ECDSA';
        break;
      case 'SHA512':
        alg = 'SHA-512/ECDSA';
        break;
      default:
        throw ArgumentError('hash alg not supported in this test: ' + hashAlg);
    }

    var keyPair = AsymmetricKeyPair(
        ECPublicKey(
            domainParameters.curve.createPoint(qX, qY), domainParameters),
        ECPrivateKey(d, domainParameters));

    group("ECDSA SigGen", () {
      grp['tests'].forEach((test) {
        checkSigGen(keyPair, alg, grp, test);
      });
    });
  });
}

void checkSigGen(
    AsymmetricKeyPair keyPair, String alg, dynamic grp, dynamic vector) {
  group("${grp["tgId"]} ${grp["curve"]} ${grp["hashAlg"]}", () {
    test("test ${vector["tcId"]}", () {
      var seed = createUint8ListFromHexString(vector['seed']);
      var msg = createUint8ListFromHexString(vector['message']);
      var expectedR =
          decodeBigIntWithSign(1, createUint8ListFromHexString(vector['r']));
      var expectedS =
          decodeBigIntWithSign(1, createUint8ListFromHexString(vector['s']));

      var privParams = PrivateKeyParameter(keyPair.privateKey);
      var rnd = FixedSecureRandom();
      rnd.seed(KeyParameter(seed));
      var signParams = ParametersWithRandom(privParams, rnd);

      var signer = Signer(alg);
      signer.init(true, signParams);

      var sigGenerated = signer.generateSignature(msg) as ECSignature;

      expect(sigGenerated.r, equals(expectedR));
      expect(sigGenerated.s, equals(expectedS));
    });
  });
}

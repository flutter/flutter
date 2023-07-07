// See file LICENSE for more information.

library test.test.signer_tests;

import 'package:test/test.dart';
import 'package:pointycastle/pointycastle.dart';

import '../src/helpers.dart';

void runSignerTests(Signer signer, CipherParameters Function() signParams,
    CipherParameters Function() verifyParams, List messageSignaturePairs) {
  group('${signer.algorithmName}:', () {
    group('generateSignature:', () {
      for (var i = 0; i < messageSignaturePairs.length; i += 2) {
        var message = messageSignaturePairs[i];
        var signature = messageSignaturePairs[i + 1];

        test(
            '${formatAsTruncated(message as String)}',
            () => _runGenerateSignatureTest(
                signer, signParams, message, signature as Signature));
      }
    });

    group('verifySignature:', () {
      for (var i = 0; i < messageSignaturePairs.length; i += 2) {
        var message = messageSignaturePairs[i];
        var signature = messageSignaturePairs[i + 1];

        test(
            '${formatAsTruncated(message as String)}',
            () => _runVerifySignatureTest(
                signer, verifyParams, message, signature as Signature));
      }
    });
  });
}

void _runGenerateSignatureTest(
    Signer signer,
    CipherParameters Function() params,
    String message,
    Signature expectedSignature) {
  signer.reset();
  signer.init(true, params());

  var signature = signer.generateSignature(createUint8ListFromString(message));

  expect(signature, expectedSignature);
}

void _runVerifySignatureTest(Signer signer, CipherParameters Function() params,
    String message, Signature signature) {
  signer.reset();
  signer.init(false, params());

  var ok =
      signer.verifySignature(createUint8ListFromString(message), signature);

  expect(ok, true);
}

// -----

void runSignerTestsFail(Signer signer, CipherParameters Function() signParams,
    CipherParameters Function() verifyParams, List messageSignaturePairs) {
  group('${signer.algorithmName}:', () {
    group('generateSignature:', () {
      for (var i = 0; i < messageSignaturePairs.length; i += 2) {
        var message = messageSignaturePairs[i];
        var signature = messageSignaturePairs[i + 1];

        test(
            '${formatAsTruncated(message as String)}',
            () => _runGenerateSignatureTestFail(
                signer, signParams, message, signature as Signature));
      }
    });

    group('verifySignature:', () {
      for (var i = 0; i < messageSignaturePairs.length; i += 2) {
        var message = messageSignaturePairs[i];
        var signature = messageSignaturePairs[i + 1];

        test(
            '${formatAsTruncated(message as String)}',
            () => _runVerifySignatureTestFail(
                signer, verifyParams, message, signature as Signature));
      }
    });
  });
}

void _runGenerateSignatureTestFail(
    Signer signer,
    CipherParameters Function() params,
    String message,
    Signature expectedSignature) {
  signer.reset();
  signer.init(true, params());

  var signature = signer.generateSignature(createUint8ListFromString(message));

  expect(signature, isNot(equals(expectedSignature)));
}

void _runVerifySignatureTestFail(Signer signer,
    CipherParameters Function() params, String message, Signature signature) {
  signer.reset();
  signer.init(false, params());

  var ok =
      signer.verifySignature(createUint8ListFromString(message), signature);

  expect(ok, false);
}

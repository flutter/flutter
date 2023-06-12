// See file LICENSE for more information.

library test.signers.ecdsa_signer_test;

import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

import '../test/runners/signer.dart';
import '../test/src/null_secure_random.dart';

void main() {
  var eccDomain = ECDomainParameters('prime192v1');

  // ignore_for_file: non_constant_identifier_names
  var Qx = BigInt.parse(
      '1498602238651628509310686451034731914387602356706565103527');
  var Qy = BigInt.parse(
      '6264116558863692852155702059476882343593676720209154057133');
  var Q = eccDomain.curve.createPoint(Qx, Qy);
  var verifyParams = () => PublicKeyParameter(ECPublicKey(Q, eccDomain));

  var d = BigInt.parse(
      '3062713166230336928689662410859599564103408831862304472446');
  var privParams = PrivateKeyParameter(ECPrivateKey(d, eccDomain));
  var signParams = () => ParametersWithRandom(privParams, NullSecureRandom());

  runSignerTests(Signer('SHA-1/ECDSA'), signParams, verifyParams, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
    _newSignature('4165461920577864743570110591887661239883413257826890841803',
        '4192466672819485121438972302615731758021595554374647962056'),
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
    _newSignature('4165461920577864743570110591887661239883413257826890841803',
        '4124624969901653266585887193504647035526068719224431686679'),
  ]);

  runSignerTests(Signer('SHA-1/DET-ECDSA'), signParams, verifyParams, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
    _newSignature('6052012072724008730564193612572794050491696411960275629627',
        '2161019278549597185578307509265728228343111084484752661213'),
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
    _newSignature('4087581495017442027693712553398765118791696551913571321320',
        '4593990646726045634082084213208629584972116888758459298644'),
  ]);

  runSignerTests(
      NormalizedECDSASigner(Signer('SHA-1/DET-ECDSA') as ECDSASigner),
      signParams,
      verifyParams, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
    _newSignature('6052012072724008730564193612572794050491696411960275629627',
        '2161019278549597185578307509265728228343111084484752661213'),
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
    _newSignature('4087581495017442027693712553398765118791696551913571321320',
        '1683111088660635129753705209967429428795077884424382985437'),
  ]);

  runSignerTestsFail(
      NormalizedECDSASigner(Signer('SHA-1/DET-ECDSA') as ECDSASigner,
          enforceNormalized: true),
      signParams,
      verifyParams,
      [
        'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
        _newSignature(
            '4087581495017442027693712553398765118791696551913571321320',
            '4593990646726045634082084213208629584972116888758459298644'),
      ]);
}

ECSignature _newSignature(String r, String s) =>
    ECSignature(BigInt.parse(r), BigInt.parse(s));

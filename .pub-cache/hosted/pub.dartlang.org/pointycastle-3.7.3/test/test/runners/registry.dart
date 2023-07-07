// See file LICENSE for more information.

library test.test.registry_tests;

import 'package:pointycastle/pointycastle.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

void testAsymmetricBlockCipher(String algorithmName) {
  var cipher = AsymmetricBlockCipher(algorithmName);
  expect(cipher, const TypeMatcher<AsymmetricBlockCipher>());
  expect(cipher.algorithmName, algorithmName);
}

void testBlockCipher(String algorithmName) {
  var cipher = BlockCipher(algorithmName);
  expect(cipher, const TypeMatcher<BlockCipher>());
  expect(cipher.algorithmName, algorithmName);
}

void testDigest(String algorithmName) {
  var digest = Digest(algorithmName);
  expect(digest, const TypeMatcher<Digest>());
  expect(digest.algorithmName, algorithmName);
}

void testECDomainParameters(String domainName) {
  var domain = ECDomainParameters(domainName);
  expect(domain, const TypeMatcher<ECDomainParameters>());
  expect(domain.domainName, domainName);
}

void testKeyDerivator(String algorithmName) {
  var kf = KeyDerivator(algorithmName);
  expect(kf, const TypeMatcher<KeyDerivator>());
  expect(kf.algorithmName, algorithmName);
}

void testKeyGenerator(String algorithmName) {
  var kg = KeyGenerator(algorithmName);
  expect(kg, const TypeMatcher<KeyGenerator>());
  expect(kg.algorithmName, algorithmName);
}

void testMac(String algorithmName) {
  var mac = Mac(algorithmName);
  expect(mac, const TypeMatcher<Mac>());
  expect(mac.algorithmName, algorithmName);
}

void testPaddedBlockCipher(String algorithmName) {
  var parts = algorithmName.split('/');

  var pbc = PaddedBlockCipher(algorithmName);
  expect(pbc, const TypeMatcher<PaddedBlockCipher>());
  expect(pbc.algorithmName, algorithmName);

  var padding = pbc.padding;
  expect(padding, const TypeMatcher<Padding>());
  expect(padding.algorithmName, equals(parts[2]));

  var cbc = pbc.cipher;
  expect(cbc, const TypeMatcher<BlockCipher>());
  expect(cbc.algorithmName, equals('${parts[0]}/${parts[1]}'));
}

void testPadding(String algorithmName) {
  var padding = Padding(algorithmName);
  expect(padding, const TypeMatcher<Padding>());
  expect(padding.algorithmName, algorithmName);
}

void testSecureRandom(String algorithmName) {
  var rnd = SecureRandom(algorithmName);
  expect(rnd, const TypeMatcher<SecureRandom>());
  expect(rnd.algorithmName, algorithmName);
}

void testSigner(String algorithmName) {
  var signer = Signer(algorithmName);
  expect(signer, const TypeMatcher<Signer>());
  expect(signer.algorithmName, algorithmName);
}

void testStreamCipher(String algorithmName) {
  var cipher = StreamCipher(algorithmName);
  expect(cipher, const TypeMatcher<StreamCipher>());
  expect(cipher.algorithmName, algorithmName);
}

void testAEADCipher(String algorithmName) {
  var cipher = AEADCipher(algorithmName);
  expect(cipher, const TypeMatcher<AEADCipher>());
  expect(cipher.algorithmName, algorithmName);
}

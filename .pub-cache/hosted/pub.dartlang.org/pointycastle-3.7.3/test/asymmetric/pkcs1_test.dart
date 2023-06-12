// See file LICENSE for more information.

library test.asymmetric.pkcs1_test;

import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/src/registry/registry.dart';

import '../test/runners/asymmetric_block_cipher.dart';
import '../test/src/null_asymmetric_block_cipher.dart';
import '../test/src/null_secure_random.dart';

void main() {
  var pubpar = () => ParametersWithRandom(
      PublicKeyParameter(NullPublicKey()), NullSecureRandom());
  var privpar = () => ParametersWithRandom(
      PrivateKeyParameter(NullPrivateKey()), NullSecureRandom());

  registry.register(NullAsymmetricBlockCipher.factoryConfig);
  registry.register(NullSecureRandom.factoryConfig);

  runAsymmetricBlockCipherTests(
      AsymmetricBlockCipher('Null/PKCS1'), pubpar, privpar, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    '020a010203040506070809004c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e2e2e',
    '01ffffffffffffffffffff004c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e2e2e',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme',
    '02080102030405060700456e20756e206c75676172206465204c61204d616e6368612c206465206375796f206e6f6d627265206e6f2071756965726f2061636f726461726d65',
    '01ffffffffffffffff00456e20756e206c75676172206465204c61204d616e6368612c206465206375796f206e6f6d627265206e6f2071756965726f2061636f726461726d65',
  ]);
}

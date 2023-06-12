library src.registry.impl;

import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_derivators/concat_kdf.dart';
import 'package:pointycastle/key_derivators/ecdh_kdf.dart';
import 'package:pointycastle/src/registry/registry.dart';

void registerFactories(FactoryRegistry registry) {
  _registerAsymmetricCiphers(registry);
  _registerBlockCiphers(registry);
  _registerDigests(registry);
  _registerECCurves(registry);
  _registerKeyDerivators(registry);
  _registerKeyGenerators(registry);
  _registerPbeParameterGenerators(registry);
  _registerMacs(registry);
  _registerPaddedBlockCiphers(registry);
  _registerPaddings(registry);
  _registerRandoms(registry);
  _registerSigners(registry);
  _registerStreamCiphers(registry);
}

void _registerAsymmetricCiphers(FactoryRegistry registry) {
  registry.register(OAEPEncoding.factoryConfig);
  registry.register(PKCS1Encoding.factoryConfig);
  registry.register(RSAEngine.factoryConfig);
}

void _registerBlockCiphers(FactoryRegistry registry) {
  registry.register(AESEngine.factoryConfig);
  registry.register(RC2Engine.factoryConfig);
  registry.register(DESedeEngine.factoryConfig);
  // modes
  registry.register(CBCBlockCipher.factoryConfig);
  registry.register(CFBBlockCipher.factoryConfig);
  registry.register(CTRBlockCipher.factoryConfig);
  registry.register(ECBBlockCipher.factoryConfig);
  registry.register(GCTRBlockCipher.factoryConfig);
  registry.register(OFBBlockCipher.factoryConfig);
  registry.register(SICBlockCipher.factoryConfig);
  registry.register(GCMBlockCipher.factoryConfig);
  registry.register(CCMBlockCipher.factoryConfig);
  registry.register(IGEBlockCipher.factoryConfig);
}

void _registerDigests(FactoryRegistry registry) {
  registry.register(Blake2bDigest.factoryConfig);
  registry.register(MD2Digest.factoryConfig);
  registry.register(MD4Digest.factoryConfig);
  registry.register(MD5Digest.factoryConfig);
  registry.register(RIPEMD128Digest.factoryConfig);
  registry.register(RIPEMD160Digest.factoryConfig);
  registry.register(RIPEMD256Digest.factoryConfig);
  registry.register(RIPEMD320Digest.factoryConfig);
  registry.register(SHA1Digest.factoryConfig);
  registry.register(SHA3Digest.factoryConfig);
  registry.register(KeccakDigest.factoryConfig);
  registry.register(SHA224Digest.factoryConfig);
  registry.register(SHA256Digest.factoryConfig);
  registry.register(SHA384Digest.factoryConfig);
  registry.register(SHA512Digest.factoryConfig);
  registry.register(SHA512tDigest.factoryConfig);
  registry.register(TigerDigest.factoryConfig);
  registry.register(WhirlpoolDigest.factoryConfig);
  registry.register(SHAKEDigest.factoryConfig);
  registry.register(CSHAKEDigest.factoryConfig);
  registry.register(SM3Digest.factoryConfig);
}

void _registerECCurves(FactoryRegistry registry) {
  registry.register(ECCurve_brainpoolp160r1.factoryConfig);
  registry.register(ECCurve_brainpoolp160t1.factoryConfig);
  registry.register(ECCurve_brainpoolp192r1.factoryConfig);
  registry.register(ECCurve_brainpoolp192t1.factoryConfig);
  registry.register(ECCurve_brainpoolp224r1.factoryConfig);
  registry.register(ECCurve_brainpoolp224t1.factoryConfig);
  registry.register(ECCurve_brainpoolp256r1.factoryConfig);
  registry.register(ECCurve_brainpoolp256t1.factoryConfig);
  registry.register(ECCurve_brainpoolp320r1.factoryConfig);
  registry.register(ECCurve_brainpoolp320t1.factoryConfig);
  registry.register(ECCurve_brainpoolp384r1.factoryConfig);
  registry.register(ECCurve_brainpoolp384t1.factoryConfig);
  registry.register(ECCurve_brainpoolp512r1.factoryConfig);
  registry.register(ECCurve_brainpoolp512t1.factoryConfig);
  registry.register(ECCurve_gostr3410_2001_cryptopro_a.factoryConfig);
  registry.register(ECCurve_gostr3410_2001_cryptopro_b.factoryConfig);
  registry.register(ECCurve_gostr3410_2001_cryptopro_c.factoryConfig);
  registry.register(ECCurve_gostr3410_2001_cryptopro_xcha.factoryConfig);
  registry.register(ECCurve_gostr3410_2001_cryptopro_xchb.factoryConfig);
  registry.register(ECCurve_prime192v1.factoryConfig);
  registry.register(ECCurve_prime192v2.factoryConfig);
  registry.register(ECCurve_prime192v3.factoryConfig);
  registry.register(ECCurve_prime239v1.factoryConfig);
  registry.register(ECCurve_prime239v2.factoryConfig);
  registry.register(ECCurve_prime239v3.factoryConfig);
  registry.register(ECCurve_prime256v1.factoryConfig);
  registry.register(ECCurve_secp112r1.factoryConfig);
  registry.register(ECCurve_secp112r2.factoryConfig);
  registry.register(ECCurve_secp128r1.factoryConfig);
  registry.register(ECCurve_secp128r2.factoryConfig);
  registry.register(ECCurve_secp160k1.factoryConfig);
  registry.register(ECCurve_secp160r1.factoryConfig);
  registry.register(ECCurve_secp160r2.factoryConfig);
  registry.register(ECCurve_secp192k1.factoryConfig);
  registry.register(ECCurve_secp192r1.factoryConfig);
  registry.register(ECCurve_secp224k1.factoryConfig);
  registry.register(ECCurve_secp224r1.factoryConfig);
  registry.register(ECCurve_secp256k1.factoryConfig);
  registry.register(ECCurve_secp256r1.factoryConfig);
  registry.register(ECCurve_secp384r1.factoryConfig);
  registry.register(ECCurve_secp521r1.factoryConfig);
}

void _registerKeyDerivators(FactoryRegistry registry) {
  registry.register(PBKDF2KeyDerivator.factoryConfig);
  registry.register(Scrypt.factoryConfig);
  registry.register(HKDFKeyDerivator.factoryConfig);
  registry.register(Argon2BytesGenerator.factoryConfig);
  registry.register(ConcatKDFDerivator.factoryConfig);
  registry.register(ECDHKeyDerivator.factoryConfig);
  registry.register(ECDHKeyDerivator.factoryConfig);
  registry.register(ECDHKeyDerivator.factoryConfig);
}

void _registerKeyGenerators(FactoryRegistry registry) {
  registry.register(ECKeyGenerator.factoryConfig);
  registry.register(RSAKeyGenerator.factoryConfig);
}

void _registerPbeParameterGenerators(FactoryRegistry registry) {
  registry.register(PKCS12ParametersGenerator.factoryConfig);
  registry.register(PKCS5S1ParameterGenerator.factoryConfig);
}

void _registerMacs(FactoryRegistry registry) {
  registry.register(HMac.factoryConfig);
  registry.register(CMac.factoryConfig);
  registry.register(CBCBlockCipherMac.factoryConfig);
  registry.register(Poly1305.factoryConfig);
}

void _registerPaddedBlockCiphers(FactoryRegistry registry) {
  registry.register(PaddedBlockCipherImpl.factoryConfig);
}

void _registerPaddings(FactoryRegistry registry) {
  registry.register(PKCS7Padding.factoryConfig);
  registry.register(ISO7816d4Padding.factoryConfig);
}

void _registerRandoms(FactoryRegistry registry) {
  registry.register(AutoSeedBlockCtrRandom.factoryConfig);
  registry.register(BlockCtrRandom.factoryConfig);
  registry.register(FortunaRandom.factoryConfig);
}

void _registerSigners(FactoryRegistry registry) {
  registry.register(ECDSASigner.factoryConfig);
  registry.register(PSSSigner.factoryConfig);
  registry.register(RSASigner.factoryConfig);
}

void _registerStreamCiphers(FactoryRegistry registry) {
  registry.register(CTRStreamCipher.factoryConfig);
  registry.register(Salsa20Engine.factoryConfig);
  registry.register(ChaCha20Engine.factoryConfig);
  registry.register(ChaCha7539Engine.factoryConfig);
  registry.register(ChaCha20Poly1305.factoryConfig);
  registry.register(SICStreamCipher.factoryConfig);
  registry.register(EAX.factoryConfig);
  registry.register(RC4Engine.factoryConfig);
}

Changelog
=========

#### Version 3.7.3 (2023-04-14)

* PSSSigner requires only salt length to verify signature

#### Version 3.7.2 (2023-03-23)

* Removed duplicate oids

#### Version 3.7.1 (2023-03-21)

* Fix linter warnings
* Added new oids

#### Version 3.7.0 (2023-03-16)

* Added RC2
* Added RC4
* Added 3DES
* Added PKCS5S1ParameterGenerator
* Added PKCS12ParametersGenerator
* Added new OIDs
* Added new ASN1 models
* EAX
* Linting
* Fix to BasePadding

#### Version 3.6.2 (2022-09-09)

* Added OIDs 2.16.840.1.114412.1.1/digiCertOVCert and
* 2.23.140.1.2.2/organization-validated

#### Version 3.6.1 (2022-06-19)

* Added OID 2.5.4.26/registeredAddress
* Support ASN1 tag 164

#### Version 3.6.0 (2022-04-27)

* Added ECDH Basic Agreement
* Added ConcatKDF

#### Version 3.5.2 (2022-03-07)

* Added secp521r1 OID

#### Version 3.5.1 (2022-02-08)

* Added ASN1BMPString
* Added emailAddress OID

#### Version 3.5.0 (2021-12-30)

* RSAES-OAEP with SHA256 or any digest instance.
* Fixed bug in Keccak when updating with single bytes.

#### Version 3.4.0 (2021-11-09)

* Security update, fixed timing leaking in GCM implementation.
* Fixed bug in GCM counter.
* Added constant time gated xor.
* Removed more references to AESFastEngine.
* Security update, AESFastEngine is open to timing attacks, this has been deprecated and replaced with AESEngine.
* validateMac in BaseAEADBlockCipher is now constant time.

#### Version 3.4.0-rc2

* Security update, fixed timing leaking in GCM implementation.
* Fixed bug in GCM counter.
* Added constant time gated xor.
* Removed more references to AESFastEngine.

#### Version 3.4.0-rc1

* Security update, AESFastEngine is open to timing attacks, this has been deprecated and replaced with AESEngine.
* validateMac in BaseAEADBlockCipher is now constant time.

#### Version 3.3.5 (2021-10-27)

* New OID

#### Version 3.3.4 (2021-09-07)

* Performance update to scrypt
* SM3 implementation

#### Version 3.3.3 (2021-09-03)

* Argon2 in js environments.

#### Version 3.3.2 (2021-08-27)

* New OIDs

#### Version 3.3.1 (2021-08-18)

* Update to Register64 mul(...)
* New OID

#### Version 3.3.0 (2021-08-12)

* ECElGamal Encryptor and Decryptor

#### Version 3.2.0 (2021-07-29)

* Better ASN1 Dump
* New OIDs
* ASN1 Fixes

#### Version 3.2.0-rc0 (2021-07-05)

* Extended platform detection to supply entropy source, this works on nodejs.
* Critical fix to the examples:

  Where, ```xxx.nextInt(255)``` is used.

  Must be replaced with either ```.nextInt(256)``` or alternatively use:

  ```Platform.instance.platformEntropySource().getBytes(_how many_)``` to provide the seed.

#### Version 3.1.3 (2021-06-29)

* Add Argon2
* Fix to ASN1 parsing, calculation of start position.

#### Version 3.1.2 (2021-06-17)

* Critical fixed to Blake2b and additional test vectors see https://github.com/bcgit/pc-dart/pull/108

#### Version 3.1.1 (2021-06-04)

* Updated pubspec

#### Version 3.1.0 (2021-05-31)

* SRP support
* Readme correction
* not published

#### Version 3.0.1 (2021-03-24)

First non-nullable-by-default release

#### Version 3.0.0-nullsafety.2 (2021-02-05)

* Ports this library to non-nullable-by-default, a new feature in the Dart language
* This is a breaking change: client code (libraries and apps) will have to migrate as well to use new releases of this
  library.
* This library's existing APIs should not have changed functionally from Version 2.0.1; any such change should be
  reported at https://github.com/bcgit/pc-dart/issues
* The block cipher modes IGE and CCM were also added in this update.
* More info about migration: https://dart.dev/null-safety/migration-guide
* More info about null safety: https://dart.dev/null-safety

#### Version 3.0.0-nullsafety.1

* not published

#### Version 3.0.0-nullsafety.0

* not published

#### Version 2.0.1 (2021-01-16)

* Bug fix, ASN1Utils
* Removal of 'dart:io'
* RSAPrivateKey calculates the public exponent from the other values.

The previous BigInt handling functions in the util package now treat encoded BigInts as twos compliment numbers, this
may cause sudden unexpected failures if a number is suddenly negative. Users are advised to review their use of
decodeBigInt and encodeBigInt.

**utils.dart:**
- decodeBigInt is twos compliment.
- encodeBigInt is twos compliment and adds padding to preserve sign.
- encodeBigIntAsUnsigned writes the magnitude without any padding.
- decodeBigIntWithSign allows the specification of an arbitrary sign.
- Previous uses of decodeBigInt where the expectation is an unsigned integer have been updated with
  decodeBigIntWithSign(1, magnitude).

#### Version 2.0.0 (2020-10-02)

* No changes from 2.0.0-rc2

#### Version 2.0.0-rc2 (2020-09-25)

* Linter Fixes
* Updates to ASN1 API

#### Version 2.0.0-rc1 (2020-09-11) (Dart SDK version 2.1.1)

* Fixed OAEPEncoding and PKCS1Encoding to use provided output offset value.
* Fixed RSA block length and offset checks in RSAEngine.processBlock.
* Fixed RSASigner.verifySignature to return false when signature is bad.
* Add HKDF support (IETF RFC 5869)
* Add Poly1305, ChaCha20, ChaCha7539, AES-GCM, SHA3, Keccak, RSA/PSS
* Add CSHAKE, SHAKE
* Fixed randomly occurring bug with OAEP decoding.
* Added NormalizedECDSASigner that wraps ECDSASigner to guarantee an ecdsa signature in lower-s form. (Enforcement on verification supported).
* Reduce copies in CBC mode.
* Linter issues fixed.
* FixedSecureRandom to use seed only once.
* ASN1 - BOOLEAN, INTEGER, BIT_STRING, OCTET_STRING, NULL, OBJECT_IDENTIFIER, 
  ENUMERATED, UTF8_STRING, SEQUENCE, SET, PRINTABLE_STRING, IA5_STRING & UTC_TIME
* ASN1 Encoding - DER & BER
* RSA Keys - Private Key carries public key exponent, added publicExponent and privateExponent where necessary
  and deprecated single variable getters in for those values.

##### Thanks, Steven
 At this release the Point Castle Crypto API has been fully handed over to the 
 Legion of the Bouncy Castle Inc. Steven Roose, it is no small thing to single headedly 
 manage a cryptography API and your effort is rightfully respected by the Pointy Castle user 
 base. We would like to thank you for your trust in us to carry the project forward, and we
 wish you all the best!
  
  
#### Version 1.0.2 (2019-11-15)

* Add non-Keccak SHA3 support
* Add CMAC support ("AES/CMAC")
* Add ISO7816-4 padding support
* Fixes in CBCBlockCipherMac and CMac

#### Version 1.0.1 (2019-02-20)

* Add Blake2b support

#### Version 1.0.0 (2018-12-17) (Dart SDK version 2.0)

* Support Dart 2 and Strong Mode
* Migrate from `package:bignum.BigInteger` to `dart:core.BigInt`
* Remove Quiver and fixnum dependency
* OAEP encoding for block ciphers


#### Version 0.10.0 (2016-02-04) (Dart SDK version 0.14.0)

* First Pointy Castle release.

* Reorganised file structure.

* Completely new Registry implementation that dynamically loads imported implementations using reflection.
  It is explained in [this commit](https://github.com/PointyCastle/pointycastle/commit/2da75e5a8d7bdbf95d08329add9f13b9070b75d4).

* Migrated from unittest to test package.


### cipher releases

#### Version 0.8.0 (2014-??-??) (Dart SDK version ???)

* **[bug 80]** PaddedBlockCipher doesn't add padding when data length is a multiple of the block 
                size. This fix introduces a **BREAKING CHANGE** in PaddedBlockCipher specification.
                Read its API documentation to know about the changes.


#### Version 0.7.0 (2014-03-22) (Dart SDK version 1.3.0-dev.5.2)

* **[enh 15]** Implement stream cipher benchmarks.
* **[enh 64]** Benchmark and optimize digests.
* **[enh 74]** Make SHA-3 usable in terms of speed.

* **[bug 67]** Removed some unused code.
* **[bug 68]** Fix process() method of PaddedBlockCipher.
* **[bug 75]** Remove a registry dependency in the Scrypt algorithm.

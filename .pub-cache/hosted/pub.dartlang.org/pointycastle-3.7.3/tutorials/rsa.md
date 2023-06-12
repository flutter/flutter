# RSA

This article describes how to use the Pointy Castle package, an
implementation of cryptographic algorithms for use with the Dart
programming language, to use the RSA algorithm to:

- generate a key pair;
- create a signature and to verify a signature;
- encrypt and decrypt.

## Overview

The RSA (Rivest Shamir Adleman) algorithm is an asymmetric
cryptographic algorithm (also known as a public-key algorithm). It
uses two keys: a public key that is used for encrypting data and
verifying signatures, and a private key that is used for decrypting
data and creating signatures.

## Generating RSA key pairs

To generate a pair of RSA keys:

1. Obtain a `SecureRandom` number generator.
2. Instantiate an `RSAKeyGenrator` object.
3. Initialize the key generator object with the secure random number generator and other parameters.
4. Invoke the object's `generateKeyPair` method.

This is a function to generate an RSA key pair:

```dart
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import "package:pointycastle/export.dart";

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  // Create an RSA key generator and initialize it

  // final keyGen = KeyGenerator('RSA'); // Get using registry
  final keyGen = RSAKeyGenerator();

  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom));

  // Use the generator

  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types

  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

SecureRandom exampleSecureRandom() {

  final secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(
        Platform.instance.platformEntropySource().getBytes(32)));
  return secureRandom;
}

...

final pair = generateRSAkeyPair(exampleSecureRandom());
final public = pair.publicKey;
final private = pair.privateKey;
```

The key generator requires an instance of `SecureRandom`. The above
example shows the use of the Fortuna random number generator
(initialized with a less-secure random seed), but other methods can be
used too.

### Implementation

#### Using the registry

If using the registry, invoke the  `KeyGenerator` factory  with the algorithm name of "RSA".

```dart
final keyGen = KeyGenerator('RSA');
```

#### Without the registry

If the registry is not used, invoke the `RSAKeyGenerator` constructor.

```dart
final keyGen = RSAKeyGenerator();
```

### Initialize

The RSA key generator must be initialized with both an
`RSAKeyGeneratorParameters` and the `SecureRandom` number generator.
This is done by creating a `ParametersWithRandom` with the two, and
passing that to the key generator `init` method.

```dart
SecureRandom mySecureRandom = ...

final rsaParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
final paramsWithRnd = ParametersWithRandom(rsaParams, mySecureRandom);
keyGen.init(paramsWithRnd);
```

The `RSAKeyGeneratorParameters` has:

- the public exponent to use (must be an odd number)

- bit strength (e.g. 2048 or 4096)

- a certainty factor (the maximum number of rounds used by the
  Miller-Rabin primality test: larger numbers increase the probability
  a non-prime is correctly identified as being non-prime).

### Generation

Invoke the `generateKeyPair` method on the `RSAKeyGenrator` to
generate the key pair.

```dart
final pair = keyGen.generateKeyPair();

final myPublic = pair.publicKey as RSAPublicKey;
final myPrivate = pair.privateKey as RSAPrivateKey;
```

It returns an `AsymmetricKeyPair<PublicKey,PrivateKey>`, so the type
for the `publicKey` and `privateKey` members are the abstract classes
`PublicKey` and `PrivateKey`.  The members will need to be cast into
an `RSAPublicKey` and `RSAPrivateKey` to use them as RSA keys.

## Signing and verifying

To create a signature:

1. Obtain an `RSAPrivateKey`.

2. Instantiate an `RSASigner` with the desired `Digest` algorithm
   object and an algorithm identifier.

3. Initialize the object for signing with the private key.

4. Invoke the object's `generateSignature` method with the data
   being signed.

To verify a signature:

1. Obtain an `RSAPublicKey`.

2. Instantiate an `RSASigner` with the desired `Digest` algorithm
   object and algorithm identifier.

3. Initialize the object for verification with the public key.

4. Invoke the object's `verifySignature` method with the data
   that was supposedly signed and the signature.

The following functions creates a signature and verifies a signature
using SHA-256 as the digest algorithm:

```dart
import "package:pointycastle/export.dart";

Uint8List rsaSign(RSAPrivateKey privateKey, Uint8List dataToSign) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');

  // initialize with true, which means sign
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

  final sig = signer.generateSignature(dataToSign);

  return sig.bytes;
}

bool rsaVerify(
    RSAPublicKey publicKey, Uint8List signedData, Uint8List signature) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final sig = RSASignature(signature);

  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');

  // initialize with false, which means verify
  verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

  try {
    return verifier.verifySignature(signedData, sig);
  } on ArgumentError {
	return false; // for Pointy Castle 1.0.2 when signature has been modified
  }
}
```

### Standards supported

Pointy Castle implements PKCS #1 version 2.0 signature and
verification. Specifically, it implements the _RSASSA-PKCS1-v1_5_
signature scheme with appendix from section 8.1 of [RFC
2437](https://tools.ietf.org/html/rfc2437#section-8.1): which defines
how the digest algorithm identifier and digest value are both encoded, and
how that encoding is then signed using RSA.

### Implementation

#### Using the registry

If using the registry, invoke the `Signer` factory with the name of
the digest algorithm and signing algorithm (e.g. "SHA-256/RSA" or
"SHA-1/RSA").

```dart
final signer = Signer('SHA-256/RSA');
```

#### Without the registry

If the registry is not used, instantiate the `RSASigner` constructor,
passing in a digest implemenetation object and the identifier for that
digest algorithm.

```dart
final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
```

The second parameter identifies the signing algorithm being used, and
will be incorporated into the signature. It **must** be the correct
value corresponding to the algorithm of the first parameter.

Its value is the hexadecimal string representation of the DER encoding
of an ASN.1 Object Identifier (OID).

For example, "0609608648016503040201" is the value for
2.16.840.1.101.3.4.2.1, which is the OID for SHA-256 (specifically:
joint-iso-itu-t(2) country(16) us(840) organization(1) gov(101)
csor(3) nistAlgorithm(4) hashAlgs(2) sha256(1)). Note: that hex
encoding must includes a tag byte (0x06 as the first byte in this
example) and the length (0x09 in the second byte), as well as the
actual bytes representing the OID.

If the registry was used, the correct algorithm identifier is
automatically used. But when creating the objects directly, the
correct value must be found and entered into the code. The following
values were found in the source code for the `RSASigner` (the
_lib/signers/rsa_signer.dart_ file), in the `_DIGEST_IDENTIFIER_HEXES`
private member.

| Algorithm  | Object Identifier      | Hexadecimal encoding of DER |
|------------|------------------------|-----------------------------|
| MD2        | 1.2.840.113549.2.2     | 06082a864886f70d0202   |
| MD4        | 1.2.840.113549.2.4     | 06082a864886f70d0204   |
| MD5        | 1.2.840.113549.2.5     | 06082a864886f70d0205   |
| RIPEMD-128 | 1.3.36.3.2.2           | 06052b24030202         |
| RIPEMD-160 | 1.3.36.3.2.1           | 06052b24030201         |
| RIPEMD-256 | 1.3.36.3.2.3           | 06052b24030203         |
| SHA-1      | 1.3.14.3.2.26          | 06052b0e03021a         |
| SHA-224    | 2.16.840.1.101.3.4.2.4 | 0609608648016503040204 |
| SHA-256    | 2.16.840.1.101.3.4.2.1 | 0609608648016503040201 |
| SHA-384    | 2.16.840.1.101.3.4.2.2 | 0609608648016503040202 |
| SHA-512    | 2.16.840.1.101.3.4.2.3 | 0609608648016503040203 |

**Important:** both the signer and verifier must use the same value,
otherwise the signature will not validate.

### Initialize

Use the `init` method to initialize the signer. The first parameter
determines whether it can be used for signing, and the second
parameter is an RSA key.

For signing, use true and the private key.

```dart
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
```

For verifying, use false and the public key.

```dart
  verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
```

### Sign

To generate a signature, pass the data being signed to
the `generateSignature` method.

It returns an `RSASignature`, from which the bytes making up the
signature can be obtained using the `bytes` getter.

```dart
Uint8List dataToSign = ...

final sig = signer.generateSignature(dataToSign);

final signatureBytes = sig.bytes;
```

### Verify

To verify a signature, pass the data that was supposedly signed and
the signature (as a `RSASignature` object) to the `verifySignature`
method.

It returns true if the signature is valid, otherwise it should return
false.

```dart
final sig = RSASignature(signatureBytes);

final sigOk = verifier.verifySignature(signedData, sig);
```

Note: in Pointy Castle 1.0.2 and earlier, `verifySignature` returns
false if the data had been modified, but will usually throw an
`ArgumentError` if the signature had been modified. The exception
should be caught and treated as the signature failed to verify.

```dart
final sig = RSASignature(signatureBytes);

bool sigOk;
try {
  sigOk = verifier.verifySignature(signedData, sig);
} on ArgumentError {
  sigOk = false; // required for Pointy Castle 1.0.2 and earlier
}
```

## RSA encryption and decryption

To encrypt using RSA and an asymmetric block cipher:

1. Instantiate an `AsymmetricalBlockCipher` object with an `RSAEngine` object.
2. Initialize the asymmetrical block cipher for encryption and with the public key.
3. Invoke the object's `processBlock` method with the plaintext blocks
   to produce the ciphertext blocks.

To decrypt using RSA and an asymmetric block cipher:

1. Instantiate an AsymmetricalBlockCipher object with an RSAEngine object.
2. Initialize the asymmetrical block cipher for decryption and with the private key.
3. Invoke the object's `processBlock` method with the ciphertext blocks
   to produce the plaintext blocks.

For example,

```dart
import "package:pointycastle/export.dart";

Uint8List rsaEncrypt(RSAPublicKey myPublic, Uint8List dataToEncrypt) {
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(myPublic)); // true=encrypt

  return _processInBlocks(encryptor, dataToEncrypt);
}

Uint8List rsaDecrypt(RSAPrivateKey myPrivate, Uint8List cipherText) {
  final decryptor = OAEPEncoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(myPrivate)); // false=decrypt

  return _processInBlocks(decryptor, cipherText);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final numBlocks = input.length ~/ engine.inputBlockSize +
      ((input.length % engine.inputBlockSize != 0) ? 1 : 0);

  final output = Uint8List(numBlocks * engine.outputBlockSize);

  var inputOffset = 0;
  var outputOffset = 0;
  while (inputOffset < input.length) {
    final chunkSize = (inputOffset + engine.inputBlockSize <= input.length)
        ? engine.inputBlockSize
        : input.length - inputOffset;

    outputOffset += engine.processBlock(
        input, inputOffset, chunkSize, output, outputOffset);

    inputOffset += chunkSize;
  }

  return (output.length == outputOffset)
      ? output
      : output.sublist(0, outputOffset);
}
```

### Standards supported

Pointy Castle implements PKCS #1 version 2.0 encryption and
decryption. Specifically, it implements the RSAES-OAEP and
RSAES-PKCS1-v1_5 encryption schemes from section 7 of [RFC
2437](https://tools.ietf.org/html/rfc2437#section-7): which defines
how the plaintext data is encoded, and how that encoding is then
encrypted using RSA.

- RSA Encryption Scheme Optimal Asymmetric Encryption Padding
  (RSAES-OAEP) is implemented by the `OAEPEncoding` class.

- RSA Encryption Scheme from PKCS #1 version 1.5 (RSAES-PKCS1-v1_5),
  is implemented by the `PKCS1Encoding` class.

**Important:** RSAES-OAEP was changed in PKCS #1 version 2.1, in a way
that is not compatible with it in version 2.0. Therefore, Pointy
Castle's implementation of OAEP cannot interoperate with programs that
expect OAEP from PKCS #1 version 2.1 or later.

RFC 2437 says, "RSAES-OAEP is recommended for new applications;
RSAES-PKCS1-v1_5 is included only for compatibility with existing
applications, and is not recommended for new applications."

### Implementation

#### Using the registry

If using the registry, invoke the `AsymmetricBlockCipher` factory with
the name of the asymmetric block cipher: "RSA/OAEP" or "RSA/PKCS1".

```dart
final p = AsymmetricBlockCipher('RSA/OAEP');

// final p = AsymmetricBlockCipher('RSA/PKCS1);
```

#### Without the registry

If the registry is not used, invoke the constructor for
`PKCS1Encoding` or `OAEPEncoding`, providing an instance of the
`RSAEngine` as a parameter.

```dart
final p = OAEPEncoding(RSAEngine());

// final p = PKCS1Encoding(RSAEngine());
```

### Initialization

Use the `init` method to initialize the asymmetric block cipher. The
first parameter determines whether it is used for encryption, and the
second parameter is an RSA key.

For encrypting, use true and the public key.

```dart
p.init(true, PublicKeyParameter<RSAPublicKey>(myPublic));
```

For decrypting, use false and the private key.

```dart
p.init(false, PrivateKeyParameter<RSAPrivateKey>(myPrivate));
```

### Providing the data

#### Using processBlock

The data being encrypted/decrypted must be processed in blocks. Each
input block is processed into an output block.

The maximum size of a block can be obtained from the `inputBlockSize`
and `outputBlockSize` getters. They usually have different values, so
care must be taken to use the correct size when stepping through the
input and output.

The values are a _maximum_, so the input blocks can be smaller. But
it usually only makes sense for the final block to be smaller, and all
the other blocks to be the maximum size.

The `processBlock` method has five arguments:

- the `Uint8List` where the input block is read from
- offset into the input where the block starts
- length of the input block
- the output `Uint8List` where the calculated block will be written to
- offset into the output where the block starts writing from

It returns the number of bytes written. Which is especially important
when the last block is smaller than the maximum size. Always use the
returned output size to know how much of the output is valid.

#### Using process

The `process` method can also be used instead of `processBlock`. It is
simpler, because it creates and returns the output block. However, it
requires the input to be no larger than _inputBlockSize_. And the
_inputBlockSize_ depends on the bit-length of the key.

If `process` is used, the program needs to ensure the size of the data
and the bit-length of the key are both suitable.

#### Decryption errors

If the ciphertext cannot be decrypted, an `ArgumentError` is thrown.
The message associated with the `ArgumentError` can be ignored, since
it only describes the symptoms and not the cause: it does not help in
diagnosing why it failed.

Even if the ciphertext was successfully decrypted (i.e. no exception
was thrown), it does not guarantee the result is the same as the
plaintext that was encrypted. Encryption is designed to provides
confidentiality, and not integrity.  If data integrity is important,
additional mechanisms -- such as digests, HMACs or signatures --
should used in conjunction with encryption.

# AES-CBC with Pointy Castle

This article describes how to perform AES-CBC encryption and
decryption using the Pointy Castle package, which is an implementation
of cryptographic algorithms for use with the Dart programming
language.

## Overview

The Advanced Encryption Standard (AES) is a symmetric encryption
algorithm. As a symmetric algorithm, the same secret key is used to
encrypt and decrypt. It is also a block cipher algorithm, which means
the algorithm processes the data in fixed-size blocks.

Cipher Block Chaining (CBC) is a mode of operation where each block is
combined with the previous block before it is encrypted. Since the
first block doesn't have a previous block, it is combined with an
Initialization Vector (IV).

There are three algorithms in the AES family: AES-128, AES-192 and
AES-256, corresponding to the length of the keys in bits. For all the
algorithms, the block size is always 128-bits (16 bytes).

To encrypt using AES-CBC:

1. Instantiate the CBC block cipher class with the AES implementation class.
2. Initialize it with the key and Initialization Vector (IV) for encryption.
3. Process each block of the padded plaintext being encrypted.

To decrypt using AES-CBC:

1. Instantiate the CBC block cipher class with the AES implementation class.
2. Initialize it with the key and Initialization Vector (IV) for decryption.
3. Process each block of the ciphertext being decrypted.

These functions encrypts and decrypts using AES-CBC:

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import "package:pointycastle/export.dart";

Uint8List aesCbcEncrypt(
    Uint8List key, Uint8List iv, Uint8List paddedPlaintext) {
  assert([128, 192, 256].contains(key.length * 8));
  assert(128 == iv.length * 8);
  assert(128 == paddedPlaintext.length * 8);

  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = CBCBlockCipher(AESEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

  // Encrypt the plaintext block-by-block

  final cipherText = Uint8List(paddedPlaintext.length); // allocate space

  var offset = 0;
  while (offset < paddedPlaintext.length) {
    offset += cbc.processBlock(paddedPlaintext, offset, cipherText, offset);
  }
  assert(offset == paddedPlaintext.length);

  return cipherText;
}

Uint8List aesCbcDecrypt(Uint8List key, Uint8List iv, Uint8List cipherText) {
  assert([128, 192, 256].contains(key.length * 8));
  assert(128 == iv.length * 8);
  assert(128 == cipherText.length * 8);

  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = CBCBlockCipher(AESEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), iv)); // false=decrypt

  // Decrypt the cipherText block-by-block

  final paddedPlainText = Uint8List(cipherText.length); // allocate space

  var offset = 0;
  while (offset < cipherText.length) {
    offset += cbc.processBlock(cipherText, offset, paddedPlainText, offset);
  }
  assert(offset == cipherText.length);

  return paddedPlainText;
}
```

The _key_ must be exactly 128-bits, 192-bits or 256-bits (i.e. 16, 24
or 32 bytes). This is what determines whether AES-128, AES-192 or
AES-256 is being performed.

The _iv_ must be exactly 128-bits (16 bytes) long, which is the AES
block size.

The _paddedPlainText_ must be a multiple of the block size
(128-bits). If the data being encrypted is not the correct length, it
must be padded before it can be processed by AES. The implementations
of padding algorithms in Pointy Castle can be used for this.


## Details

### Implementation

#### Using the registry

If using the registry, invoke the `BlockCipher` factory with the name
of the encryption algorithm and block cipher mode: "AES/CBC".

```dart
final aesCbc = BlockCipher('AES/CBC');
```

#### Without the registry

If the registry is not used, invoke the block cipher's constructor,
passing in the AES implementation as a parameter.

```dart
final aesCbc = CBCBlockCipher(AESEngine());
```

### Initialize with key and IV

The first parameter determines if the object is used for encryption or
decryption.

Initialize for encryption:

```dart
aesCbc.init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt
```

Initialize for decryption:

```dart
aesCbc.init(false, ParametersWithIV(KeyParameter(key), iv)); // false=decrypt
```

### Processing each block

Invoke the `processBlock` method for each block, in order from the
first block to the last.

The method takes four parameters:

- Source `Uint8List` where the block comes from;
- Offset into that source where the block starts;
- Destination `Uint8List` to write the calculated block to;
- Offset into that destination where the output block will start.

Since each block is processed into another block, the destination
is the exact same size as the source.

For example,

```dart
final destination = Uint8List(source.length); // allocate space

var offset = 0;
while (offset < paddedPlaintext.length) {
  offset += cbc.processBlock(source, offset, destination, offset);
}
assert(offset == source.length);
```

The process is the same for encryption and decryption. With
encryption, the source is the padded plaintext. With decryption, the
source is the ciphertext (which doesn't need padding, since it is
guaranteed to be a multiple of the block size).

## External dependencies

There is no single standard for how the IV, ciphertext, and the other
necessary information (e.g. the key length) is stored or
transmitted. Different programs and standards do it differently.  To
be able to interoperate, the encrypting and decrypting programs must
agree to use the same method.

There is also no single standard for how the keys are obtained, the IV
is generated, or how the data is padded. Again, for interoperability,
the encrypting and decrypting programs must agree to use the same
method.

- The key is normally derived from a text passphrase, using a secure
  key derivation algorithm. While the key must be kept secret, the
  algorithm (with any parameters) used by the encrypting software must
  provided to or known by the decrypting software. One of those
  parameters is the size of the key, since that determines which AES
  algorithm is used.

- The Initialization Vector (IV) is normally randomly generated.  It
  must be stored or transmitted to the decrypting software, since the
  same IV must be used in decryption.

- The padding must be identified by the decrypting software, so it can
  remove it from the decrypted blocks.

It is important to securely derive the key and generate the IV. While
AES itself is secure, a system is only as secure as its weakest link.



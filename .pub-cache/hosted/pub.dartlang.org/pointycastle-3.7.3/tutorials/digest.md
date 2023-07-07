# Digests with Pointy Castle

This article describes how to calculate digests using the Pointy
Castle package, which is an implementation of cryptographic algorithms
for use with the Dart programming language.

## Overview

A digest is a value derived from a message. In all/most cases, the
digest is a small fixed size, regardless of the size of the
message. The digest value is produced by running an algorithm over the
message. Pointy Castle has implementations of a number of different
cryptographic digest algorithms (cryptographic hash algorithms or
cryptographic hash functions).  The term "hash" and "digest" are often
used interchangably. And in Pointy Castle, the _Digest_ class
represents the algorithm rather than the value that is produced.

To calculate a digest value:

1. Instantiate a class that implements the `Digest` abstract class.

2. Provide it the bytes to calculate the digest over. Either as a
   single `Uint8List`, or as fragments of `Uint8List` and bytes.

This program calculates the SHA-265 digest of text strings:

```dart
import 'dart:convert';
import 'dart:typed_data';

import "package:pointycastle/export.dart";

Uint8List sha256Digest(Uint8List dataToDigest) {
  final d = SHA256Digest();

  return d.process(dataToDigest);
}

void main(List<String> args) {
  final valuesToDigest = (args.isNotEmpty) ? args : ['Hello world!'];

  for (final data in valuesToDigest) {
    print('Data: "$data"');
    final hash = sha256Digest(utf8.encode(data) as Uint8List);
    print('SHA-256: $hash');
    print('SHA-256: ${bin2hex(hash)}'); // output in hexadecimal
  }
}
```

Note: these overview examples do not use the registry. For information
on how to use the registry, see the following details.

## Details

### Implementation

#### Using the registry

If using the registry, invoke the `Digest` factory with the name of
the digest algorithm.

```dart
final d = Digest("SHA-256");
```

Possible names include: "MD2", "MD4", "MD5", "RIPEMD-128",
"RIPEMD-160", "RIPEMD-256", "RIPEMD-320", "SHA-1", "SHA-224",
"SHA-256", "SHA-384", "SHA-512", "Tiger", "Whirlpool" and "SM3".

Note: these examples store the digest object in "d", since they could
be for any digest algorithm. But it is better to give the variable a
more meaningful name, such as "sha256".

Some digest implementations should not be instantiated using the
registry, because additional parameters need to be passed to their
constructors. These include: `Blake2bDigest`, `SHA3Digest` and
`SHA512tDigest`.

#### Without the registry

If the registery is not used, invoke the digest implementation's
constructor.

```dart
final d = SHA256Digest(); // SHA-256
```

All of the available digest classes of are listed as the implementers
of the
[Digest](https://pub.dev/documentation/pointycastle/latest/pointycastle.api/Digest-class.html)
abstract class.

### Providing the data to digest

#### Complete data

If all the data is available as a single sequence of bytes, pass it to
the `process` method to obtain the digest. The input data must be a
single `Uint8List`, and the calculated digest is returned in a new
`Uint8List`.

```dart
final Uint8List dataToDigest = ...

final hash = d.process(dataToDigest);
```

#### Progressive data

The data can also be provided as a sequence of individual bytes or
fragments of bytes.

To provide a single byte, use the `updateByte` method. It takes a single `int`.

To provide a fragment of bytes, use the `update` method. This method
takes a `Uint8List`, an offset to where the bytes start and the
length. Therefore, a sublist of the `Uint8List` can be provided, instead
of the entire `Uint8List`.

After all the data has been provided, use the `doFinal` method to obtain the
digest. The `doFinal` method takes two arguments: a `Uint8List` where it will
store the digest and an offset to where it will start.

The destination, after the offset position, must be large enough to
hold the digest.  The number of bytes required depends on the digest
algorithm being used, and can be found using the `digestSize` getter.

```dart
final chunk1 = utf8.encode('cellophane');
final chunk2 = utf8.encode('world');

d.updateByte(0x48); // 'H'
d.updateByte(0x65); // 'e'
d.update(chunk1, 1, 4);
d.updateByte(0x20); // ' '
d.update(chunk2, 0, chunk2.length);
d.updateByte(0x21); // '!'

final hash = Uint8List(d.digestSize); // create a destination for storing the hash

d.doFinal(hash, 0); // hash of "Hello world!"
```

#### Discarding provided data

When providing the data progressively, previously provided data can be
discarded by invoking the `reset` method.

Normally, reset does not need to be explicitly done because it is done
automatically by the `process` and `doFinal` methods.  This is only
required if previously provided data is abandoned.

```dart
final part1 = utf8.encode('Hello ');
final part2 = utf8.encode('world!');

final d = SHA256Digest();
final hash = Uint8List(d.digestSize);

// Without rest

d.update(part1, 0, part1.length);
d.update(part2, 0, part2.length);
d.doFinal(hash, 0); // hash of "Hello world!"

// With reset

d.update(part1, 0, part1.length);
d.reset();
d.update(part2, 0, part2.length);
d.doFinal(hash, 0); // hash of "world!"
```

Note: do not use the _resetState_ method that is available in the
SHA-family of implementations. The `reset` method will internally
invoke the _resetState_ method, as well as perform other operations to
reset the digester.


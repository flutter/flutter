# HMAC with Pointy Castle

This article describes how to calculate a HMAC using the Pointy Castle
package, which is an implementation of cryptographic algorithms for
use with the Dart programming language.

## Overview

A Hash-based Message Authentication Code (HMAC) is a type of Message
Authentication Code (MAC) that is calculate using a digest algorithm,
a secret key and the message data.

To calculate a HMAC:

1. Instantiate an implementation of `Hmac`, providing it the `Digest` implementation to use.
2. Initialize it with the HMAC key.
2. Provide it the bytes to calculate the HMAC over.

This program calculates the HMAC SHA-256:

```dart
import 'dart:convert';
import 'dart:typed_data';

import "package:pointycastle/export.dart";

Uint8List hmacSha256(Uint8List hmacKey, Uint8List data) {
  final hmac = HMac(SHA256Digest(), 64) // HMAC SHA-256: block must be 64 bytes
    ..init(KeyParameter(hmacKey));

  return hmac.process(data);
}

void main(List<String> args) {
  final key = utf8.encode(args[0]); // first argument is the key
  final data = utf8.encode(args[1]); // second argument is the data

  final hmacValue = hmacSha256(key, data);
  print('HMAC SHA-256: $hmacValue');
}
```

## Details

### Implementation

#### Using the registry

If using the registry, invoke the `Mac` factory with the name of the
HMAC algorithm. The name of the HMAC algorithm is the name of the
digest algorithm followed by "/HMAC" (e.g. "SHA-1/HMAC").

```dart
final hmac = Mac("SHA-256/HMAC");
```

#### Without the registry

If the registry is not used, invoke the `HMac` constructor, passing it
the digest implementation to use and a block length for that digest
algorithm.

```dart
final hmacSha256 = HMac(SHA256Digest(), 64); // for HMAC SHA-256, block length must be 64

final hmacSha1 = HMac(SHA1Digest(), 64); // for HMAC SHA-1, block length must be 64
final hmacSha512 = HMac(SHA512Digest(), 128); // for HMAC SHA-512, block length must be 128
final hmacMd2 = HMac(MD2Digest(), 16); // for HMAC MD2, block length must be 16
final hmacMd5 = HMac(MD5Digest(), 64); // for HMAC MD5, block length must be 64
```

**Warning:** the correct block length for the digest algorithm must be
used. Using a different value will produce an HMAC that is incorrect.
The registry automatically uses the correct values, which it gets from
the `_DIGEST_BLOCK_LENGTH` internal static member from the `HMac` class
in _lib/macs/hmac.dart_. But without the registry the correct value
must be found and explicitly provided.

### Set the key

Before processing the data, initialize the `HMac` object with the HMAC key
as a key parameter.

```dart
Uint8List keyBytes = ...

hmac.init(KeyParameter(keyBytes));
```

### Providing the data

This is similar to calculating a digest.

#### Complete data

If all the data is available as a single sequence of bytes, pass it to
the `process` method to obtain the HMAC. The input data must be a
`Uint8List`, and the calculated HMAC is returned in a new `Uint8List`.

```dart
final Uint8List data = ...

final hmacValue = hmac.process(data);
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
HMAC. The `doFinal` method takes two arguments: a `Uint8List` where it will
store the HMAC and an offset to where it will start.

The destination, after the offset position, must be large enough to
hold the HMAC.  The number of bytes required depends on the HMAC
algorithm being used, and can be found using the `macSize` getter.

```dart
final chunk1 = utf8.encode('cellophane');
final chunk2 = utf8.encode('world');

hmac.updateByte(0x48); // 'H'
hmac.updateByte(0x65); // 'e'
hmac.update(chunk1, 1, 4);
hmac.updateByte(0x20); // ' '
hmac.update(chunk2, 0, chunk2.length);
hmac.updateByte(0x21); // '!'

final hmacValue = Uint8List(hmac.macSize); // create a destination for storing the HMAC

hmac.doFinal(hmacValue, 0); // HMAC of "Hello world!"
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

final result = Uint8List(hmac.macSize);

// Without reset

hmac.update(part1, 0, part1.length);
hmac.update(part2, 0, part2.length);
hmac.doFinal(result, 0); // result contains HMAC of "Hello world!"

// With reset

hmac.update(part1, 0, part1.length);
hmac.reset(); // *** reset discards the data from part1
hmac.update(part2, 0, part2.length);
hmac.doFinal(result, 0); // result contains HMAC of "world!"
```

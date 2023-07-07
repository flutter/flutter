# Cryptographic hashing functions for Dart

A set of cryptographic hashing functions implemented in pure Dart

The following hashing algorithms are supported:

* SHA-1
* SHA-224
* SHA-256
* SHA-384
* SHA-512
* SHA-512/224
* SHA-512/256
* MD5
* HMAC (i.e. HMAC-MD5, HMAC-SHA1, HMAC-SHA256)

## Usage

### Digest on a single input

To hash a list of bytes, invoke the [`convert`][convert] method on the
[`sha1`][sha1-obj], [`sha256`][sha256-obj] or [`md5`][md5-obj]
objects.

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method

void main() {
  var bytes = utf8.encode("foobar"); // data being hashed

  var digest = sha1.convert(bytes);

  print("Digest as bytes: ${digest.bytes}");
  print("Digest as hex string: $digest");
}
```

### Digest on chunked input

If the input data is not available as a _single_ list of bytes, use
the chunked conversion approach.

Invoke the [`startChunkedConversion`][startChunkedConversion] method
to create a sink for the input data. On the sink, invoke the `add`
method for each chunk of input data, and invoke the `close` method
when all the chunks have been added. The digest can then be retrieved
from the `Sink<Digest>` used to create the input data sink.

```dart
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

void main() {
  var firstChunk = utf8.encode("foo");
  var secondChunk = utf8.encode("bar");

  var output = AccumulatorSink<Digest>();
  var input = sha1.startChunkedConversion(output);
  input.add(firstChunk);
  input.add(secondChunk); // call `add` for every chunk of input data
  input.close();
  var digest = output.events.single;

  print("Digest as bytes: ${digest.bytes}");
  print("Digest as hex string: $digest");
}
```

The above example uses the `AccumulatorSink` class that comes with the
_convert_ package. It is capable of accumulating multiple events, but
in this usage only a single `Digest` is added to it when the data sink's
`close` method is invoked.

### HMAC

Create an instance of the [`Hmac`][Hmac] class with the hash function
and secret key being used.  The object can then be used like the other
hash calculating objects.

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  var key = utf8.encode('p@ssw0rd');
  var bytes = utf8.encode("foobar");

  var hmacSha256 = Hmac(sha256, key); // HMAC-SHA256
  var digest = hmacSha256.convert(bytes);

  print("HMAC digest as bytes: ${digest.bytes}");
  print("HMAC digest as hex string: $digest");
}
```

## Disclaimer

Support for this library is given as _best effort_.

This library has not been reviewed or vetted by security professionals.

[convert]: https://pub.dev/documentation/crypto/latest/crypto/Hash/convert.html
[Digest]: https://pub.dev/documentation/crypto/latest/crypto/Digest-class.html
[Hmac]: https://pub.dev/documentation/crypto/latest/crypto/Hmac-class.html
[md5-obj]: https://pub.dev/documentation/crypto/latest/crypto/md5-constant.html
[sha1-obj]: https://pub.dev/documentation/crypto/latest/crypto/sha1-constant.html
[sha256-obj]: https://pub.dev/documentation/crypto/latest/crypto/sha256-constant.html
[startChunkedConversion]: https://pub.dev/documentation/crypto/latest/crypto/Hash/startChunkedConversion.html

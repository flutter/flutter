## 3.0.2

* Require Dart 2.14.0.
* Fix bug calculating hashes for content larger than 512MB when compiled to JS.

## 3.0.1

* Fix doc links in README.

## 3.0.0

* Stable release for null safety.

## 3.0.0-nullsafety.0

Null safety migration of this package.

* Adds SHA-2 512/224 and SHA-2 512/256 from FIPS 180-4

* Removes `newInstance` instance members on some classes
  and updates documentation.

## 2.1.5

* Improve example and package description to address package site maintenance
  suggestions.

## 2.1.4
  * BugFix: padding was incorrect for some SHA-512/328.

## 2.1.3
  * **Security vulnerability**: Fixed constant-time comparison in `Digest`.

## 2.1.2
  * Fix bug in SHA-2 384/512 blocksize.
  * Added HMAC-SHA-2 test vectors

## 2.1.1+1
  * Bump version number for publish mishap (spare file uploaded with `pub
    publish`).

## 2.1.1
  * Added a workaround for a bug in DDC (used in build_web_compilers 1.x).
  This bug is not present in DDK (used in build_web_compilers 2.x).

## 2.1.0
  * Added SHA384, and SHA512
  * Add Sha224 + Refactor
  * Support 32bit and 64bit operations for SHA384/51
  * Add conditional imports
  * De-listify 32bit allocations
  * Add sha monte tests for 224,256,384, and 512

## 2.0.5

* Changed the max message size instead to 0x3ffffffffffff, which is the largest
  portable value for both JS and the Dart VM.

## 2.0.4

* Made max message size a BigNum instead of an int so that dart2js can compile
  with crypto.

## 2.0.3

* Updated SDK version to 2.0.0-dev.17.0

## 2.0.2+1

* Fix SDK constraint.

## 2.0.2

* Prepare `HashSink` implementation for limiting integers to 64 bits in Dart
  language.

## 2.0.1

* Support `convert` 2.0.0.

## 2.0.0

**Note**: There are no APIs in 2.0.0 that weren't also in 0.9.2. Packages that
would use 2.0.0 as a lower bound should use 0.9.2 instead—for example, `crypto:
">=0.9.2 <3.0.0"`.

* `Hash` and `Hmac` no longer extend `ChunkedConverter`.

## 1.1.1

* Properly close sinks passed to `Hash.startChunkedConversion()` when
  `ByteConversionSink.close()` is called.

## 1.1.0

* `Hmac` and `Hash` now extend the new `ChunkedConverter` class from
  `dart:convert`.

* Fix all strong mode warnings.

## 1.0.0

* All APIs that were deprecated in 0.9.2 have been removed. No new APIs have
  been added. Packages that would use 1.0.0 as a lower bound should use 0.9.2
  instead—for example, `crypto: ">=0.9.2 <2.0.0"`.

## 0.9.2+1

* Avoid core library methods that don't work on dart2js.

## 0.9.2

* `Hash`, `MD5`, `SHA1`, and `SHA256` now implement `Converter`. They convert
  between `List<int>`s and the new `Digest` class, which represents a hash
  digest. The `Converter` APIs—`Hash.convert()` and
  `Hash.startChunkedConversion`—should be used in preference to the old APIs,
  which are now deprecated.

* `SHA1`, `SHA256`, and `HMAC` have been renamed to `Sha1`, `Sha256`, and
  `Hmac`, respectively. The old names still work, but are deprecated.

* Top-level `sha1`, `sha256`, and `md5` fields have been added to make it easier
  to use those hash algorithms without having to instantiate new instances.

* Hashing now works correctly for input sizes up to 2^64 bytes.

### Deprecations

* `Hash.add`, `Hash.close`, and `Hash.newInstance` are deprecated.
  `Hash.convert` should be used for hashing single values, and
  `Hash.startChunkedConversion` should be used for hashing streamed values.

* `SHA1` and `SHA256` are deprecated. Use the top-level `sha1` and `sha256`
  fields instead.

* While the `MD5` class is not deprecated, the `new MD5()` constructor is. Use
  the top-level `md5` field instead.

* `HMAC` is deprecated. Use `Hmac` instead.

* `Base64Codec`, `Base64Encoder`, `Base64Decoder`, `Base64EncoderSink`,
  `Base64DecoderSink`, and `BASE64` are deprecated. Use the Base64 APIs in
  `dart:convert` instead.

* `CryptoUtils` is deprecated. Use the Base64 APIs in `dart:convert` and the hex
  APIs in the `convert` package instead.

## 0.9.1

* Base64 convert returns an Uint8List
* Base64 codec and encoder can now take an encodePaddingCharacter
* Implement a Base64 codec similar to codecs in 'dart:convert'

## 0.9.0

* ChangeLog starts here.

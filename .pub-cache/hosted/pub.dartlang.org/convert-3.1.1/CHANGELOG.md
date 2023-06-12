## 3.1.1

- Require Dart 2.18
- Fix a number of comment references.

## 3.1.0

- Add a fixed-pattern DateTime formatter. See
  [#210](https://github.com/dart-lang/intl/issues/210) in package:intl.

## 3.0.2

- Fix bug in `CodePage` class. See issue
  [#47](https://github.com/dart-lang/convert/issues/47).

## 3.0.1

- Dependency clean-up.

## 3.0.0

- Stable null safety release.
- Added `CodePage` class for single-byte `Encoding` implementations.

## 2.1.1

- Fixed a DDC compilation regression for consumers using the Dart 1.x SDK that
  was introduced in `2.1.0`.

## 2.1.0

- Added an `IdentityCodec<T>` which implements `Codec<T,T>` for use as default
  value for in functions accepting an optional `Codec` as parameter.

## 2.0.2

- Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 2.0.1

- `PercentEncoder` no longer encodes digits. This follows the specified
  behavior.

## 2.0.0

**Note**: No new APIs have been added in 2.0.0. Packages that would use 2.0.0 as
a lower bound should use 1.0.0 instead—for example, `convert: ">=1.0.0 <3.0.0"`.

- `HexDecoder`, `HexEncoder`, `PercentDecoder`, and `PercentEncoder` no longer
  extend `ChunkedConverter`.

## 1.1.1

- Fix all strong-mode warnings.

## 1.1.0

- Add `AccumulatorSink`, `ByteAccumulatorSink`, and `StringAccumulatorSink`
  classes for providing synchronous access to the output of chunked converters.

## 1.0.1

- Small improvement in percent decoder efficiency.

## 1.0.0

- Initial version

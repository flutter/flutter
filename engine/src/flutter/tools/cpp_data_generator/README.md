# cpp_data_generator

Code generator for `@_NativeData` C++ structs and Dart FFI `Struct` encoders/decoders.

Reads `@_NativeData(symbol: '...')` constructors and `_NativeType<DartT, NativeT>` parameter types from a Dart library and generates:

1. A C++ header containing the corresponding standard-layout C++ structs, `present_mask` bitfields (`has_<field>()`), and `tonic::DartConverter` specializations.
2. A Dart `part of` file containing the packed `dart:ffi` `Struct` definitions (`_Packed<Type>` with `operator ==` and `hashCode`), encoded wrapper extension types (`_Encoded<Type>`), FFI encoders (`_encode<Type>Ffi`), and `toString` helpers (`_<type>ToString`).

## Usage

From the `engine/src/flutter` directory:

```shell
dart --enable-asserts ./tools/cpp_data_generator/bin/main.dart \
  --input lib/ui/text.dart \
  --cpp-out lib/ui/text/text_styles.g.h \
  --dart-out lib/ui/text_styles.g.dart
```

## Running Tests

```shell
dart test tools/cpp_data_generator
```

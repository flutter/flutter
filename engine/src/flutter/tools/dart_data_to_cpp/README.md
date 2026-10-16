# dart_data_to_cpp

Generates C++ classes and Dart glue code to streamline passing a `dart:ui` data class to C++.

`dart_data_to_cpp` inspects every constructor annotated with `@_NativeData(symbol: '...')` in a dart library and uses its formal parameters as the single source of truth to generate:

1. **A C++ header** defining the matching C++ data class and FFI converter so C++ functions can accept the type directly as a parameter.
2. **A Dart `part of` file** containing the FFI encoding glue that packs the Dart fields for C++.

The goal of this code generator is to hide the encoding / layout details so adding a new primitive field becomes trivial.

## Minimal Sample

### 1. Define `_NativeType` mappings and `@_NativeData` constructor

```dart
part 'text_styles.g.dart';

// Marks a constructor for C++ struct and Dart FFI code generation.
extension type const _NativeData._(String symbol) {
  const _NativeData({required this.symbol});
}

// Base type mapping a Dart type `DartT` to a `dart:ffi` `NativeType` (`NativeT`).
// Every parameter in a `@_NativeData` constructor must use a subtype of `_NativeType`.
extension type const _NativeType<DartT, NativeT extends NativeType>._unconstructable(DartT value) {}

// 1. Direct FFI primitives: encoded via `.value` and stored inline in the FFI `Struct`.
extension type const _NativeBool(bool value) implements _NativeType<bool, Bool> {}
extension type const _NativeDouble(double value) implements _NativeType<double, Double> {}

// 2. Enums: must use `_NativeEnum` without custom `encode`/`decode` methods.
//    The generator inspects the enum's value count at compile time and picks
//    the narrowest unsigned integer (`Uint8`, `Uint16`, or `Uint32`).
extension type const _NativeEnum<T extends Enum>(T value) implements _NativeType<T, NativeType> {}

// 3. Custom primitive-backed types: pack a Dart object into a fixed-width
//    integer or float in the FFI `Struct` by defining `encode()` and `static decode(raw)`.
extension type const _NativeFontWeight(FontWeight value)
    implements _NativeType<FontWeight, Uint16> {
  int encode() => value.value;
  static FontWeight decode(int raw) => FontWeight(raw);
}

// 4. Heap/GC-managed objects (`Handle`): cannot live inside a `dart:ffi` `Struct`,
//    so they are passed alongside the packed bytes and exposed as `Dart_Handle` in C++.
extension type const _NativeHandle<T extends Object>(T value) implements _NativeType<T, Handle> {}

// `Handle` types can optionally define `encode()` to convert the value before FFI.
extension type const _NativeLocale(Locale value) implements _NativeType<Locale, Handle> {
  String encode() => value.toString();
}

class StrutStyle {
  StrutStyle({
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    required bool forceStrutHeight,
  }) : this._(
         fontFamily: fontFamily == null ? null : .new(fontFamily),
         fontSize: fontSize == null ? null : .new(fontSize),
         fontWeight: fontWeight == null ? null : .new(fontWeight),
         fontStyle: fontStyle == null ? null : .new(fontStyle),
         forceStrutHeight: .new(forceStrutHeight),
       );

  // `symbol` specifies the generated C++ namespace and class name.
  @_NativeData(symbol: 'flutter::StrutStyle')
  StrutStyle._({
    // Nullable `Handle` parameter: passed as `Dart_Handle` to C++.
    // Must NOT specify a default value.
    this._fontFamily,
    // Nullable primitive parameters: packed into the FFI `Struct`.
    // MUST specify a default value to populate the struct slot when `null`.
    _NativeDouble? fontSize = const .new(14.0),
    _NativeFontWeight? fontWeight = const .new(.normal),
    _NativeEnum<FontStyle>? fontStyle = const .new(.normal),
    // Non-nullable primitive parameter: always present, so it must NOT
    // specify a default value and does not consume a bit in `present_mask`.
    required _NativeBool forceStrutHeight,
  }) : _encoded = _encodeStrutStyleFfi(
         fontFamily: _fontFamily,
         fontSize: fontSize,
         fontWeight: fontWeight,
         fontStyle: fontStyle,
         forceStrutHeight: forceStrutHeight,
       );

  // Holds the pre-encoded FFI payload (`_PackedStrutStyle`, its backing `Uint8List`,
  // and any encoded `Handle` values). Passed directly to `@Native` calls.
  // Primitive values can also be read back on demand via `_encoded.packed.<field>`.
  final _EncodedStrutStyle _encoded;
  final _NativeHandle<String>? _fontFamily;
}
```

### 2. Generated C++ Usage

Include the generated header and accept `const flutter::StrutStyle&` (or by value) in your FFI binding via `tonic::DartConverter`:

```cpp
void ParagraphBuilder::SetStrutStyle(const flutter::StrutStyle& strut) {
  // Nullable fields generate `has_<field>()` to check if Dart passed a non-null value:
  if (strut.has_font_size()) {
    // Explicitly provided by the caller: use `strut.font_size`.
  }

  // Or read primitive fields directly without branching: if Dart passed `null`,
  // `strut.font_weight` already holds the default value from `StrutStyle._`.
  uint16_t weight = strut.font_weight;

  // `Handle` fields are exposed as `Dart_Handle`:
  if (strut.has_font_family()) {
    // Unpack `strut.font_family` ...
  }
}
```

## Implementation Notes

### Hybrid Marshaling: Packed Primitives + Handles

`dart:ffi` `Struct`s allow C++ to read primitive fields at native speed with a single `std::memcpy`, but they cannot hold GC-managed Dart objects (`String`, `List`, `Paint`, etc.). `dart_data_to_cpp` splits parameters into two categories:
- **Primitives** (numbers, booleans, enums, and small value types with custom `encode`/`decode`) are packed into a single `Struct` backed by a `Uint8List`.
- **Handles** are stored alongside the byte buffer in a fixed-length Dart `List` and extracted into `Dart_Handle` fields on the C++ struct.

### Default Values and Nullability (`presentMask`)

Nullable primitive parameters are required to specify a default value in the `@_NativeData` constructor, while non-nullable and `Handle` parameters must not:
- **Presence tracking**: Every nullable parameter is assigned a bit in a synthesized `presentMask` field. When the caller passes a non-null value, its bit is set, which C++ can query via `has_<field>()`.
- **Deterministic struct slots**: Because a `Struct` occupies fixed memory, every primitive field must hold some value even when the Dart argument is `null`. Filling omitted primitive slots with their constructor default value serves two purposes:
  1. **Fast Dart equality and hashing**: Because `null` fields always contain a canonical default value in memory (with their `presentMask` bit cleared), two packed structs can be compared and hashed directly without branching on presence bits for every field.
  2. **Ergonomic C++ consumption**: C++ code that simply wants a fallback value when a property is omitted can read the struct field directly, while code that distinguishes "unspecified" from "explicitly set to the default" can check `has_<field>()`.
- **Why non-nullable and `Handle` parameters omit defaults**: Non-nullable parameters are always provided by the caller, and `Handle` parameters are passed as `null` (`Dart_Null()`) rather than occupying a primitive `Struct` slot, so default values on them would have no effect.

## Usage

From the `engine/src/flutter` directory:

```shell
dart --enable-asserts ./tools/dart_data_to_cpp/bin/main.dart \
  --input lib/ui/text.dart \
  --cpp-out lib/ui/text/text_styles.g.h \
  --dart-out lib/ui/text_styles.g.dart
```

## Running Tests

Tests don't run on CI.

```shell
dart --enable-asserts run tools/dart_data_to_cpp/test/dart_data_to_cpp_test.dart
```

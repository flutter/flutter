// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// [NativeType]'s subtypes represent a native type in C.
///
/// Not all [NativeType]'s subtypes are constructible in the Dart code. The
/// non-constructable subtypes serve purely as markers in type signatures.
abstract final class NativeType {}

/// A [NativeType] with a known size.
///
/// Sized native types can be used in [sizeOf] and [AllocatorAlloc.call].
@Since('3.4')
abstract final class SizedNativeType implements NativeType {}

/// [Opaque]'s subtypes represent opaque types in C.
///
/// [Opaque]'s subtypes are not constructible in the Dart code and serve purely
/// as markers in type signatures.
@Since('2.12')
abstract base class Opaque implements NativeType {}

/// [_NativeInteger]'s subtypes represent a native integer in C.
///
/// [_NativeInteger]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
abstract final class _NativeInteger implements SizedNativeType {}

/// [_NativeDouble]'s subtypes represent a native float or double in C.
///
/// [_NativeDouble]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
abstract final class _NativeDouble implements SizedNativeType {}

/// Represents a native signed 8 bit integer in C.
///
/// [Int8] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int8 implements _NativeInteger {
  const Int8();
}

/// Represents a native signed 16 bit integer in C.
///
/// [Int16] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int16 implements _NativeInteger {
  const Int16();
}

/// Represents a native signed 32 bit integer in C.
///
/// [Int32] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int32 implements _NativeInteger {
  const Int32();
}

/// Represents a native signed 64 bit integer in C.
///
/// [Int64] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int64 implements _NativeInteger {
  const Int64();
}

/// Represents a native unsigned 8 bit integer in C.
///
/// [Uint8] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Uint8 implements _NativeInteger {
  const Uint8();
}

/// Represents a native unsigned 16 bit integer in C.
///
/// [Uint16] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Uint16 implements _NativeInteger {
  const Uint16();
}

/// Represents a native unsigned 32 bit integer in C.
///
/// [Uint32] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Uint32 implements _NativeInteger {
  const Uint32();
}

/// Represents a native unsigned 64 bit integer in C.
///
/// [Uint64] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Uint64 implements _NativeInteger {
  const Uint64();
}

/// Represents a native 32 bit float in C.
///
/// [Float] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Float implements _NativeDouble {
  const Float();
}

/// Represents a native 64 bit double in C.
///
/// [Double] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Double implements _NativeDouble {
  const Double();
}

/// Represents a native bool in C.
///
/// [Bool] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
@Since('2.15')
final class Bool implements SizedNativeType {
  const Bool();
}

/// Represents a void type in C.
///
/// [Void] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
abstract final class Void implements NativeType {}

/// Represents `Dart_Handle` from `dart_api.h` in C.
///
/// [Handle] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
///
/// If [Handle] is part of the native signature of a [Native] external function
/// or [NativeFunctionPointer.asFunction], an API handle scope is created for
/// the duration of the FFI call. For more information on API scopes, refer to
/// the documentation on `Dart_EnterScope` in `dart_api.h`.
@Since('2.9')
abstract final class Handle implements NativeType {}

/// Represents a function type in C.
///
/// The return type and argument types in [T] must be a subtype of [NativeType].
///
/// [NativeFunction] is not constructible in the Dart code and serves purely as
/// marker in type signatures.
abstract final class NativeFunction<T extends Function> implements NativeType {}

/// The types of variadic arguments passed in C.
///
/// The signatures in [NativeFunction] need to specify the exact types of each
/// actual argument used in FFI calls.
///
/// For example take calling `printf` in C.
///
/// ```c
/// int printf(const char *format, ...);
///
/// void call_printf() {
///   int a = 4;
///   double b = 5.5;
///   const char* format = "...";
///   printf(format, a, b);
/// }
/// ```
///
/// To call `printf` directly from Dart with those two argument types, define
/// the native type as follows:
///
/// ```dart
/// /// `int printf(const char *format, ...)` with `int` and `double` as
/// /// varargs.
/// typedef NativePrintfIntDouble =
///     Int Function(Pointer<Char>, VarArgs<(Int, Double)>);
/// ```
///
/// Note the record type inside the `VarArgs` type argument.
///
/// If only a single variadic argument is passed, the record type must
/// contain a trailing comma:
///
/// ```dart continued
/// /// `int printf(const char *format, ...)` with only `int` as varargs.
/// typedef NativePrintfInt = Int Function(Pointer<Char>, VarArgs<(Int,)>);
/// ```
///
/// When a variadic function is called with different variadic argument types,
/// multiple bindings need to be created.
/// To avoid doing multiple [DynamicLibrary.lookup]s for the same symbol, the
/// pointer to the symbol can be cast:
///
/// ```dart continued
/// final dylib = DynamicLibrary.executable();
/// final printfPointer = dylib.lookup('printf');
/// final void Function(Pointer<Char>, int, double) printfIntDouble =
///     printfPointer.cast<NativeFunction<NativePrintfIntDouble>>().asFunction();
/// final void Function(Pointer<Char>, int) printfInt =
///     printfPointer.cast<NativeFunction<NativePrintfInt>>().asFunction();
/// ```
///
/// If no variadic argument is passed, the `VarArgs` must be passed with an
/// empty record type:
///
/// ```dart
/// /// `int printf(const char *format, ...)` with no varargs.
/// typedef NativePrintfNoVarArgs = Int Function(Pointer<Char>, VarArgs<()>);
/// ```
///
/// [VarArgs] must be the last parameter.
///
/// [VarArgs] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
@Since('3.0')
abstract final class VarArgs<T extends Record> implements NativeType {}

// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines [NativeType]s for common C types.
///
/// Many C types only define a minimal size in the C standard, but they are
/// consistent per [Abi]. Therefore we use [AbiSpecificInteger]s to define
/// these C types in this library.
part of dart.ffi;

/// The C `char` type.
///
/// Typically a signed or unsigned 8-bit integer.
/// For a guaranteed 8-bit integer, use [Int8] with the C `int8_t` type
/// or [Uint8] with the C `uint8_t` type.
/// For a specifically `signed` or `unsigned` `char`, use [SignedChar] or
/// [UnsignedChar].
///
/// The [Char] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint8(),
  Abi.androidArm64: Uint8(),
  Abi.androidIA32: Int8(),
  Abi.androidX64: Int8(),
  Abi.androidRiscv64: Uint8(),
  Abi.fuchsiaArm64: Uint8(),
  Abi.fuchsiaX64: Int8(),
  Abi.fuchsiaRiscv64: Uint8(),
  Abi.iosArm: Int8(),
  Abi.iosArm64: Int8(),
  Abi.iosX64: Int8(),
  Abi.linuxArm: Uint8(),
  Abi.linuxArm64: Uint8(),
  Abi.linuxIA32: Int8(),
  Abi.linuxX64: Int8(),
  Abi.linuxRiscv32: Uint8(),
  Abi.linuxRiscv64: Uint8(),
  Abi.macosArm64: Int8(),
  Abi.macosX64: Int8(),
  Abi.windowsArm64: Int8(),
  Abi.windowsIA32: Int8(),
  Abi.windowsX64: Int8(),
})
final class Char extends AbiSpecificInteger {
  const Char();
}

/// The C `signed char` type.
///
/// Typically a signed 8-bit integer.
/// For a guaranteed 8-bit integer, use [Int8] with the C `int8_t` type.
/// For an `unsigned char`, use [UnsignedChar].
///
/// The [SignedChar] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int8(),
  Abi.androidArm64: Int8(),
  Abi.androidIA32: Int8(),
  Abi.androidX64: Int8(),
  Abi.androidRiscv64: Int8(),
  Abi.fuchsiaArm64: Int8(),
  Abi.fuchsiaX64: Int8(),
  Abi.fuchsiaRiscv64: Int8(),
  Abi.iosArm: Int8(),
  Abi.iosArm64: Int8(),
  Abi.iosX64: Int8(),
  Abi.linuxArm: Int8(),
  Abi.linuxArm64: Int8(),
  Abi.linuxIA32: Int8(),
  Abi.linuxX64: Int8(),
  Abi.linuxRiscv32: Int8(),
  Abi.linuxRiscv64: Int8(),
  Abi.macosArm64: Int8(),
  Abi.macosX64: Int8(),
  Abi.windowsArm64: Int8(),
  Abi.windowsIA32: Int8(),
  Abi.windowsX64: Int8(),
})
final class SignedChar extends AbiSpecificInteger {
  const SignedChar();
}

/// The C `unsigned char` type.
///
/// Typically an unsigned 8-bit integer.
/// For a guaranteed 8-bit integer, use [Uint8] with the C `uint8_t` type.
/// For a `signed char`, use [SignedChar].
///
/// The [UnsignedChar] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint8(),
  Abi.androidArm64: Uint8(),
  Abi.androidIA32: Uint8(),
  Abi.androidX64: Uint8(),
  Abi.androidRiscv64: Uint8(),
  Abi.fuchsiaArm64: Uint8(),
  Abi.fuchsiaX64: Uint8(),
  Abi.fuchsiaRiscv64: Uint8(),
  Abi.iosArm: Uint8(),
  Abi.iosArm64: Uint8(),
  Abi.iosX64: Uint8(),
  Abi.linuxArm: Uint8(),
  Abi.linuxArm64: Uint8(),
  Abi.linuxIA32: Uint8(),
  Abi.linuxX64: Uint8(),
  Abi.linuxRiscv32: Uint8(),
  Abi.linuxRiscv64: Uint8(),
  Abi.macosArm64: Uint8(),
  Abi.macosX64: Uint8(),
  Abi.windowsArm64: Uint8(),
  Abi.windowsIA32: Uint8(),
  Abi.windowsX64: Uint8(),
})
final class UnsignedChar extends AbiSpecificInteger {
  const UnsignedChar();
}

/// The C `short` type.
///
/// Typically a signed 16-bit integer.
/// For a guaranteed 16-bit integer, use [Int16] with the C `int16_t` type.
/// For an `unsigned short`, use [UnsignedShort].
///
/// The [Short] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int16(),
  Abi.androidArm64: Int16(),
  Abi.androidIA32: Int16(),
  Abi.androidX64: Int16(),
  Abi.androidRiscv64: Int16(),
  Abi.fuchsiaArm64: Int16(),
  Abi.fuchsiaX64: Int16(),
  Abi.fuchsiaRiscv64: Int16(),
  Abi.iosArm: Int16(),
  Abi.iosArm64: Int16(),
  Abi.iosX64: Int16(),
  Abi.linuxArm: Int16(),
  Abi.linuxArm64: Int16(),
  Abi.linuxIA32: Int16(),
  Abi.linuxX64: Int16(),
  Abi.linuxRiscv32: Int16(),
  Abi.linuxRiscv64: Int16(),
  Abi.macosArm64: Int16(),
  Abi.macosX64: Int16(),
  Abi.windowsArm64: Int16(),
  Abi.windowsIA32: Int16(),
  Abi.windowsX64: Int16(),
})
final class Short extends AbiSpecificInteger {
  const Short();
}

/// The C `unsigned short` type.
///
/// Typically an unsigned 16-bit integer.
/// For a guaranteed 16-bit integer, use [Uint16] with the C `uint16_t` type.
/// For a signed `short`, use [Short].
///
/// The [UnsignedShort] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint16(),
  Abi.androidArm64: Uint16(),
  Abi.androidIA32: Uint16(),
  Abi.androidX64: Uint16(),
  Abi.androidRiscv64: Uint16(),
  Abi.fuchsiaArm64: Uint16(),
  Abi.fuchsiaX64: Uint16(),
  Abi.fuchsiaRiscv64: Uint16(),
  Abi.iosArm: Uint16(),
  Abi.iosArm64: Uint16(),
  Abi.iosX64: Uint16(),
  Abi.linuxArm: Uint16(),
  Abi.linuxArm64: Uint16(),
  Abi.linuxIA32: Uint16(),
  Abi.linuxX64: Uint16(),
  Abi.linuxRiscv32: Uint16(),
  Abi.linuxRiscv64: Uint16(),
  Abi.macosArm64: Uint16(),
  Abi.macosX64: Uint16(),
  Abi.windowsArm64: Uint16(),
  Abi.windowsIA32: Uint16(),
  Abi.windowsX64: Uint16(),
})
final class UnsignedShort extends AbiSpecificInteger {
  const UnsignedShort();
}

/// The C `int` type.
///
/// Typically a signed 32-bit integer.
/// For a guaranteed 32-bit integer, use [Int32] with the C `int32_t` type.
/// For an `unsigned int`, use [UnsignedInt].
///
/// The [Int] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int32(),
  Abi.androidArm64: Int32(),
  Abi.androidIA32: Int32(),
  Abi.androidX64: Int32(),
  Abi.androidRiscv64: Int32(),
  Abi.fuchsiaArm64: Int32(),
  Abi.fuchsiaX64: Int32(),
  Abi.fuchsiaRiscv64: Int32(),
  Abi.iosArm: Int32(),
  Abi.iosArm64: Int32(),
  Abi.iosX64: Int32(),
  Abi.linuxArm: Int32(),
  Abi.linuxArm64: Int32(),
  Abi.linuxIA32: Int32(),
  Abi.linuxX64: Int32(),
  Abi.linuxRiscv32: Int32(),
  Abi.linuxRiscv64: Int32(),
  Abi.macosArm64: Int32(),
  Abi.macosX64: Int32(),
  Abi.windowsArm64: Int32(),
  Abi.windowsIA32: Int32(),
  Abi.windowsX64: Int32(),
})
final class Int extends AbiSpecificInteger {
  const Int();
}

/// The C `unsigned int` type.
///
/// Typically an unsigned 32-bit integer.
/// For a guaranteed 32-bit integer, use [Uint32] with the C `uint32_t` type.
/// For a signed `int`, use [Int].
///
/// The [UnsignedInt] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint32(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint32(),
  Abi.androidRiscv64: Uint32(),
  Abi.fuchsiaArm64: Uint32(),
  Abi.fuchsiaX64: Uint32(),
  Abi.fuchsiaRiscv64: Uint32(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint32(),
  Abi.iosX64: Uint32(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint32(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint32(),
  Abi.linuxRiscv32: Uint32(),
  Abi.linuxRiscv64: Uint32(),
  Abi.macosArm64: Uint32(),
  Abi.macosX64: Uint32(),
  Abi.windowsArm64: Uint32(),
  Abi.windowsIA32: Uint32(),
  Abi.windowsX64: Uint32(),
})
final class UnsignedInt extends AbiSpecificInteger {
  const UnsignedInt();
}

/// The C `long int`, aka. `long`, type.
///
/// Typically a signed 32- or 64-bit integer.
/// For a guaranteed 32-bit integer, use [Int32] with the C `int32_t` type.
/// For a guaranteed 64-bit integer, use [Int64] with the C `int64_t` type.
/// For an `unsigned long`, use [UnsignedLong].
///
/// The [Long] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int32(),
  Abi.androidArm64: Int64(),
  Abi.androidIA32: Int32(),
  Abi.androidX64: Int64(),
  Abi.androidRiscv64: Int64(),
  Abi.fuchsiaArm64: Int64(),
  Abi.fuchsiaX64: Int64(),
  Abi.fuchsiaRiscv64: Int64(),
  Abi.iosArm: Int32(),
  Abi.iosArm64: Int64(),
  Abi.iosX64: Int64(),
  Abi.linuxArm: Int32(),
  Abi.linuxArm64: Int64(),
  Abi.linuxIA32: Int32(),
  Abi.linuxX64: Int64(),
  Abi.linuxRiscv32: Int32(),
  Abi.linuxRiscv64: Int64(),
  Abi.macosArm64: Int64(),
  Abi.macosX64: Int64(),
  Abi.windowsArm64: Int32(),
  Abi.windowsIA32: Int32(),
  Abi.windowsX64: Int32(),
})
final class Long extends AbiSpecificInteger {
  const Long();
}

/// The C `unsigned long int`, aka. `unsigned long`, type.
///
/// Typically an unsigned 32- or 64-bit integer.
/// For a guaranteed 32-bit integer, use [Uint32] with the C `uint32_t` type.
/// For a guaranteed 64-bit integer, use [Uint64] with the C `uint64_t` type.
/// For a signed `long`, use [Long].
///
/// The [UnsignedLong] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint64(),
  Abi.androidRiscv64: Uint64(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint64(),
  Abi.fuchsiaRiscv64: Uint64(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint64(),
  Abi.iosX64: Uint64(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint64(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint64(),
  Abi.linuxRiscv32: Uint32(),
  Abi.linuxRiscv64: Uint64(),
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint64(),
  Abi.windowsArm64: Uint32(),
  Abi.windowsIA32: Uint32(),
  Abi.windowsX64: Uint32(),
})
final class UnsignedLong extends AbiSpecificInteger {
  const UnsignedLong();
}

/// The C `long long` type.
///
/// Typically a signed 64-bit integer.
/// For a guaranteed 64-bit integer, use [Int64] with the C `int64_t` type.
/// For an `unsigned long long`, use [UnsignedLongLong].
///
/// The [LongLong] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int64(),
  Abi.androidArm64: Int64(),
  Abi.androidIA32: Int64(),
  Abi.androidX64: Int64(),
  Abi.androidRiscv64: Int64(),
  Abi.fuchsiaArm64: Int64(),
  Abi.fuchsiaX64: Int64(),
  Abi.fuchsiaRiscv64: Int64(),
  Abi.iosArm: Int64(),
  Abi.iosArm64: Int64(),
  Abi.iosX64: Int64(),
  Abi.linuxArm: Int64(),
  Abi.linuxArm64: Int64(),
  Abi.linuxIA32: Int64(),
  Abi.linuxX64: Int64(),
  Abi.linuxRiscv32: Int64(),
  Abi.linuxRiscv64: Int64(),
  Abi.macosArm64: Int64(),
  Abi.macosX64: Int64(),
  Abi.windowsArm64: Int64(),
  Abi.windowsIA32: Int64(),
  Abi.windowsX64: Int64(),
})
final class LongLong extends AbiSpecificInteger {
  const LongLong();
}

/// The C `unsigned long long` type.
///
/// Typically an unsigned 64-bit integer.
/// For a guaranteed 64-bit integer, use [Uint64] with the C `uint64_t` type.
/// For a signed `long long`, use [LongLong].
///
/// The [UnsignedLongLong] type is a native type, and should not be constructed
/// in Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint64(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint64(),
  Abi.androidX64: Uint64(),
  Abi.androidRiscv64: Uint64(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint64(),
  Abi.fuchsiaRiscv64: Uint64(),
  Abi.iosArm: Uint64(),
  Abi.iosArm64: Uint64(),
  Abi.iosX64: Uint64(),
  Abi.linuxArm: Uint64(),
  Abi.linuxArm64: Uint64(),
  Abi.linuxIA32: Uint64(),
  Abi.linuxX64: Uint64(),
  Abi.linuxRiscv32: Uint64(),
  Abi.linuxRiscv64: Uint64(),
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint64(),
  Abi.windowsArm64: Uint64(),
  Abi.windowsIA32: Uint64(),
  Abi.windowsX64: Uint64(),
})
final class UnsignedLongLong extends AbiSpecificInteger {
  const UnsignedLongLong();
}

/// The C `intptr_t` type.
///
/// The [IntPtr] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int32(),
  Abi.androidArm64: Int64(),
  Abi.androidIA32: Int32(),
  Abi.androidX64: Int64(),
  Abi.androidRiscv64: Int64(),
  Abi.fuchsiaArm64: Int64(),
  Abi.fuchsiaX64: Int64(),
  Abi.fuchsiaRiscv64: Int64(),
  Abi.iosArm: Int32(),
  Abi.iosArm64: Int64(),
  Abi.iosX64: Int64(),
  Abi.linuxArm: Int32(),
  Abi.linuxArm64: Int64(),
  Abi.linuxIA32: Int32(),
  Abi.linuxX64: Int64(),
  Abi.linuxRiscv32: Int32(),
  Abi.linuxRiscv64: Int64(),
  Abi.macosArm64: Int64(),
  Abi.macosX64: Int64(),
  Abi.windowsArm64: Int64(),
  Abi.windowsIA32: Int32(),
  Abi.windowsX64: Int64(),
})
final class IntPtr extends AbiSpecificInteger {
  const IntPtr();
}

/// The C `uintptr_t` type.
///
/// The [UintPtr] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint64(),
  Abi.androidRiscv64: Uint64(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint64(),
  Abi.fuchsiaRiscv64: Uint64(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint64(),
  Abi.iosX64: Uint64(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint64(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint64(),
  Abi.linuxRiscv32: Uint32(),
  Abi.linuxRiscv64: Uint64(),
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint64(),
  Abi.windowsArm64: Uint64(),
  Abi.windowsIA32: Uint32(),
  Abi.windowsX64: Uint64(),
})
final class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}

/// The C `size_t` type.
///
/// The [Size] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint64(),
  Abi.androidRiscv64: Uint64(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint64(),
  Abi.fuchsiaRiscv64: Uint64(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint64(),
  Abi.iosX64: Uint64(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint64(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint64(),
  Abi.linuxRiscv32: Uint32(),
  Abi.linuxRiscv64: Uint64(),
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint64(),
  Abi.windowsArm64: Uint64(),
  Abi.windowsIA32: Uint32(),
  Abi.windowsX64: Uint64(),
})
final class Size extends AbiSpecificInteger {
  const Size();
}

/// The C `wchar_t` type.
///
/// The signedness of `wchar_t` is undefined in C. Here, it is exposed as the
/// defaults on the tested [Abi]s.
///
/// The [WChar] type is a native type, and should not be constructed in
/// Dart code.
/// It occurs only in native type signatures and as annotation on [Struct] and
/// [Union] fields.
@Since('2.17')
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint32(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint32(),
  Abi.androidRiscv64: Int32(),
  Abi.fuchsiaArm64: Uint32(),
  Abi.fuchsiaX64: Int32(),
  Abi.fuchsiaRiscv64: Int32(),
  Abi.iosArm: Int32(),
  Abi.iosArm64: Int32(),
  Abi.iosX64: Int32(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint32(),
  Abi.linuxIA32: Int32(),
  Abi.linuxX64: Int32(),
  Abi.linuxRiscv32: Int32(),
  Abi.linuxRiscv64: Int32(),
  Abi.macosArm64: Int32(),
  Abi.macosX64: Int32(),
  Abi.windowsArm64: Uint16(),
  Abi.windowsIA32: Uint16(),
  Abi.windowsX64: Uint16(),
})
final class WChar extends AbiSpecificInteger {
  const WChar();
}

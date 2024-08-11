// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// The supertype of all [Abi]-specific integer types.
///
/// [Abi]-specific integers should extend this class and annotate it with
/// [AbiSpecificIntegerMapping] to declare the integer size and signedness
/// for [Abi.values].
///
/// For example:
///
/// ```
/// /// The C `uintptr_t` type.
/// ///
/// /// The [UintPtr] type is a native type, and should not be constructed in
/// /// Dart code.
/// /// It occurs only in native type signatures and as annotation on [Struct]
/// /// and [Union] fields.
/// @AbiSpecificIntegerMapping({
///   Abi.androidArm: Uint32(),
///   Abi.androidArm64: Uint64(),
///   Abi.androidIA32: Uint32(),
///   Abi.androidX64: Uint64(),
///   Abi.androidRiscv64: Uint64(),
///   Abi.fuchsiaArm64: Uint64(),
///   Abi.fuchsiaX64: Uint64(),
///   Abi.fuchsiaRiscv64: Uint64(),
///   Abi.iosArm: Uint32(),
///   Abi.iosArm64: Uint64(),
///   Abi.linuxArm: Uint32(),
///   Abi.linuxArm64: Uint64(),
///   Abi.linuxIA32: Uint32(),
///   Abi.linuxX64: Uint64(),
///   Abi.linuxRiscv32: Uint32(),
///   Abi.linuxRiscv64: Uint64(),
///   Abi.macosArm64: Uint64(),
///   Abi.macosX64: Uint64(),
///   Abi.windowsIA32: Uint32(),
///   Abi.windowsX64: Uint64(),
/// })
/// final class UintPtr extends AbiSpecificInteger {
///   const UintPtr();
/// }
/// ```
@Since('2.16')
base class AbiSpecificInteger implements SizedNativeType {
  const AbiSpecificInteger();
}

/// Mapping for a subtype of [AbiSpecificInteger].
///
/// See documentation on [AbiSpecificInteger].
@Since('2.16')
final class AbiSpecificIntegerMapping {
  final Map<Abi, NativeType> mapping;

  const AbiSpecificIntegerMapping(this.mapping);
}

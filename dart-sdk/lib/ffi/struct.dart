// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// A memory range, represented by its starting address.
///
/// Shared supertype of the FFI compound [Struct], [Union], and [Array] types.
///
/// This class is not abstract because instances can be created as an anonymous
/// representation of a memory area, with no structure on top. (In particular,
/// during the transformation of `.address` in FFI leaf calls.)
@pragma("wasm:entry-point")
final class _Compound implements NativeType {
  /// The underlying [TypedData] or [Pointer] that a subtype uses.
  @pragma("vm:entry-point")
  final Object _typedDataBase;

  /// Offset in bytes into [_typedDataBase].
  @pragma("vm:entry-point")
  final int _offsetInBytes;

  external _Compound._();

  _Compound._fromTypedDataBase(
    this._typedDataBase,
    this._offsetInBytes,
  );

  /// Constructs a view on [typedData].
  ///
  /// The length in bytes of [typedData] must at least be [sizeInBytes].
  _Compound._fromTypedData(
    TypedData typedData,
    int offset,
    int sizeInBytes,
  )   : _typedDataBase = typedData,
        _offsetInBytes = typedData.elementSizeInBytes * offset {
    if (typedData.lengthInBytes <
        typedData.elementSizeInBytes * offset + sizeInBytes) {
      throw RangeError.range(
        typedData.lengthInBytes,
        sizeInBytes + typedData.elementSizeInBytes * offset,
        null,
        'typedData.lengthInBytes',
        'The typed list is not large enough',
      );
    }
  }
}

/// The supertype of all FFI struct types.
///
/// FFI struct types should extend this class and declare fields corresponding
/// to the underlying native structure.
///
/// Field declarations in a [Struct] subclass declaration are automatically
/// given a setter and getter implementation which accesses the native struct's
/// field in memory.
///
/// All field declarations in a [Struct] subclass declaration must either have
/// type [int] or [double] and be annotated with a [NativeType] representing the
/// native type, or must be of type [Pointer], [Array] or a subtype of [Struct]
/// or [Union]. For example:
///
/// ```c
/// typedef struct {
///  int a;
///  float b;
///  void* c;
/// } my_struct;
/// ```
///
/// ```dart
/// final class MyStruct extends Struct {
///   @Int32()
///   external int a;
///
///   @Float()
///   external double b;
///
///   external Pointer<Void> c;
/// }
/// ```
///
/// The field declarations of a [Struct] subclass *must* be marked `external`. A
/// struct subclass points directly into a location of native memory ([Pointer])
/// or Dart memory ([TypedData]), and the external field's getter and setter
/// implementations directly read and write bytes at appropriate offsets from
/// that location. This does not allow for non-native fields to also exist.
///
/// An instance of a struct subclass cannot be created with a generative
/// constructor. Instead, an instance can be created by [StructPointer.ref],
/// [Struct.create], FFI call return values, FFI callback arguments,
/// [StructArray], and accessing [Struct] fields. To create an instance backed
/// by native memory, use [StructPointer.ref]. To create an instance backed by
/// Dart memory, use [Struct.create].
@Since('2.12')
abstract base class Struct extends _Compound implements SizedNativeType {
  /// Construct a reference to the [nullptr].
  ///
  /// Use [StructPointer]'s `.ref` to gain references to native memory backed
  /// structs.
  Struct() : super._();

  /// Creates a struct view of bytes in [typedData].
  ///
  /// The created instance of the struct subclass will then be backed by the
  /// bytes at [TypedData.offsetInBytes] plus [offset] times
  /// [TypedData.elementSizeInBytes]. That is, the getters and setters of the
  /// external instance variables declared by the subclass, will read an write
  /// their values from the bytes of the [TypedData.buffer] of [typedData],
  /// starting at [TypedData.offsetInBytes] plus [offset] times
  /// [TypedData.elementSizeInBytes]. The [TypedData.lengthInBytes] of
  /// [typedData] *must* be sufficient to contain the [sizeOf] of the struct
  /// subclass. _It doesn't matter whether the [typedData] is, for example, a
  /// [Uint8List], a [Float64List], or any other [TypedData], it's only treated
  /// as a view into a [ByteBuffer], through its [TypedData.buffer],
  /// [TypedData.offsetInBytes] and [TypedData.lengthInBytes]._
  ///
  /// If [typedData] is omitted, a fresh [ByteBuffer], with precisely enough
  /// bytes for the [sizeOf] of the created struct, is allocated on the Dart
  /// heap, and used as memory to store the struct fields.
  ///
  /// If [offset] is provided, the indexing into [typedData] is offset by
  /// [offset] times [TypedData.elementSizeInBytes].
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// final class Point extends Struct {
  ///   @Double()
  ///   external double x;
  ///
  ///   @Double()
  ///   external double y;
  ///
  ///   /// Creates Dart managed memory to hold a `Point` and returns the
  ///   /// `Point` view on it.
  ///   factory Point(double x, double y) {
  ///     return Struct.create()
  ///       ..x = x
  ///       ..y = y;
  ///   }
  ///
  ///   /// Creates a [Point] view on [typedData].
  ///   factory Point.fromTypedData(TypedData typedData) {
  ///     return Struct.create(typedData);
  ///   }
  /// }
  /// ```
  ///
  /// To create a struct object from a [Pointer], use [StructPointer.ref].
  @Since('3.4')
  external static T create<T extends Struct>([TypedData typedData, int offset]);

  /// Creates a view on a [TypedData] or [Pointer].
  ///
  /// Used in [StructPointer.ref], FFI calls, and FFI callbacks.
  Struct._fromTypedDataBase(
    super._typedDataBase,
    super._offsetInBytes,
  ) : super._fromTypedDataBase();

  /// Creates a view on [typedData].
  ///
  /// The length in bytes of [typedData] must at least be [sizeInBytes].
  ///
  /// Used in the `external` public constructor of [Struct].
  Struct._fromTypedData(
    super.typedData,
    super.offset,
    super.sizeInBytes,
  ) : super._fromTypedData();
}

/// Annotation to specify on `Struct` subtypes to indicate that its members
/// need to be packed.
///
/// Valid values for [memberAlignment] are 1, 2, 4, 8, and 16.
@Since('2.13')
final class Packed {
  final int memberAlignment;

  const Packed(this.memberAlignment);
}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.typed_data;

/// A read-only view of a [ByteBuffer].
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableByteBufferView.
@Deprecated('No replacement')
abstract final class UnmodifiableByteBufferView implements ByteBuffer {
  external factory UnmodifiableByteBufferView(ByteBuffer data);
}

/// A read-only view of a [ByteData].
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableByteDataView.
@Deprecated('Use ByteData.asUnmodifiableView() instead')
abstract final class UnmodifiableByteDataView implements ByteData {
  external factory UnmodifiableByteDataView(ByteData data);
}

/// View of a [Uint8List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint8ListView.
@Deprecated('Use Uint8List.asUnmodifiableView() instead')
abstract final class UnmodifiableUint8ListView implements Uint8List {
  external factory UnmodifiableUint8ListView(Uint8List list);
}

/// View of a [Int8List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt8ListView.
@Deprecated('Use Int8List.asUnmodifiableView() instead')
abstract final class UnmodifiableInt8ListView implements Int8List {
  external factory UnmodifiableInt8ListView(Int8List list);
}

/// View of a [Uint8ClampedList] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint8ClampedListView.
@Deprecated('Use Uint8ClampedList.asUnmodifiableView() instead')
abstract final class UnmodifiableUint8ClampedListView
    implements Uint8ClampedList {
  external factory UnmodifiableUint8ClampedListView(Uint8ClampedList list);
}

/// View of a [Uint16List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint16ListView.
@Deprecated('Use Uint16List.asUnmodifiableView() instead')
abstract final class UnmodifiableUint16ListView implements Uint16List {
  external factory UnmodifiableUint16ListView(Uint16List list);
}

/// View of a [Int16List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt16ListView.
@Deprecated('Use Int16List.asUnmodifiableView() instead')
abstract final class UnmodifiableInt16ListView implements Int16List {
  external factory UnmodifiableInt16ListView(Int16List list);
}

/// View of a [Uint32List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint32ListView.
@Deprecated('Use Uint32List.asUnmodifiableView() instead')
abstract final class UnmodifiableUint32ListView implements Uint32List {
  external factory UnmodifiableUint32ListView(Uint32List list);
}

/// View of a [Int32List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt32ListView.
@Deprecated('Use Int32List.asUnmodifiableView() instead')
abstract final class UnmodifiableInt32ListView implements Int32List {
  external factory UnmodifiableInt32ListView(Int32List list);
}

/// View of a [Uint64List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint64ListView.
@Deprecated('Use Uint64List.asUnmodifiableView() instead')
abstract final class UnmodifiableUint64ListView implements Uint64List {
  external factory UnmodifiableUint64ListView(Uint64List list);
}

/// View of a [Int64List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt64ListView.
@Deprecated('Use Int64List.asUnmodifiableView() instead')
abstract final class UnmodifiableInt64ListView implements Int64List {
  external factory UnmodifiableInt64ListView(Int64List list);
}

/// View of a [Int32x4List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt32x4ListView.
@Deprecated('Use Int32x4List.asUnmodifiableView() instead')
abstract final class UnmodifiableInt32x4ListView implements Int32x4List {
  external factory UnmodifiableInt32x4ListView(Int32x4List list);
}

/// View of a [Float32x4List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat32x4ListView.
@Deprecated('Use Float32x4List.asUnmodifiableView() instead')
abstract final class UnmodifiableFloat32x4ListView implements Float32x4List {
  external factory UnmodifiableFloat32x4ListView(Float32x4List list);
}

/// View of a [Float64x2List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat64x2ListView.
@Deprecated('Use Float64x2List.asUnmodifiableView() instead')
abstract final class UnmodifiableFloat64x2ListView implements Float64x2List {
  external factory UnmodifiableFloat64x2ListView(Float64x2List list);
}

/// View of a [Float32List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat32ListView.
@Deprecated('Use Float32List.asUnmodifiableView() instead')
abstract final class UnmodifiableFloat32ListView implements Float32List {
  external factory UnmodifiableFloat32ListView(Float32List list);
}

/// View of a [Float64List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat64ListView.
@Deprecated('Use Float64List.asUnmodifiableView() instead')
abstract final class UnmodifiableFloat64ListView implements Float64List {
  external factory UnmodifiableFloat64ListView(Float64List list);
}

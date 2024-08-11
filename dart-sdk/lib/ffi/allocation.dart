// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

// Examples can assume:
// late Allocator allocator;
// late Allocator calloc;

/// Manages memory on the native heap.
///
/// When allocating memory, prefer calling this allocator directly as a
/// function (see [AllocatorAlloc.call] for details).
///
/// This interface provides only the [allocate] method to allocate a block of
/// bytes, and the [free] method to release such a block again.
/// Implementations only need to provide those two methods.
/// The [AllocatorAlloc.call] extension method is defined in terms of those
/// lower-level operations.
///
/// An example of an allocator wrapping another to count the number of
/// allocations:
///
/// ```dart
/// class CountingAllocator implements Allocator {
///   final Allocator _wrappedAllocator;
///   int _totalAllocations = 0;
///   int _nonFreedAllocations = 0;
///
///   CountingAllocator([Allocator? allocator])
///       : _wrappedAllocator = allocator ?? calloc;
///
///   int get totalAllocations => _totalAllocations;
///
///   int get nonFreedAllocations => _nonFreedAllocations;
///
///   @override
///   Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
///     final result =
///         _wrappedAllocator.allocate<T>(byteCount, alignment: alignment);
///     _totalAllocations++;
///     _nonFreedAllocations++;
///     return result;
///   }
///
///   @override
///   void free(Pointer<NativeType> pointer) {
///     _wrappedAllocator.free(pointer);
///     _nonFreedAllocations--;
///   }
/// }
/// ```
@Since('2.12')
abstract class Allocator {
  /// This interface is meant to be implemented, not extended or mixed in.
  Allocator._() {
    throw UnsupportedError("Cannot be instantiated");
  }

  /// Allocates [byteCount] bytes of memory on the native heap.
  ///
  /// If [alignment] is provided, the allocated memory will be at least aligned
  /// to [alignment] bytes.
  ///
  /// To allocate a multiple of `sizeOf<T>()` bytes, call the allocator directly
  /// as a function: `allocator<T>(count)` (see [AllocatorAlloc.call] for
  /// details).
  ///
  /// ```dart
  /// // This allocates two bytes. If you intended two Int32's, this is an
  /// // error.
  /// allocator.allocate<Int32>(2);
  ///
  /// // This allocates eight bytes, which is enough space for two Int32's.
  /// // However, this is not the idiomatic way.
  /// allocator.allocate<Int32>(sizeOf<Int32>() * 2);
  ///
  /// // The idiomatic way to allocate space for two Int32 is to call the
  /// // allocator directly as a function.
  /// allocator<Int32>(2);
  /// ```
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment});

  /// Releases memory allocated on the native heap.
  ///
  /// Throws an [ArgumentError] if the memory pointed to by [pointer] cannot be
  /// freed.
  void free(Pointer pointer);
}

/// Extension on [Allocator] to provide allocation with [NativeType].
@Since('2.12')
extension AllocatorAlloc on Allocator {
  /// Allocates `sizeOf<T>() * count` bytes of memory using [allocate].
  ///
  /// ```dart
  /// // This allocates eight bytes, which is enough space for two Int32's.
  /// allocator<Int32>(2);
  /// ```
  ///
  /// This extension method must be invoked with a compile-time constant [T].
  ///
  /// To allocate a specific number of bytes, not just a multiple of
  /// `sizeOf<T>()`, use [allocate].
  /// To allocate with a non constant [T], use [allocate].
  /// Prefer [call] for normal use, and use [allocate] for implementing an
  /// [Allocator] in terms of other allocators.
  external Pointer<T> call<T extends SizedNativeType>([int count = 1]);
}

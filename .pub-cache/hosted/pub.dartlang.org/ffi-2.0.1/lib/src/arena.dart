// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Explicit arena used for managing resources.

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// An [Allocator] which frees all allocations at the same time.
///
/// The arena allows you to allocate heap memory, but ignores calls to [free].
/// Instead you call [releaseAll] to release all the allocations at the same
/// time.
///
/// Also allows other resources to be associated with the arena, through the
/// [using] method, to have a release function called for them when the arena
/// is released.
///
/// An [Allocator] can be provided to do the actual allocation and freeing.
/// Defaults to using [calloc].
class Arena implements Allocator {
  /// The [Allocator] used for allocation and freeing.
  final Allocator _wrappedAllocator;

  /// Native memory under management by this [Arena].
  final List<Pointer<NativeType>> _managedMemoryPointers = [];

  /// Callbacks for releasing native resources under management by this [Arena].
  final List<void Function()> _managedResourceReleaseCallbacks = [];

  bool _inUse = true;

  /// Creates a arena of allocations.
  ///
  /// The [allocator] is used to do the actual allocation and freeing of
  /// memory. It defaults to using [calloc].
  Arena([Allocator allocator = calloc]) : _wrappedAllocator = allocator;

  /// Allocates memory and includes it in the arena.
  ///
  /// Uses the allocator provided to the [Arena] constructor to do the
  /// allocation.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    _ensureInUse();
    final p = _wrappedAllocator.allocate<T>(byteCount, alignment: alignment);
    _managedMemoryPointers.add(p);
    return p;
  }

  /// Registers [resource] in this arena.
  ///
  /// Executes [releaseCallback] on [releaseAll].
  ///
  /// Returns [resource] again, to allow for easily inserting
  /// `arena.using(resource, ...)` where the resource is allocated.
  T using<T>(T resource, void Function(T) releaseCallback) {
    _ensureInUse();
    releaseCallback = Zone.current.bindUnaryCallback(releaseCallback);
    _managedResourceReleaseCallbacks.add(() => releaseCallback(resource));
    return resource;
  }

  /// Registers [releaseResourceCallback] to be executed on [releaseAll].
  void onReleaseAll(void Function() releaseResourceCallback) {
    _managedResourceReleaseCallbacks.add(releaseResourceCallback);
  }

  /// Releases all resources that this [Arena] manages.
  ///
  /// If [reuse] is `true`, the arena can be used again after resources
  /// have been released. If not, the default, then the [allocate]
  /// and [using] methods must not be called after a call to `releaseAll`.
  ///
  /// If any of the callbacks throw, [releaseAll] is interrupted, and should
  /// be started again.
  void releaseAll({bool reuse = false}) {
    if (!reuse) {
      _inUse = false;
    }
    // The code below is deliberately wirtten to allow allocations to happen
    // during `releaseAll(reuse:true)`. The arena will still be guaranteed
    // empty when the `releaseAll` call returns.
    while (_managedResourceReleaseCallbacks.isNotEmpty) {
      _managedResourceReleaseCallbacks.removeLast()();
    }
    for (final p in _managedMemoryPointers) {
      _wrappedAllocator.free(p);
    }
    _managedMemoryPointers.clear();
  }

  /// Does nothing, invoke [releaseAll] instead.
  @override
  void free(Pointer<NativeType> pointer) {}

  void _ensureInUse() {
    if (!_inUse) {
      throw StateError(
          'Arena no longer in use, `releaseAll(reuse: false)` was called.');
    }
  }
}

/// Runs [computation] with a new [Arena], and releases all allocations at the
/// end.
///
/// If the return value of [computation] is a [Future], all allocations are
/// released when the future completes.
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_
/// cleaned up.
R using<R>(R Function(Arena) computation,
    [Allocator wrappedAllocator = calloc]) {
  final arena = Arena(wrappedAllocator);
  bool isAsync = false;
  try {
    final result = computation(arena);
    if (result is Future) {
      isAsync = true;
      return (result.whenComplete(arena.releaseAll) as R);
    }
    return result;
  } finally {
    if (!isAsync) {
      arena.releaseAll();
    }
  }
}

/// Creates a zoned [Arena] to manage native resources.
///
/// The arena is availabe through [zoneArena].
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_
/// cleaned up.
R withZoneArena<R>(R Function() computation,
    [Allocator wrappedAllocator = calloc]) {
  final arena = Arena(wrappedAllocator);
  var arenaHolder = [arena];
  bool isAsync = false;
  try {
    return runZoned(() {
      final result = computation();
      if (result is Future) {
        isAsync = true;
        return result.whenComplete(() {
          arena.releaseAll();
        }) as R;
      }
      return result;
    }, zoneValues: {#_arena: arenaHolder});
  } finally {
    if (!isAsync) {
      arena.releaseAll();
      arenaHolder.clear();
    }
  }
}

/// A zone-specific [Arena].
///
/// Asynchronous computations can share a [Arena]. Use [withZoneArena] to create
/// a new zone with a fresh [Arena], and that arena will then be released
/// automatically when the function passed to [withZoneArena] completes.
/// All code inside that zone can use `zoneArena` to access the arena.
///
/// The current arena must not be accessed by code which is not running inside
/// a zone created by [withZoneArena].
Arena get zoneArena {
  final arenaHolder = Zone.current[#_arena] as List<Arena>?;
  if (arenaHolder == null) {
    throw StateError('Not inside a zone created by `useArena`');
  }
  if (arenaHolder.isNotEmpty) {
    return arenaHolder.single;
  }
  throw StateError('Arena has already been cleared with releaseAll.');
}

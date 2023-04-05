// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:meta/meta.dart';

import '../../engine.dart' show Instrumentation;
import 'canvaskit_api.dart';
import 'renderer.dart';

/// A cache of Skia objects whose memory Flutter manages.
///
/// When using Skia, Flutter creates Skia objects which are allocated in
/// WASM memory and which must be explicitly deleted. In the case of Flutter
/// mobile, the Skia objects are wrapped by a C++ class which is destroyed
/// when the associated Dart object is garbage collected.
///
/// On the web, we cannot tell when a Dart object is garbage collected, so
/// we must use other strategies to know when to delete a Skia object. Some
/// objects, like [ui.Paint], can safely delete their associated Skia object
/// because they can always recreate the Skia object from data stored in the
/// Dart object. Other objects, like [ui.Picture], can be serialized to a
/// JS-managed data structure when they are deleted so that when the associated
/// object is garbage collected, so is the serialized data.
class SkiaObjectCache {
  SkiaObjectCache(this.maximumSize)
      : _itemQueue = DoubleLinkedQueue<SkiaObject<Object>>(),
        _itemMap = <SkiaObject<Object>, DoubleLinkedQueueEntry<SkiaObject<Object>>>{};

  final int maximumSize;

  /// A doubly linked list of the objects in the cache.
  ///
  /// This makes it fast to move a recently used object to the front.
  final DoubleLinkedQueue<SkiaObject<Object>> _itemQueue;

  /// A map of objects to their associated node in the [_itemQueue].
  ///
  /// This makes it fast to find the node in the queue when we need to
  /// move the object to the front of the queue.
  final Map<SkiaObject<Object>, DoubleLinkedQueueEntry<SkiaObject<Object>>> _itemMap;

  /// The number of objects in the cache.
  int get length => _itemQueue.length;

  /// Whether or not [object] is in the cache.
  ///
  /// This is only for testing.
  @visibleForTesting
  bool debugContains(SkiaObject<Object> object) {
    return _itemMap.containsKey(object);
  }

  /// Adds [object] to the cache.
  ///
  /// If adding [object] causes the total size of the cache to exceed
  /// [maximumSize], then the least recently used half of the cache
  /// will be deleted.
  void add(SkiaObject<Object> object) {
    _itemQueue.addFirst(object);
    _itemMap[object] = _itemQueue.firstEntry()!;

    if (_itemQueue.length > maximumSize) {
      SkiaObjects.markCacheForResize(this);
    }
  }

  /// Records that [object] was used in the most recent frame.
  void markUsed(SkiaObject<Object> object) {
    final DoubleLinkedQueueEntry<SkiaObject<Object>> item = _itemMap[object]!;
    item.remove();
    _itemQueue.addFirst(object);
    _itemMap[object] = _itemQueue.firstEntry()!;
  }

  /// Deletes the least recently used half of this cache.
  void resize() {
    final int itemsToDelete = maximumSize ~/ 2;
    for (int i = 0; i < itemsToDelete; i++) {
      final SkiaObject<Object> oldObject = _itemQueue.removeLast();
      _itemMap.remove(oldObject);
      oldObject.delete();
      oldObject.didDelete();
    }
  }
}

/// An object backed by a JavaScript object mapped onto a Skia C++ object in the
/// WebAssembly heap.
///
/// These objects are automatically deleted when no longer used.
abstract class SkiaObject<T extends Object> {
  /// The JavaScript object that's mapped onto a Skia C++ object in the WebAssembly heap.
  T get skiaObject;

  /// Deletes the associated C++ object from the WebAssembly heap.
  void delete();

  /// Lifecycle method called immediately after calling [delete].
  ///
  /// This method is used to
  void didDelete();
}

/// A [SkiaObject] that manages the lifecycle of its C++ counterpart.
///
/// In browsers that support weak references we use feedback from the garbage
/// collector to determine when it is safe to release the C++ object.
///
/// In browsers that do not support weak references we pessimistically delete
/// the underlying C++ object before the Dart object is garbage-collected.
///
/// If [isResurrectionExpensive] is false the object is deleted at the end of
/// the frame. If a deleted object is reused in a subsequent frame it is
/// resurrected by calling [resurrect]. This allows reusing the C++ objects
/// within the frame.
///
/// If [isResurrectionExpensive] is true the object is put in a LRU cache.
/// Objects that are used least frequently are deleted from the cache when
/// the cache limit is reached.
///
/// The lifecycle of a resurrectable C++ object is as follows:
///
/// - Create: a managed object is created using a default instance that's
///   either supplied as a constructor argument, or obtained by calling
///   [createDefault]. The data in the new object is expected to contain
///   data matching Flutter's defaults (sometimes Skia defaults need to be
///   adjusted).
/// - Zero or more cycles of delete + resurrect: when a Dart object is reused
///   after its C++ object is deleted we create a new C++ object populated with
///   data from the current state of the Dart object. This is done using the
///   [resurrect] method.
/// - Final delete: if a Dart object is never reused, it is GC'd after its
///   underlying C++ object is deleted. This is implemented by [SkiaObjects].
abstract class ManagedSkiaObject<T extends Object> extends SkiaObject<T> {
  /// Creates a managed Skia object.
  ///
  /// If `instance` is null calls [createDefault] to create a Skia object to
  /// manage. Otherwise, uses the provided instance.
  ///
  /// The provided instance must not be managed by another [ManagedSkiaObject],
  /// as it may lead to undefined behavior.
  ManagedSkiaObject([T? instance]) {
    final T defaultObject = instance ?? createDefault();
    rawSkiaObject = defaultObject;
    if (browserSupportsFinalizationRegistry) {
      // If FinalizationRegistry is supported we will only ever need the
      // default object, as we know precisely when to delete it.
      Collector.instance.register(this, defaultObject as SkDeletable);
    } else {
      // If FinalizationRegistry is _not_ supported we may need to delete
      // and resurrect the object multiple times before deleting it forever.
      if (Instrumentation.enabled) {
        Instrumentation.instance.incrementCounter(
          '${(defaultObject as SkDeletable).constructor.name} created',
        );
      }
      if (isResurrectionExpensive) {
        SkiaObjects.manageExpensive(this);
      } else {
        SkiaObjects.manageResurrectable(this);
      }
    }
  }

  @override
  T get skiaObject => rawSkiaObject ?? _doResurrect();

  T _doResurrect() {
    assert(!browserSupportsFinalizationRegistry);
    final T skiaObject = resurrect();
    if (Instrumentation.enabled) {
      Instrumentation.instance.incrementCounter(
        '${(skiaObject as SkDeletable).constructor.name} resurrected',
      );
    }
    rawSkiaObject = skiaObject;
    if (isResurrectionExpensive) {
      SkiaObjects.manageExpensive(this);
    } else {
      SkiaObjects.manageResurrectable(this);
    }
    return skiaObject;
  }

  @override
  void didDelete() {
    assert(!browserSupportsFinalizationRegistry);

    // Null indicates that the object has been manually disposed of. This
    // happens for objects with manual lifecycles, such as Picture.
    if (rawSkiaObject == null) {
      return;
    }

    if (Instrumentation.enabled) {
      Instrumentation.instance.incrementCounter(
        '${(rawSkiaObject! as SkDeletable).constructor.name} deleted',
      );
    }
    rawSkiaObject = null;
  }

  /// Returns the current skia object as is without attempting to
  /// resurrect it.
  ///
  /// If the returned value is `null`, the corresponding C++ object has
  /// been deleted.
  ///
  /// Use this field instead of the [skiaObject] getter when implementing
  /// the [delete] method.
  T? rawSkiaObject;

  /// Instantiates a new Skia-backed JavaScript object containing default
  /// values.
  ///
  /// The object is expected to represent Flutter's defaults. If Skia uses
  /// different defaults from those used by Flutter, this method is expected
  /// initialize the object to Flutter's defaults.
  T createDefault();

  /// Creates a new Skia-backed JavaScript object containing data representing
  /// the current state of the Dart object.
  T resurrect();

  /// Whether or not it is expensive to resurrect this object.
  ///
  /// Defaults to false.
  bool get isResurrectionExpensive => false;
}

/// A function that restores a Skia object that was temporarily deleted.
typedef Resurrector<T> = T Function();

// ignore: avoid_classes_with_only_static_members
/// Singleton that manages the lifecycles of [SkiaObject] instances.
class SkiaObjects {
  @visibleForTesting
  static final List<ManagedSkiaObject<Object>> resurrectableObjects =
      <ManagedSkiaObject<Object>>[];

  @visibleForTesting
  static int maximumCacheSize = 1024;

  @visibleForTesting
  static final SkiaObjectCache expensiveCache =
      SkiaObjectCache(maximumCacheSize);

  @visibleForTesting
  static final List<SkiaObjectCache> cachesToResize = <SkiaObjectCache>[];

  static bool _addedCleanupCallback = false;

  @visibleForTesting
  static void registerCleanupCallback() {
    if (_addedCleanupCallback) {
      return;
    }
    CanvasKitRenderer.instance.rasterizer.addPostFrameCallback(postFrameCleanUp);
    _addedCleanupCallback = true;
  }

  /// Starts managing the lifecycle of resurrectable [object].
  ///
  /// These can safely be deleted at any time.
  static void manageResurrectable(ManagedSkiaObject<Object> object) {
    registerCleanupCallback();
    resurrectableObjects.add(object);
  }

  /// Starts managing the lifecycle of a resurrectable object that is expensive.
  ///
  /// Since it's expensive to resurrect, we shouldn't just delete it after every
  /// frame. Instead, add it to a cache and only delete it when the cache fills.
  static void manageExpensive(SkiaObject<Object> object) {
    registerCleanupCallback();
    expensiveCache.add(object);
  }

  /// Marks that [cache] has overflown its maximum size and show be resized.
  static void markCacheForResize(SkiaObjectCache cache) {
    registerCleanupCallback();
    if (cachesToResize.contains(cache)) {
      return;
    }
    cachesToResize.add(cache);
  }

  /// Cleans up managed Skia memory.
  static void postFrameCleanUp() {
    if (resurrectableObjects.isEmpty && cachesToResize.isEmpty) {
      return;
    }

    for (int i = 0; i < resurrectableObjects.length; i++) {
      final SkiaObject<Object> object = resurrectableObjects[i];
      object.delete();
      object.didDelete();
    }
    resurrectableObjects.clear();

    for (int i = 0; i < cachesToResize.length; i++) {
      final SkiaObjectCache cache = cachesToResize[i];
      cache.resize();
    }
    cachesToResize.clear();
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

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
  final int maximumSize;

  /// A doubly linked list of the objects in the cache.
  ///
  /// This makes it fast to move a recently used object to the front.
  final DoubleLinkedQueue<SkiaObject> _itemQueue;

  /// A map of objects to their associated node in the [_itemQueue].
  ///
  /// This makes it fast to find the node in the queue when we need to
  /// move the object to the front of the queue.
  final Map<SkiaObject, DoubleLinkedQueueEntry<SkiaObject>> _itemMap;

  SkiaObjectCache(this.maximumSize)
      : _itemQueue = DoubleLinkedQueue<SkiaObject>(),
        _itemMap = <SkiaObject, DoubleLinkedQueueEntry<SkiaObject>>{};

  /// The number of objects in the cache.
  int get length => _itemQueue.length;

  /// Whether or not [object] is in the cache.
  ///
  /// This is only for testing.
  @visibleForTesting
  bool debugContains(SkiaObject object) {
    return _itemMap.containsKey(object);
  }

  /// Adds [object] to the cache.
  ///
  /// If adding [object] causes the total size of the cache to exceed
  /// [maximumSize], then the least recently used half of the cache
  /// will be deleted.
  void add(SkiaObject object) {
    _itemQueue.addFirst(object);
    _itemMap[object] = _itemQueue.firstEntry()!;

    if (_itemQueue.length > maximumSize) {
      SkiaObjects.markCacheForResize(this);
    }
  }

  /// Records that [object] was used in the most recent frame.
  void markUsed(SkiaObject object) {
    DoubleLinkedQueueEntry<SkiaObject> item = _itemMap[object]!;
    item.remove();
    _itemQueue.addFirst(object);
    _itemMap[object] = _itemQueue.firstEntry()!;
  }

  /// Deletes the least recently used half of this cache.
  void resize() {
    final int itemsToDelete = maximumSize ~/ 2;
    for (int i = 0; i < itemsToDelete; i++) {
      final SkiaObject oldObject = _itemQueue.removeLast();
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
/// the underlying C++ object before the Dart object is garbage-collected. The
/// current algorithm deletes objects at the end of every frame. This allows
/// reusing the C++ objects within the frame. If the object is used again after
/// is was deleted, we [resurrect] it based on the data available on the
/// JavaScript side.
///
/// The lifecycle of a resurrectable C++ object is as follows:
///
/// - Create default: when instantiating a C++ object for a Dart object for the
///   first time, the C++ object is populated with default data (the defaults are
///   defined by Flutter; Skia defaults are corrected if necessary). The
///   default object is created by [createDefault].
/// - Zero or more cycles of delete + resurrect: when a Dart object is reused
///   after its C++ object is deleted we create a new C++ object populated with
///   data from the current state of the Dart object. This is done using the
///   [resurrect] method.
/// - Final delete: if a Dart object is never reused, it is GC'd after its
///   underlying C++ object is deleted. This is implemented by [SkiaObjects].
abstract class ManagedSkiaObject<T extends Object> extends SkiaObject<T> {
  ManagedSkiaObject() {
    final T defaultObject = createDefault();
    rawSkiaObject = defaultObject;
    if (browserSupportsFinalizationRegistry) {
      // If FinalizationRegistry is supported we will only ever need the
      // default object, as we know precisely when to delete it.
      skObjectFinalizationRegistry.register(this, defaultObject);
    } else {
      // If FinalizationRegistry is _not_ supported we may need to delete
      // and resurrect the object multiple times before deleting it forever.
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

// TODO(hterkelsen): [OneShotSkiaObject] is dangerous because it might delete
//     the underlying Skia object while the associated Dart object is still in
//     use. This issue discusses ways to address this:
//     https://github.com/flutter/flutter/issues/60401
/// A [SkiaObject] which is deleted once and cannot be used again.
///
/// In browsers that support weak references we use feedback from the garbage
/// collector to determine when it is safe to release the C++ object. Otherwise,
/// we use an LRU cache (see [SkiaObjects.manageOneShot]).
abstract class OneShotSkiaObject<T extends Object> extends SkiaObject<T> {
  /// Returns the current skia object as is without attempting to
  /// resurrect it.
  ///
  /// If the returned value is `null`, the corresponding C++ object has
  /// been deleted.
  ///
  /// Use this field instead of the [skiaObject] getter when implementing
  /// the [delete] method.
  T rawSkiaObject;

  bool _isDeleted = false;

  OneShotSkiaObject(T skObject) : this.rawSkiaObject = skObject {
    if (browserSupportsFinalizationRegistry) {
      skObjectFinalizationRegistry.register(this, skObject);
    } else {
      SkiaObjects.manageOneShot(this);
    }
  }

  @override
  T get skiaObject {
    if (browserSupportsFinalizationRegistry) {
      return rawSkiaObject;
    }
    if (_isDeleted) {
      throw StateError('Attempting to use a Skia object that has been freed.');
    }
    SkiaObjects.oneShotCache.markUsed(this);
    return rawSkiaObject;
  }

  @override
  void didDelete() {
    _isDeleted = true;
  }
}

/// Manages the lifecycle of a Skia object owned by a wrapper object.
///
/// When the wrapper is garbage collected, deletes the corresponding
/// [skObject] (only in browsers that support weak references).
///
/// The [delete] method can be used to eagerly delete the [skObject]
/// before the wrapper is garbage collected.
///
/// The [delete] method may be called any number of times. The box
/// will only delete the object once.
class SkiaObjectBox {
  SkiaObjectBox(Object wrapper, this.skObject) {
    if (browserSupportsFinalizationRegistry) {
      boxRegistry.register(wrapper, this);
    }
  }

  /// The Skia object whose lifecycle is being managed.
  final SkDeletable skObject;

  /// Whether this object has been deleted.
  bool get isDeleted => _isDeleted;
  bool _isDeleted = false;

  /// Deletes Skia objects when their wrappers are garbage collected.
  static final SkObjectFinalizationRegistry<SkiaObjectBox> boxRegistry =
      SkObjectFinalizationRegistry<SkiaObjectBox>(
          js.allowInterop((SkiaObjectBox box) {
    box.delete();
  }));

  /// Deletes the [skObject].
  ///
  /// Does nothing if the object has already been deleted.
  void delete() {
    if (_isDeleted) {
      return;
    }
    _isDeleted = true;
    _skObjectDeleteQueue.add(skObject);
    _skObjectCollector ??= _scheduleSkObjectCollection();
  }
}

/// Singleton that manages the lifecycles of [SkiaObject] instances.
class SkiaObjects {
  @visibleForTesting
  static final List<ManagedSkiaObject> resurrectableObjects =
      <ManagedSkiaObject>[];

  @visibleForTesting
  static int maximumCacheSize = 8192;

  @visibleForTesting
  static final SkiaObjectCache oneShotCache = SkiaObjectCache(maximumCacheSize);

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
    window.rasterizer!.addPostFrameCallback(postFrameCleanUp);
    _addedCleanupCallback = true;
  }

  /// Starts managing the lifecycle of resurrectable [object].
  ///
  /// These can safely be deleted at any time.
  static void manageResurrectable(ManagedSkiaObject object) {
    registerCleanupCallback();
    resurrectableObjects.add(object);
  }

  /// Starts managing the lifecycle of a one-shot [object].
  ///
  /// We should avoid deleting these whenever we can, since we won't
  /// be able to resurrect them.
  static void manageOneShot(OneShotSkiaObject object) {
    registerCleanupCallback();
    oneShotCache.add(object);
  }

  /// Starts managing the lifecycle of a resurrectable object that is expensive.
  ///
  /// Since it's expensive to resurrect, we shouldn't just delete it after every
  /// frame. Instead, add it to a cache and only delete it when the cache fills.
  static void manageExpensive(ManagedSkiaObject object) {
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
      final SkiaObject object = resurrectableObjects[i];
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

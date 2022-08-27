// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

/// A lyfecycle event of an object.
abstract class ObjectEvent{
  /// Creates an instance of [ObjectEvent].
  ObjectEvent({
    required this.object,
    this.details = const <Object>[],
    this.token,
  });

  /// Reference to the object.
  ///
  /// The reference should not be stored in any
  /// long living place as it will prevent garbage collection.
  final Object object;

  /// A token that uniquely identify object, for object tracking
  /// accross events.
  ///
  /// If not provided, the consumers of the event may use
  /// [identityHashCode] and handle small risk of duplicates.
  /// The object's token should be the same accross all events.
  final Object? token;

  /// Details that may help with troubleshooting.
  final List<Object> details;
}

/// A listener of [ObjectEvent].
typedef ObjectEventListener = void Function(ObjectEvent);

/// An event that describes creation of an object.
class ObjectCreated extends ObjectEvent {
  /// Creates an instance of [ObjectCreated].
  ObjectCreated({
    required this.library,
    required this.className,
    required super.object,
    super.token,
    super.details = const <Object>[],
  });

  /// Name of the instrumented library.
  final String library;

  /// Name of the instrumented class.
  final String className;
}

/// An event that describes disposal of an object.
class ObjectDisposed extends ObjectEvent {
  /// Creates an instance of [ObjectDisposed].
  ObjectDisposed({
    required super.object,
    super.details = const <Object>[],
    super.token,
  });
}

/// The event contains tracing information that may help with memory
/// troubleshooting.
///
/// For example, information about ownership transfer
/// or state change.
class ObjectTraced extends ObjectEvent {
  /// Creates an instance of [ObjectTraced].
  ObjectTraced({
    required super.object,
    super.details = const <Object>[],
    super.token,
  });
}

/// An interface for listening to object lyfecycle events.
///
/// [MemoryAllocations] already listens to creation and disposal events
/// for disposable objects in Flutter Framework.
/// You can dispatch events for other objects by invoking
/// [MemoryAllocations.dispatchObjectEvent].
class MemoryAllocations {
  MemoryAllocations._();

  /// The shared instance of [MemoryAllocations].
  static final MemoryAllocations instance = MemoryAllocations._();

  List<ObjectEventListener>? _listeners;

  /// Register a listener that is called every time an object event is
  /// dispatched.
  ///
  /// Listeners can be removed with [removeListener].
  void addListener(ObjectEventListener listener){
    if (_listeners == null) {
      _listeners = <ObjectEventListener>[];
      _subscribeToSdkObjects();
    }
    _listeners!.add(listener);
  }

  /// Stop calling the given listener every time an object event is
  /// dispatched.
  ///
  /// Listeners can be added with [addListener].
  void removeListener(ObjectEventListener listener){
    _listeners?.remove(listener);
    if (_listeners?.isEmpty ?? false) {
      _listeners = null;
      _unSubscribeFromSdkObjects();
    }
  }

  /// Stop calling all listeners every time an object event is
  /// dispatched.
  ///
  /// Listeners can be added with [addListener].
  void removeAllListeners(){
    _listeners = null;
    _unSubscribeFromSdkObjects();
  }

  /// Dispatch a new object event to listeners.
  void dispatchObjectEvent(ObjectEvent objectEvent) {
    final List<ObjectEventListener>? listeners = _listeners;
    if (listeners == null || listeners.isEmpty) {
      return;
    }
    for (final ObjectEventListener listener in listeners) {
      listener(objectEvent);
    }
  }

  void _subscribeToSdkObjects() {
    // Uncomment and test cover
    // when https://github.com/flutter/engine/pull/35274 lands:
    // assert(ui.Image.onCreate == null);
    // assert(ui.Image.onDispose == null);
    // assert(ui.Picture.onCreate == null);
    // assert(ui.Picture.onDispose == null);
    // ui.Image.onCreate = _imageOnCreate;
    // ui.Image.onDispose = _imageOnDispose;
    // ui.Picture.onCreate = _pictureOnCreate;
    // ui.Picture.onDispose = _pictureOnDispose;
  }

  void _unSubscribeFromSdkObjects() {
    // Uncomment and test cover
    // when https://github.com/flutter/engine/pull/35274 lands:
    // assert(ui.Image.onCreate == _imageOnCreate);
    // assert(ui.Image.onDispose == _imageOnDispose);
    // assert(ui.Picture.onCreate == _pictureOnCreate);
    // assert(ui.Picture.onDispose == _pictureOnDispose);
    // ui.Image.onCreate = null;
    // ui.Image.onDispose = null;
    // ui.Picture.onCreate = null;
    // ui.Picture.onDispose = null;
  }

  void _imageOnCreate(ui.Image image) => dispatchObjectEvent(ObjectCreated(
    library: 'dart:ui',
    className: 'Image',
    object: image,
  ));

  void _pictureOnCreate(ui.Picture picture) => dispatchObjectEvent(ObjectCreated(
    library: 'dart:ui',
    className: 'Image',
    object: picture,
  ));

  void _imageOnDispose(ui.Image image) => dispatchObjectEvent(ObjectDisposed(
    object: image,
  ));

  void _pictureOnDispose(ui.Picture picture) => dispatchObjectEvent(ObjectDisposed(
    object: picture,
  ));
}

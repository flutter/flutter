// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

/// A lyfecycle event of an object.
abstract class ObjectEvent{}

/// A listener of [ObjectEvent].
typedef ObjectEventListener = void Function(ObjectEvent);

/// An event that describes vreation of an object.
class ObjectCreated implements ObjectEvent {
  /// Creates an instance of [ObjectCreated].
  ObjectCreated({
    required this.library,
    required this.klass,
    required this.object,
    this.token,
    this.details = const <Object>[],
  });

  /// Name of the instrumented library.
  final String library;

  /// Name of the instrumented class.
  final String klass;

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

///
class ObjectDisposed implements ObjectEvent {

  ///
  ObjectDisposed({
    required this.object,
    this.details = const <Object>[],
    this.token }
  );

  ///
  final Object object;

  ///
  final Object? token;

  ///
  final List<Object> details;
}


/// The event contains tracing information that may help with memory
/// troubleshooting.
///
/// For example, it may be information about ownership transfer
/// or state change.
class ObjectTraced implements ObjectEvent {

  ///
  ObjectTraced(
    this.object, {
    this.details = const <Object>[],
    this.token, }
  );

  ///
  final Object object;

  ///
  final Object? token;

  ///
  final List<Object> details;
}

///
class MemoryAllocations {
  MemoryAllocations._();

  ///
  static final MemoryAllocations instance = MemoryAllocations._();

  List<ObjectEventListener>? _listeners;

  ///
  void addListener(ObjectEventListener listener){
    if (_listeners == null) {
      _listeners = <ObjectEventListener>[];
      _subscribeToSdkObjects();
    }
    _listeners!.add(listener);
  }

  ///
  void removeListener(ObjectEventListener listener){
    _listeners?.remove(listener);
    if (_listeners?.isEmpty ?? false) {
      _listeners = null;
      _unSubscribeFromSdkObjects();
    }
  }

  ///
  void registerObjectEvent(ObjectEvent objectEvent) {
    final List<ObjectEventListener>? listeners = _listeners;
    if (listeners == null || listeners.isEmpty) {
      return;
    }
    for (final ObjectEventListener listener in listeners) {
      listener(objectEvent);
    }
  }

  void _subscribeToSdkObjects() {
    assert(ui.Image.onCreate == null);
    assert(ui.Image.onDispose == null);
    assert(ui.Picture.onCreate == null);
    assert(ui.Picture.onDispose == null);
    ui.Image.onCreate = _imageOnCreate;
    ui.Image.onDispose = _imageOnDispose;
    ui.Picture.onCreate = _pictureOnCreate;
    ui.Picture.onDispose = _pictureOnDispose;
  }

  void _unSubscribeFromSdkObjects() {
    assert(ui.Image.onCreate == _imageOnCreate);
    assert(ui.Image.onDispose == _imageOnDispose);
    assert(ui.Picture.onCreate == _pictureOnCreate);
    assert(ui.Picture.onDispose == _pictureOnDispose);
    ui.Image.onCreate = null;
    ui.Image.onDispose = null;
    ui.Picture.onCreate = null;
    ui.Picture.onDispose = null;
  }

  void _imageOnCreate(ui.Image image) => registerObjectEvent(ObjectCreated(
    library: 'dart:ui',
    klass: 'Image',
    object: image,
  ));

  void _pictureOnCreate(ui.Picture picture) => registerObjectEvent(ObjectCreated(
    library: 'dart:ui',
    klass: 'Image',
    object: picture,
  ));

  void _imageOnDispose(ui.Image image) => registerObjectEvent(ObjectDisposed(
    object: image,
  ));

  void _pictureOnDispose(ui.Picture picture) => registerObjectEvent(ObjectDisposed(
    object: picture,
  ));
}

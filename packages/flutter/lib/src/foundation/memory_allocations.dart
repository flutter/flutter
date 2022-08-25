// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

///
abstract class ObjectEvent{}

///
typedef ObjectEventListener = void Function(ObjectEvent);

///
class ObjectCreated implements ObjectEvent {
  ///
  ObjectCreated({
    required this.library,
    required this.klass,
    required this.object,
    this.token,
    this.details = const <Object>[],
  });

  ///
  final String library;

  ///
  final String klass;

  /// Reference to this object should not be stored in any
  /// long living place as it will prevent garbage collection.
  final Object object;

  /// A token that uniquely identify object, for object tracking
  /// accross events.
  ///
  /// If not provided, the consumers of the event may use
  /// [identityHashCode] and handle small risk of duplicates.
  /// The object's token should be the same accross events.
  final Object? token;

  ///
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


///
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
  // Lint is ignored here, because 'late' is needed for lazy pattern.
  // ignore: unnecessary_late
  static late final MemoryAllocations instance = MemoryAllocations._();

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

  void _imageOnDispose(ui.Image image) => registerObjectEvent(ObjectCreated(
    library: 'dart:ui',
    klass: 'Image',
    object: image,
  ));

  void _pictureOnDispose(ui.Picture picture) => registerObjectEvent(ObjectCreated(
    library: 'dart:ui',
    klass: 'Image',
    object: picture,
  ));
}

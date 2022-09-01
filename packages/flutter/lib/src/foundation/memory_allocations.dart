// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'assertions.dart';
import 'diagnostics.dart';

/// List of the Flutter Framework and SDK libraries with instrumented
/// classes.
class FlutterLibraries {
  static const String dartUi = 'dart:ui';
  static const String flutterFoundation = 'package:flutter/foundation.dart';
}

/// List of field names for dart form of [ObjectEvent].
class FieldNames {
  static const String eventType = 'eventType';
  static const String labraryName = 'labraryName';
  static const String className = 'className';
}

/// A lyfecycle event of an object.
abstract class ObjectEvent{
  /// Creates an instance of [ObjectEvent].
  ObjectEvent({
    required this.object,
  });

  /// Reference to the object.
  ///
  /// The reference should not be stored in any
  /// long living place as it will prevent garbage collection.
  final Object object;

  /// The representation of the event in a form, acceptible by a
  /// pure dart library, that cannot depend on Flutter.
  ///
  /// The method enables the code like:
  /// MemoryAllocations.instance
  ///   .addListener((event) => dartMethod(event.toDart()));
  Map<Object, Map<String, dynamic>> toDart();
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
  });

  /// Name of the instrumented library.
  final String library;

  /// Name of the instrumented class.
  final String className;

  @override
  Map<Object, Map<String, dynamic>> toDart() =>
    <Object, Map<String, dynamic>>{object: <String, dynamic>{
      FieldNames.labraryName: library,
      FieldNames.className: className,
      FieldNames.eventType: 'created',
    }};
}

/// An event that describes disposal of an object.
class ObjectDisposed extends ObjectEvent {
  /// Creates an instance of [ObjectDisposed].
  ObjectDisposed({
    required super.object,
  });

  @override
  Map<Object, Map<String, dynamic>> toDart() =>
    <Object, Map<String, dynamic>>{object: <String, dynamic>{
      FieldNames.eventType: 'disposed',
    }};
}

/// An interface for listening to object lyfecycle events.
///
/// [MemoryAllocations] already listens to creation and disposal events
/// for disposable objects in Flutter Framework.
/// You can dispatch events for other objects by invoking
/// [MemoryAllocations.dispatchObjectEvent].
///
/// The class is optimized for massive event flow and small number of
/// added or removed listeners.
class MemoryAllocations {
  MemoryAllocations._();

  /// The shared instance of [MemoryAllocations].
  static final MemoryAllocations instance = MemoryAllocations._();

  /// List of listeners.
  ///
  /// The elements are nullable, because the listeners should be removable
  /// while iterating through the list.
  List<ObjectEventListener?>? _listeners;

  /// Register a listener that is called every time an object event is
  /// dispatched.
  ///
  /// Listeners can be removed with [removeListener].
  void addListener(ObjectEventListener listener){
    if (_listeners == null) {
      _listeners = <ObjectEventListener?>[];
      _subscribeToSdkObjects();
    }
    _listeners!.add(listener);
  }

  /// Number of active notification loops.
  ///
  /// When equal to zero, we can delete listeners from the list,
  /// otherwize should null them.
  int _activeDispatchLoops = 0;

  /// If true, listeners were nulled by [removeListener].
  bool _listenersContainNulls = false;

  /// Stop calling the given listener every time an object event is
  /// dispatched.
  ///
  /// Listeners can be added with [addListener].
  void removeListener(ObjectEventListener listener){
    final List<ObjectEventListener?>? listeners = _listeners;
    if (listeners == null) {
      return;
    }

    if (_activeDispatchLoops > 0) {
      // If there are active dispatch loops, listeners.remove
      // should not be invoked, as it will
      // break the dispatch loops correctness.
      for (int i = 0; i < listeners.length; i++) {
        if (listeners[i] == listener) {
          listeners[i] = null;
          _listenersContainNulls = true;
        }
      }
    } else {
      listeners.removeWhere((ObjectEventListener? l) => l == listener);
      _checkListenersForEmptiness();
    }
  }

  void _tryDefragmentListeners() {
    if (_activeDispatchLoops > 0 || !_listenersContainNulls) {
      return;
    }
    _listeners?.removeWhere((ObjectEventListener? e) => e == null);
    _listenersContainNulls = false;
    _checkListenersForEmptiness();
  }

  void _checkListenersForEmptiness() {
    if (_listeners?.isEmpty ?? false) {
        _listeners = null;
        _unSubscribeFromSdkObjects();
    }
  }

  /// Return true if there are listeners.
  ///
  /// If there is no listeners, the app can save on creating the event object.
  bool get hasListeners {
    if (_listenersContainNulls) {
      return _listeners?.firstWhere((ObjectEventListener? l) => l != null) != null;
    }
    return _listeners?.isNotEmpty ?? false;
  }

  /// Dispatch a new object event to listeners.
  ///
  /// Exceptions thrown by listeners will be caught and reported using
  /// [FlutterError.reportError].
  ///
  /// Listeners added during an event dispatching, will start being invoked
  /// for next events, but will be skipped for this event.
  ///
  /// Listeners, removed during an event dispatching, will not be invoked
  /// after the removal.
  void dispatchObjectEvent(ObjectEvent objectEvent) {
    final List<ObjectEventListener?>? listeners = _listeners;
    if (listeners == null || listeners.isEmpty) {
      return;
    }

    _activeDispatchLoops++;
    final int end = listeners.length;
    for (int i = 0; i < end; i++) {
      try {
        listeners[i]?.call(objectEvent);
      } catch (exception, stack) {
        final String type = objectEvent.object.runtimeType.toString();
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'foundation library',
          context: ErrorDescription('MemoryAllocations while '
          'dispatching notifications for $type'),
          informationCollector: () => <DiagnosticsNode>[
            DiagnosticsProperty<Object>(
              'The $type sending notification was',
              objectEvent.object,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
          ],
        ));
      }
    }
    _activeDispatchLoops--;
    _tryDefragmentListeners();
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
    library: FlutterLibraries.dartUi,
    className: 'Image',
    object: image,
  ));

  void _pictureOnCreate(ui.Picture picture) => dispatchObjectEvent(ObjectCreated(
    library: FlutterLibraries.dartUi,
    className: 'Picture',
    object: picture,
  ));

  void _imageOnDispose(ui.Image image) => dispatchObjectEvent(ObjectDisposed(
    object: image,
  ));

  void _pictureOnDispose(ui.Picture picture) => dispatchObjectEvent(ObjectDisposed(
    object: picture,
  ));
}

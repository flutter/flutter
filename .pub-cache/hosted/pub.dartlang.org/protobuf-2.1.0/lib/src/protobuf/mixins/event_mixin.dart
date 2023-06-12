// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show StreamController, scheduleMicrotask;
import 'dart:collection' show UnmodifiableListView;

import '../../../protobuf.dart' show GeneratedMessage, FieldInfo, EventPlugin;

/// Provides a stream of changes to fields in a GeneratedMessage.
/// (Experimental.)
///
/// This mixin is enabled via an option in
/// dart_options.proto in dart-protoc-plugin.
abstract class PbEventMixin {
  final eventPlugin = EventBuffer();

  /// A stream of changes to fields in the GeneratedMessage.
  ///
  /// Events are buffered and delivered via a microtask or in
  /// the next call to [deliverChanges], whichever happens first.
  Stream<List<PbFieldChange>> get changes => eventPlugin.changes;

  /// Delivers buffered field change events synchronously,
  /// instead of waiting for the microtask to run.
  void deliverChanges() => eventPlugin.deliverChanges();
}

/// A change to a field in a GeneratedMessage.
class PbFieldChange {
  final GeneratedMessage? message;
  final FieldInfo info;
  final Object? oldValue;
  final Object? newValue;

  PbFieldChange(this.message, this.info, this.oldValue, this.newValue);

  int get tag => info.tagNumber;
}

/// A buffering implementation of event delivery.
/// (Loosely based on package:observe's ChangeNotifier.)
class EventBuffer extends EventPlugin {
  // An EventBuffer is created for each GeneratedMessage, so
  // initialization should be fast; create fields lazily.

  GeneratedMessage? _parent;
  StreamController<List<PbFieldChange>>? _controller;

  // If _buffer is non-null, at least one event is in the buffer
  // and a microtask has been scheduled to empty it.
  List<PbFieldChange>? _buffer;

  @override
  void attach(GeneratedMessage parent) {
    assert(_parent == null);
    ArgumentError.checkNotNull(parent, 'newParent');
    _parent = parent;
  }

  Stream<List<PbFieldChange>> get changes {
    var controller = _controller ??= StreamController.broadcast(sync: true);
    return controller.stream;
  }

  @override
  bool get hasObservers => _controller != null && _controller!.hasListener;

  void deliverChanges() {
    var records = _buffer;
    _buffer = null;
    if (records != null && hasObservers) {
      _controller!.add(UnmodifiableListView<PbFieldChange>(records));
    }
  }

  void addEvent(PbFieldChange change) {
    if (!hasObservers) return;
    if (_buffer == null) {
      _buffer = <PbFieldChange>[];
      scheduleMicrotask(deliverChanges);
    }
    _buffer!.add(change);
  }

  @override
  void beforeSetField(FieldInfo fi, newValue) {
    var oldValue = _parent!.getFieldOrNull(fi.tagNumber);
    oldValue ??= fi.readonlyDefault;
    if (identical(oldValue, newValue)) return;
    addEvent(PbFieldChange(_parent, fi, oldValue, newValue));
  }

  @override
  void beforeClearField(FieldInfo fi) {
    var oldValue = _parent!.getFieldOrNull(fi.tagNumber);
    if (oldValue == null) return;
    var newValue = fi.readonlyDefault;
    addEvent(PbFieldChange(_parent, fi, oldValue, newValue));
  }
}

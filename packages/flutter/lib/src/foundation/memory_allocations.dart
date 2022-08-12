// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class ObjectEvent{}

typedef ObjectEventListener = void Function(ObjectEvent);

class ObjectCreated implements ObjectEvent {
  ObjectCreated(this.library, this.klass, this.object, this.details);

  final String library;
  final String klass;
  final Object object;
  final List<Object> details;
}

class ObjectDisposed implements ObjectEvent {
  ObjectDisposed(this.object, { this.details: const <Object>[] });

  final Object object;
  final List<Object> details;
}

class ObjectDetailsDiscovered implements ObjectEvent {
  ObjectDetailsDiscovered(this.object, { this.details: const <Object>[] });

  final Object object;
  final List<Object> details;
}

class MemoryAllocations {
  MemoryAllocations._();

  // Lint is ignored here, because 'late' is needed for lazy pattern.
  // ignore: unnecessary_late
  static late final MemoryAllocations instance = MemoryAllocations._();

  List<ObjectEventListener>? _listeners;

  void addListener(ObjectEventListener listener){
    if (_listeners == null) {
      _listeners = <ObjectEventListener>[];
    }
    _listeners!.add(listener);
  }

  void removeListener(ObjectEventListener listener) => _listeners?.remove(listener);

  void registerObjectEvent(ObjectEvent ObjectEvent) {
    final List<ObjectEventListener>? listeners = _listeners;
    if (listeners == null || listeners.isEmpty) {
      return;
    }
    for (final ObjectEventListener listener in listeners) {
      listener(ObjectEvent);
    }
  }
}

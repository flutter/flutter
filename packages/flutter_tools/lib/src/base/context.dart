// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

typedef void ErrorHandler(dynamic error, StackTrace stackTrace);

/// A singleton for application functionality. This singleton can be different
/// on a per-Zone basis.
AppContext get context => Zone.current['context'];

class AppContext {
  final Map<Type, dynamic> _instances = <Type, dynamic>{};
  Zone _zone;

  AppContext() : _zone = Zone.current;

  bool isSet(Type type) {
    if (_instances.containsKey(type))
      return true;

    final AppContext parent = _calcParent(_zone);
    return parent != null ? parent.isSet(type) : false;
  }

  dynamic getVariable(Type type) {
    if (_instances.containsKey(type))
      return _instances[type];

    final AppContext parent = _calcParent(_zone);
    return parent?.getVariable(type);
  }

  void setVariable(Type type, dynamic instance) {
    _instances[type] = instance;
  }

  dynamic operator[](Type type) => getVariable(type);

  dynamic putIfAbsent(Type type, dynamic ifAbsent()) {
    dynamic value = getVariable(type);
    if (value != null) {
      return value;
    }
    value = ifAbsent();
    setVariable(type, value);
    return value;
  }

  AppContext _calcParent(Zone zone) {
    final Zone parentZone = zone.parent;
    if (parentZone == null)
      return null;

    final AppContext parentContext = parentZone['context'];
    return parentContext == this
        ? _calcParent(parentZone)
        : parentContext;
  }

  Future<dynamic> runInZone(dynamic method(), {
    ZoneBinaryCallback<dynamic, dynamic, StackTrace> onError
  }) {
    return runZoned(
      () => _run(method),
      zoneValues: <String, dynamic>{ 'context': this },
      onError: onError
    );
  }

  Future<dynamic> _run(dynamic method()) async {
    final Zone previousZone = _zone;
    try {
      _zone = Zone.current;
      return await method();
    } finally {
      _zone = previousZone;
    }
  }
}

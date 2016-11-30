// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

typedef void ErrorHandler(dynamic error, StackTrace stackTrace);

/// A singleton for application functionality. This singleton can be different
/// on a per-Zone basis.
AppContext get context => Zone.current['context'];

class AppContext {
  Map<Type, dynamic> _instances = <Type, dynamic>{};
  Zone _zone;

  bool isSet(Type type) {
    if (_instances.containsKey(type))
      return true;

    AppContext parent = _calcParent(Zone.current);
    return parent != null ? parent.isSet(type) : false;
  }

  dynamic getVariable(Type type) {
    if (_instances.containsKey(type))
      return _instances[type];

    AppContext parent = _calcParent(_zone ?? Zone.current);
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
    Zone parentZone = zone.parent;
    if (parentZone == null)
      return null;

    AppContext deps = parentZone['context'];
    if (deps == this) {
      return _calcParent(parentZone);
    } else {
      return deps;
    }
  }

  dynamic runInZone(dynamic method(), {
    ZoneBinaryCallback<dynamic, dynamic, StackTrace> onError
  }) {
    return runZoned(
      () => _run(method),
      zoneValues: <String, dynamic>{ 'context': this },
      onError: onError
    );
  }

  dynamic _run(dynamic method()) async {
    try {
      _zone = Zone.current;
      return await method();
    } finally {
      _zone = null;
    }
  }
}

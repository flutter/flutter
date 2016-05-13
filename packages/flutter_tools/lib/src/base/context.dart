// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

final AppContext _defaultContext = new AppContext();

typedef void ErrorHandler(dynamic error);

/// A singleton for application functionality. This singleton can be different
/// on a per-Zone basis.
AppContext get context {
  AppContext currentContext = Zone.current['context'];
  return currentContext == null ? _defaultContext : currentContext;
}

class AppContext {
  Map<Type, dynamic> _instances = <Type, dynamic>{};

  bool isSet(Type type) {
    if (_instances.containsKey(type))
      return true;

    AppContext parent = _calcParent(Zone.current);
    return parent != null ? parent.isSet(type) : false;
  }

  dynamic getVariable(Type type) {
    if (_instances.containsKey(type))
      return _instances[type];

    AppContext parent = _calcParent(Zone.current);
    return parent?.getVariable(type);
  }

  void setVariable(Type type, dynamic instance) {
    _instances[type] = instance;
  }

  dynamic operator[](Type type) => getVariable(type);

  void operator[]=(Type type, dynamic instance) => setVariable(type, instance);

  AppContext _calcParent(Zone zone) {
    if (this == _defaultContext)
      return null;

    Zone parentZone = zone.parent;
    if (parentZone == null)
      return _defaultContext;

    AppContext deps = parentZone['context'];
    if (deps == this) {
      return _calcParent(parentZone);
    } else {
      return deps != null ? deps : _defaultContext;
    }
  }

  dynamic runInZone(dynamic method(), { ErrorHandler onError }) {
    return runZoned(
      method,
      zoneValues: <String, dynamic>{ 'context': this },
      onError: onError
    );
  }
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:stack_trace/stack_trace.dart';

final AppContext _defaultContext = new AppContext();

typedef void ErrorHandler(dynamic error, StackTrace stackTrace);

AppContext _context = _defaultContext;

/// A singleton for the application functionality.
AppContext get context => _context;

class AppContext {
  Map<Type, dynamic> _instances = <Type, dynamic>{};

  bool isSet(Type type) => _instances.containsKey(type);

  dynamic getVariable(Type type) => _instances[type];

  void setVariable(Type type, dynamic instance) => _instances[type] = instance;

  dynamic operator[](Type type) => getVariable(type);

  void operator[]=(Type type, dynamic instance) => setVariable(type, instance);

  void clear() => _instances.clear();

  /// Sets [this] to the current context and runs [method].
  dynamic runInZone(dynamic method(), {
    ZoneBinaryCallback<dynamic, dynamic, StackTrace> onError
  }) {
    _context = this;
    return Chain.capture(() async {
      return await method();
    }, onError: onError);
  }
}

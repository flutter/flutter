// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

int _nextServiceId = 1;

// TODO(ajohnsen): Use other way of getting a unique id.
mixin _ServiceObject {
  int __serviceId = 0;
  int get _serviceId {
    if (__serviceId == 0) __serviceId = _nextServiceId++;
    return __serviceId;
  }

  String get _servicePath => "$_serviceTypePath/$_serviceId";

  String get _serviceTypePath;

  String get _serviceTypeName;

  String _serviceType(bool ref) {
    if (ref) return "@$_serviceTypeName";
    return _serviceTypeName;
  }
}

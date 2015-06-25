// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Variable {
  double value = 0.0;
  String name;

  int _tick;
  static int _total = 0;

  Variable(this.value) : _tick = _total++;

  // TODO(csg): Add external variable update callbacks here

  String get debugName => _elvis(name, "variable${_tick}");

  String toString() => "${debugName}(=${value})";
}

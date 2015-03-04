// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fn;

import 'dart:async';
import 'dart:collection';
import 'dart:sky' as sky;
import 'reflect.dart' as reflect;

part 'component.dart';
part 'node.dart';
part 'style.dart';

bool _checkedMode;

bool _debugWarnings() {
  void testFn(double i) {}

  if (_checkedMode == null) {
    _checkedMode = false;
    try {
      testFn('not a double');
    } catch (ex) {
      _checkedMode = true;
    }
  }

  return _checkedMode;
}

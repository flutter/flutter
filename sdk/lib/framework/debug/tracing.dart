// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library debug_tracing;

import 'dart:sky' as sky;

dynamic trace(String name, Function f) {
  sky.window.tracing.begin(name);
  var result = f();
  sky.window.tracing.end(name);
  return result;
}

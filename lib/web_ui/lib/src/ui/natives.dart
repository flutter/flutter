// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of ui;

List<int> saveCompilationTrace() {
  if (engine.assertionsEnabled) {
    throw UnimplementedError('saveCompilationTrace is not implemented on the web.');
  }
  throw UnimplementedError();
}

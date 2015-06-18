// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

void main() {
  initUnit();

  test("createText(null) shouldn't crash", () {
    var doc = new sky.Document();
    doc.createText(null);
  });
}

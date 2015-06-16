// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../examples/rendering/sector_layout.dart';
import '../resources/display_list.dart';

void main() {
  new TestRenderView(buildSectorExample()).endTest();
}

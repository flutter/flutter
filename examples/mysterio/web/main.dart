// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mysterio/main.dart' as entrypoint;
import 'dart:ui' as ui;

void main() {
  ui.webOnlyInitializeEngine();
  entrypoint.main();
}
// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:mysterio/main.dart' as entrypoint;

void main() {
  ui.webOnlyInitializeEngine(); // ignore: undefined_function
  entrypoint.main();
}

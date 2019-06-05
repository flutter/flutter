// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'main.dart' as entrypoint;

Future<void> main() async {
  await ui.webOnlyInitializePlatform(); // ignore: undefined_function
  entrypoint.main();
}
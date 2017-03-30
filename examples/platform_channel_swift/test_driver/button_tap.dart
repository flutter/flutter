// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:platform_channel_swift/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}

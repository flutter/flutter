// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

/// This application displays text passed through a --dart-define.
void main() {
  enableFlutterDriverExtension();
  runApp(
    const Center(
      child: Text(
        String.fromEnvironment('test.valueA') + String.fromEnvironment('test.valueB'),
        textDirection: TextDirection.ltr,
      ),
    ),
  );
}

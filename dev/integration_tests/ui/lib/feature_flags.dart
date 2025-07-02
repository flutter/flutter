// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: implementation_imports
import 'package:flutter/src/foundation/_features.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

/// This application displays the framework's enabled feature flags as a string.
void main() {
  enableFlutterDriverExtension();
  runApp(
    Center(
      child: Text(
        // ignore: invalid_use_of_internal_member
        'Feature flags: "$debugEnabledFeatureFlags"',
        textDirection: TextDirection.ltr,
      ),
    ),
  );
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();

  final Color color = defaultTargetPlatform == TargetPlatform.macOS
    ? const Color.from(red: 1, green: 0, blue: 0, alpha: 1, colorSpace: ColorSpace.displayP3)
    : const Color(0xFFFF0000);

  runApp(Container(color: color));
}

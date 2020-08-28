// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:macrobenchmarks/common.dart';
import 'package:macrobenchmarks/main.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  runApp(const MacrobenchmarksApp(initialRoute: kLargeImageChangerRouteName));
}

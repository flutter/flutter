// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(https://fxbug.dev/84961): Fix null safety and remove this language version.
// @dart=2.9

// This is an instrumented test application. It has a single field, is
// able to receive keyboard input from the test fixture, and is able to report
// back the contents of its text field to the test fixture.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';

import 'package:fidl_fuchsia_ui_test_input/fidl_async.dart' as test_text;
import 'package:fuchsia_services/services.dart';

int main() {
  // TODO(https://fxbug.dev/107917): Port https://cs.opensource.google/fuchsia/fuchsia/+/main:src/ui/tests/integration_input_tests/text-input/text-input-flutter/lib/text-input-flutter.dart
  // to dart:ui.
  print('text-input-view: starting');
}

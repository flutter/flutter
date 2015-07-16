// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Make sure that we are generating valid Dart code for all mojom interface
// tests.
// vmoptions: --compile_all

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_testing/expect.dart';
import 'package:mojo/application.dart';
import 'package:mojo/bindings.dart';
import 'package:mojo/core.dart';
import 'package:mojom/mojo/application.mojom.dart';
import 'package:mojom/mojo/service_provider.mojom.dart';
import 'package:mojom/mojo/shell.mojom.dart';
import 'package:mojom/math/math_calculator.mojom.dart';
import 'package:mojom/no_module.mojom.dart';
import 'package:mojom/mojo/test/rect.mojom.dart';
import 'package:mojom/regression_tests/regression_tests.mojom.dart';
import 'package:mojom/sample/sample_factory.mojom.dart';
import 'package:mojom/imported/sample_import2.mojom.dart';
import 'package:mojom/imported/sample_import.mojom.dart';
import 'package:mojom/sample/sample_interfaces.mojom.dart';
import 'package:mojom/sample/sample_service.mojom.dart';
import 'package:mojom/mojo/test/serialization_test_structs.mojom.dart';
import 'package:mojom/mojo/test/test_structs.mojom.dart';
import 'package:mojom/mojo/test/validation_test_interfaces.mojom.dart';

int main() {
  return 0;
}

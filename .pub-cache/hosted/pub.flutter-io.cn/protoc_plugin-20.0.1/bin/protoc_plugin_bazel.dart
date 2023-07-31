#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:protoc_plugin/bazel.dart';
import 'package:protoc_plugin/protoc.dart';

void main() {
  var packages = <String, BazelPackage>{};
  CodeGenerator(stdin, stdout).generate(
      optionParsers: {bazelOptionId: BazelOptionParser(packages)},
      config: BazelOutputConfiguration(packages));
}

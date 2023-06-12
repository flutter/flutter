// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VM protobuf serialization/deserialization benchmark.
///
/// Finds all files matching dataset*.pb pattern and loads benchmark
/// [Dataset]s from them.
library benchmark_vm;

import 'dart:io';

import 'common.dart';

void main() {
  final datasets = datasetFiles
      .map((file) => Dataset.fromBinary(File(file).readAsBytesSync()))
      .toList(growable: false);

  run(datasets);
}

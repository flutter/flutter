// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// JS protobuf serialization/deserialization benchmark.
///
/// Loads benchmark [Dataset]s from the predefined list of files
/// using D8's builtin readbuffer.
library benchmark_js;

import 'common.dart';
import 'd8.dart';

void main() {
  final datasets = datasetFiles
      .map((file) => Dataset.fromBinary(readAsBytesSync(file)))
      .toList(growable: false);

  run(datasets);
}

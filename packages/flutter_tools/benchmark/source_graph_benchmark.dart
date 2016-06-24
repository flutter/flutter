// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/dart/source_graph.dart';

void main() {
  Directory directory = new Directory('../../examples/flutter_gallery');
  SourceGraph graph = new SourceGraph(directory, 'lib/main.dart');

  Stopwatch stopwatch = new Stopwatch()..start();
  graph.initialParse();
  stopwatch.stop();
  print('${graph.sources.length} sources parsed in ${stopwatch.elapsedMilliseconds}ms.');

  // TODO(devoncarew): Benchmark an incremental `reparseSources()` mode.
}

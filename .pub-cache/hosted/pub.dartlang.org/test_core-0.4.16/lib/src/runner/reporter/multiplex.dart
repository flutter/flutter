// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../reporter.dart';

class MultiplexReporter implements Reporter {
  Iterable<Reporter> delegates;

  MultiplexReporter(this.delegates);

  @override
  void pause() {
    for (var d in delegates) {
      d.pause();
    }
  }

  @override
  void resume() {
    for (var d in delegates) {
      d.resume();
    }
  }
}

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Restarter {
  /// Attemps to perform a hot restart and returns whether it was successful or
  /// not.
  Future<bool> restart({String? runId});
}

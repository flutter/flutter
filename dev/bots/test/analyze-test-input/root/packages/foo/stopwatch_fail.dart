// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This should fail analysis.

void main() {
  Stopwatch();

  // Identify more than one in a file.
 Stopwatch myStopwatch;
  myStopwatch = Stopwatch();
  myStopwatch.reset();
}

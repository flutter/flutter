// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Testing

/// Implements a main entry point for a Swift Testing test runner.
///
/// Launches the test runner, and returns 0 if all tests pass, non-zero otherwise.
@main struct SwiftTestingMain {
  static func main() async {
    let runner = SwiftTestingRunner()
    let exitCode = await runner.run()
    exit(exitCode)
  }
}

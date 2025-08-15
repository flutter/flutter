// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Testing

@main
struct TestApp {
  static func main() async {
    let exitCode: CInt = await Testing.__swiftPMEntryPoint(passing: nil)
    exit(exitCode)
  }
}

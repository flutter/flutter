// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import SwiftUI

struct FlutterViewControllerRepresentable: UIViewControllerRepresentable {
  @Environment(AppDelegate.self) var appDelegate

  func makeUIViewController(context: Context) -> some UIViewController {
    return FlutterViewController(
      engine: appDelegate.flutterEngine,
      nibName: nil,
      bundle: nil
    )
  }

  func updateUIViewController(
    _ uiViewController: UIViewControllerType,
    context: Context
  ) {}
}

struct ContentView: View {
  var body: some View {
    FlutterViewControllerRepresentable()
  }
}

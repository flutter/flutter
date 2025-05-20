// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit
import SwiftUI
import Translation

@available(iOS 17.4, *)
@objc(FlutterTranslateController)
public class FlutterTranslateController: UIViewController {

  @available(iOS 17.4, *)
  @objc public func showTranslateUI(word: String) {
    print("Showing translate UI for word: \(word)")

  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    print("Dear god print")
    let swiftUIController = swiftUIWrapper()

    addChild(swiftUIController)
    view.addSubview(swiftUIController.view)
    swiftUIController.didMove(toParent: self) 
  }

  @available(iOS 17.4, *)
  @objc public func swiftUIWrapper() -> UIViewController {
    let hostingController = UIHostingController(rootView: ContentView())
    hostingController.view.backgroundColor = .clear
    return hostingController;
  }
}

@available(iOS 17.4, *)
struct ContentView: View {
  @available(iOS 17.4, *)
  @State private var isTranslationPopoverShown = true
  private var originalText = "bienvenue"
  var body: some View {
    Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .translationPresentation(
          isPresented: $isTranslationPopoverShown, text: originalText)
  }
}





// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.4, *)
@objc(FlutterTranslateController)
public class FlutterTranslateController: UIViewController {

  @available(iOS 13.4, *)
  @objc public func showTranslateUI(word: String) {
    print("Showing translate UI for word: \(word)")

  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    print("Dear god print")
    let swiftUIController = swiftUIWrapper()

    addChild(swiftUIController)
    view.addSubview(swiftUIController.view)

    swiftUIController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        swiftUIController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        swiftUIController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
        swiftUIController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        swiftUIController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
    swiftUIController.didMove(toParent: self) 
  }

  @available(iOS 13.4, *)
  @objc public func swiftUIWrapper() -> UIViewController {
    let hostingController = UIHostingController(rootView: ContentView())
    return hostingController;
  }
}

@available(iOS 13.4, *)
struct ContentView: View {
  @available(iOS 13.4, *)
  var body: some View {
    Rectangle()
        .fill(.red)
        .frame(width: 200, height: 200)
  }
}





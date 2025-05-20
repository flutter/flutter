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

  private let originalText: String

  @objc public init(term: String) {
    self.originalText = term;
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    self.originalText = ""
    super.init(coder: aDecoder)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let swiftUIController = getSwiftUITranslateController(termToTranslate: originalText)

    addChild(swiftUIController)
    view.addSubview(swiftUIController.view)
    swiftUIController.didMove(toParent: self) 
  }

  @available(iOS 17.4, *)
  @objc public func getSwiftUITranslateController(termToTranslate: String) -> UIViewController {
    let hostingController = UIHostingController(rootView: ContentView(termToTranslate: termToTranslate))
    hostingController.view.backgroundColor = .clear
    return hostingController;
  }
}

@available(iOS 17.4, *)
struct ContentView: View {
  @State private var isTranslationPopoverShown = true
  let termToTranslate : String;
  var body: some View {
    Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .translationPresentation(
          isPresented: $isTranslationPopoverShown, text: termToTranslate)
  }
}





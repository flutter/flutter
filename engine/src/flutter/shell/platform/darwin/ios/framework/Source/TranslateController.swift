// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit
import SwiftUI
import Translation

@available(iOS 17.4, *)
@objc(TranslateController)
public class TranslateController: UIViewController {

  private let originalText: String
  private let ipadBounds: CGRect?

  @objc public init(term: String) {
    self.originalText = term
    self.ipadBounds = nil
    super.init(nibName: nil, bundle: nil)
  }

  @objc public init(term: String, ipadBounds: CGRect) {
    self.originalText = term
    self.ipadBounds = ipadBounds
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let swiftUIViewController = makeTranslateHostingController(termToTranslate: originalText)

    addChild(swiftUIViewController)
    view.addSubview(swiftUIViewController.view)

    swiftUIViewController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        swiftUIViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
        swiftUIViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        swiftUIViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        swiftUIViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
    swiftUIViewController.didMove(toParent: self)
  }

  @objc public func makeTranslateHostingController(termToTranslate: String) -> UIViewController {
    let hostingController = UIHostingController(rootView: ContentView(termToTranslate: termToTranslate, ipadBounds: ipadBounds))
    hostingController.view.backgroundColor = .clear
    return hostingController
  }
}

@available(iOS 17.4, *)
struct ContentView: View {
  @State private var isTranslationPopoverShown = true
  let termToTranslate : String
  let ipadBounds: CGRect?
  var body: some View {
    Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .translationPresentation(
          isPresented: $isTranslationPopoverShown,
          text: termToTranslate,
          attachmentAnchor: ipadBounds != nil ? .rect(.rect(ipadBounds!)) : .rect(.bounds))
  }
}

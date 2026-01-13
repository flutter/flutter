// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit
import SwiftUI
import Translation

/// A wrapper view controller that exposes the SwiftUI translation view to Objective-C.
///
/// This is necessary because UIHostingController is a generic class and cannot
/// be imported directly into Objective-C.
@available(iOS 17.4, *)
@objc(FLTTranslateController)
class TranslateController: UIViewController {

  private let termToTranslate: String
  private let ipadBounds: CGRect?

  @objc init(term: String) {
    self.termToTranslate = term
    self.ipadBounds = nil
    super.init(nibName: nil, bundle: nil)
  }

  @objc init(term: String, ipadBounds: CGRect) {
    self.termToTranslate = term
    self.ipadBounds = ipadBounds
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let swiftUIViewController = makeTranslateHostingController(termToTranslate: termToTranslate)

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

  @objc func makeTranslateHostingController(termToTranslate: String) -> UIViewController {
    var contentView = ContentView(termToTranslate: termToTranslate, ipadBounds: ipadBounds)
    contentView.onDismiss = { [weak self] in
          guard let self = self else { return }
          self.willMove(toParent: nil)
          self.view.removeFromSuperview()
          self.removeFromParent()
        }

    let hostingController = UIHostingController(rootView: contentView)
    hostingController.view.backgroundColor = .clear
    return hostingController
  }
}

@available(iOS 17.4, *)
struct ContentView: View {
  let termToTranslate : String
  let ipadBounds: CGRect?

  var onDismiss: (() -> Void)?

  private var anchorSource: Anchor<CGRect>.Source {
          if let rect = ipadBounds {
              return .rect(rect)
          }
          return .bounds
      }

  var body: some View {
    Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .translationPresentation(
            isPresented: Binding(
              get: { true },
              set: { isShown in
                if !isShown {
                  onDismiss?()
                }
              }
            ),
            text: termToTranslate,
            attachmentAnchor: .rect(anchorSource)
        )
  }
}

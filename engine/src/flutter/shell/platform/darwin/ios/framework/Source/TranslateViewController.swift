// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import SwiftUI
import Translation
import UIKit

/// A wrapper view controller that exposes the SwiftUI translation view to Objective-C.
///
/// This is necessary because UIHostingController is a generic class and cannot
/// be imported directly into Objective-C.
@available(iOS 17.4, *)
@objc(FlutterTranslateViewController)
final class TranslateViewController: UIViewController {

  private let termToTranslate: String
  private let popoverSourceRect: CGRect?

  @objc init(term: String) {
    self.termToTranslate = term
    self.popoverSourceRect = nil
    super.init(nibName: nil, bundle: nil)
  }

  @objc init(term: String, popoverSourceRect: CGRect) {
    self.termToTranslate = term
    self.popoverSourceRect = popoverSourceRect
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let swiftUIViewController = makeTranslateHostingController(
      termToTranslate: termToTranslate
    )

    addChild(swiftUIViewController)
    view.addSubview(swiftUIViewController.view)

    swiftUIViewController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      swiftUIViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      swiftUIViewController.view.bottomAnchor.constraint(
        equalTo: view.bottomAnchor
      ),
      swiftUIViewController.view.leadingAnchor.constraint(
        equalTo: view.leadingAnchor
      ),
      swiftUIViewController.view.trailingAnchor.constraint(
        equalTo: view.trailingAnchor
      ),
    ])
    swiftUIViewController.didMove(toParent: self)
  }

  private func makeTranslateHostingController(termToTranslate: String) -> UIViewController {
    var contentView = TranslateContentView(
      termToTranslate: termToTranslate,
      popoverSourceRect: popoverSourceRect
    )
    contentView.onDismiss = { [weak self] in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
      }
    }

    let hostingController = UIHostingController(rootView: contentView)
    hostingController.view.backgroundColor = .clear
    return hostingController
  }
}

@available(iOS 17.4, *)
private struct TranslateContentView: View {
  fileprivate let termToTranslate: String
  fileprivate let popoverSourceRect: CGRect?

  fileprivate var onDismiss: (() -> Void)?

  private var anchorSource: Anchor<CGRect>.Source {
    // When a popoverSourceRect is provided (e.g. on iPad), the translate
    // screen is presented in a popover view anchored to the source rect.
    // Otherwise (e.g. on iPhone), it is presented as a sheet and uses the
    // entire view bounds.
    if let rect = popoverSourceRect {
      return .rect(rect)
    }
    return .bounds
  }

  var body: some View {
    Color.clear
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .allowsHitTesting(false)
      .translationPresentation(
        isPresented: Binding(
          get: { true },
          set: { shown in
            if !shown {
              onDismiss?()
              // If presenting the translation sheet/popover ever fails, this view
              // will not receive a dismissal event and would remain in the view hierarchy.
              // We make it transparent to touches via allowsHitTesting(false) above
              // to prevent the app from becoming unresponsive.
            }
          }
        ),
        text: termToTranslate,
        attachmentAnchor: .rect(anchorSource)
      )
  }
}

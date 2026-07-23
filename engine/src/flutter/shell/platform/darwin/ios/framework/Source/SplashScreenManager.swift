// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

/// Manages the loading, display, and removal of the application's splash screen.
///
/// Handles loading from storyboards or XIBs based on the `UILaunchStoryboardName` in the app's
/// Info.plist. Performs an animated fade-out transition when the splash screen is removed.
@objc(FlutterSplashScreenManager)
public final class SplashScreenManager: NSObject {

  /// The default duration for the splash screen fade-out animation.
  private static let defaultAnimationDuration: TimeInterval = 0.2

  private let bundle: Bundle

  private var _splashScreenView: UIView?

  /// The current splash screen view.
  ///
  /// Setting this property to a new view will update view and apply flexible width/height
  /// autoresizing masks. Setting to `nil` will trigger the removal of the current splash screen
  /// with a fade-out animation.
  @objc public var splashScreenView: UIView? {
    get { return _splashScreenView }
    set {
      guard newValue !== _splashScreenView else { return }

      if let newView = newValue {
        _splashScreenView = newView
        newView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      } else {
        removeSplashScreen(completion: nil)
      }
    }
  }

  /// Initializes a new manager with the specified bundle.
  ///
  /// The bundle is used to look up the launch storyboard name and resources.
  @objc public init(bundle: Bundle = .main) {
    self.bundle = bundle
    super.init()
  }

  /// Initializes a new manager with the main bundle.
  @objc public override convenience init() {
    self.init(bundle: .main)
  }

  /// Attempts to load the splash screen view specified by `UILaunchStoryboardName` in Info.plist.
  /// - Returns: `true` if successful, `false` otherwise.
  @discardableResult
  @objc public func loadDefaultSplashScreenView() -> Bool {
    guard let launchscreenName = bundle.infoDictionary?["UILaunchStoryboardName"] as? String else {
      return false
    }

    var splashView = splashScreenFromStoryboard(name: launchscreenName)
    if splashView == nil {
      splashView = splashScreenFromXib(name: launchscreenName)
    }

    guard let view = splashView else { return false }

    splashScreenView = view
    return true
  }

  /// Loads a view from the initial view controller of the specified storyboard.
  private func splashScreenFromStoryboard(name: String) -> UIView? {
    // Check if storyboard exists to prevent exceptions.
    guard bundle.path(forResource: name, ofType: "storyboardc") != nil else { return nil }

    let storyboard = UIStoryboard(name: name, bundle: bundle)
    let splashScreenViewController = storyboard.instantiateInitialViewController()
    return splashScreenViewController?.view
  }

  /// Loads a view from the specified XIB file.
  private func splashScreenFromXib(name: String) -> UIView? {
    // Check if nib exists to prevent exceptions.
    guard bundle.path(forResource: name, ofType: "nib") != nil else { return nil }

    let nib = UINib(nibName: name, bundle: bundle)
    let objects = nib.instantiate(withOwner: nil, options: nil)
    return objects.first as? UIView
  }

  /// Removes the splash screen with a fade-out animation.
  ///
  /// The completion block is invoked after the animation completes and the view is removed from its
  /// superview.
  @objc public func removeSplashScreen(completion: (() -> Void)?) {
    // If no splash screen, bail out immediately and invoke the completion handler.
    guard let splashScreen = _splashScreenView else {
      completion?()
      return
    }

    _splashScreenView = nil
    UIView.animate(
      withDuration: Self.defaultAnimationDuration,
      animations: {
        splashScreen.alpha = 0
      }
    ) { _ in
      splashScreen.removeFromSuperview()
      completion?()
    }
  }

  /// Installs the splash screen view into the specified parent view, if it is not already added.
  ///
  /// The view's frame is set to match the parent view's bounds.
  @objc public func installSplashScreenView(asSubviewOf parentView: UIView) {
    guard let splashScreen = splashScreenView else { return }

    splashScreen.frame = parentView.bounds
    parentView.addSubview(splashScreen)
  }
}

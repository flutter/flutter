// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

@objc public enum FlutterKeyboardMode: Int {
  case hidden
  case docked
  case floating
}

public typealias FlutterKeyboardAnimationCallback = (_ targetTime: CFTimeInterval) -> Void

/// @brief Coordinates the animation of the bottom viewport inset in response to system keyboard
/// visibility changes.
///
/// This manager translates native iOS keyboard notifications into pixel insets for the engine. It
/// ensures that the Flutter app UI correctly resizes or scrolls when the software keyboard appears
/// or disappears.
///
/// We synchronize the app's layout transitions with the native keyboard animation curve by tracking
/// a hidden internal view. When a keyboard notification is received, this view is animated using the
/// native iOS duration and curve. The manager tracks this animation and calls the delegate's update
/// methods on every vsync pulse until the transition completes.
///
/// iOS doesn't provide us with a frame-by-frame callback for keyboard transitions, but we need to
/// animate our views smoothly to account for keyboard size/position changes. To ensure Flutter's
/// layout animates in perfect sync with the system keyboard, we use a "hidden view" synchronization
/// trick:
///
///  * When a keyboard notification (e.g., UIKeyboardWillShow) is received, the manager animates a
///    hidden UIView's frame using the native iOS duration and curve.
///  * A VSyncClient tracks the 'presentationLayer' of this hidden view on every vsync.
///  * The intermediate positions are then translated into physical pixel insets and sent to the
///    engine until the animation completes.
///
/// To prevent incorrect layout shifts, the manager filters notifications based on the following
/// criteria:
///
/// * Local notifications:
///   In multitasking environments, such as iPad Split View, notifications triggered by interactions
///   with other applications are ignored.
///
/// * Keyboard attachment mode:
///   The manager distinguishes between "docked" keyboards, which cover the bottom of the viewport,
///   and "floating" or "undocked" keyboards. Floating keyboards do not typically require a viewport
///   inset and are ignored to allow them to hover over the Flutter content without resizing the
///   layout.
///
/// * View lifecycle:
///   Notifications are ignored if the associated view is not loaded or if the delegate is not the
///   active view controller.
///
/// @see [FlutterViewController], which owns this manager and acts as its delegate.
@objc public protocol FlutterKeyboardInsetManagerDelegate: NSObjectProtocol {
  @objc(updateViewportMetricsWithInset:)
  func updateViewportMetrics(withInset inset: CGFloat)
  func physicalViewInsetBottom() -> CGFloat
  func uiTaskRunner() -> TaskRunner?
  func view() -> UIView
  func engine() -> FlutterEngine?
  func flutterScreenIfViewLoaded() -> UIScreen?
  func isPadInSlideOverOrStageManagerMode() -> Bool
  @objc(convertViewRectToScreen:)
  func convertViewRect(toScreen rect: CGRect) -> CGRect
  func isViewLoaded() -> Bool
}

@objc public protocol FlutterKeyboardInsetManagerProtocol: NSObjectProtocol {
  var delegate: FlutterKeyboardInsetManagerDelegate? { get set }
  var targetViewInsetBottom: CGFloat { get set }
  var isKeyboardInOrTransitioningFromBackground: Bool { get set }
  var keyboardAnimationVSyncClient: VSyncClient? { get }

  func handleKeyboardNotification(_ notification: Notification)
  func hideKeyboardImmediately()
  func invalidate()
  func invalidateKeyboardAnimationVSyncClient()
  func startKeyBoardAnimation(_ duration: TimeInterval)
  var keyboardAnimationView: UIView? { get }
  var keyboardSpringAnimation: SpringAnimation? { get }
  func setUpKeyboardSpringAnimationIfNeeded(_ keyboardAnimation: CAAnimation?)
  func shouldIgnoreKeyboardNotification(_ notification: Notification) -> Bool
  func setUpKeyboardAnimationVsyncClient(_ animationCallback: FlutterKeyboardAnimationCallback?)
  func calculateKeyboardAttachMode(_ notification: Notification) -> FlutterKeyboardMode
  func ensureViewportMetricsIsCorrect()
}

@objc open class FlutterKeyboardInsetManager: NSObject, FlutterKeyboardInsetManagerProtocol {
  @objc public weak var delegate: FlutterKeyboardInsetManagerDelegate?
  @objc public var targetViewInsetBottom: CGFloat = 0

  private var originalViewInsetBottom: CGFloat = 0
  @objc public var keyboardAnimationVSyncClient: VSyncClient?
  @objc public var keyboardAnimationIsShowing: Bool = false
  private var keyboardAnimationStartTime: CFTimeInterval = 0
  @objc public var keyboardAnimationView: UIView?
  @objc public var keyboardSpringAnimation: SpringAnimation?
  @objc public var isKeyboardInOrTransitioningFromBackground: Bool = false

  @objc public init(delegate: FlutterKeyboardInsetManagerDelegate) {
    self.delegate = delegate
    super.init()
  }

  @objc public func handleKeyboardNotification(_ notification: Notification) {
    // See https://flutter.dev/go/ios-keyboard-calculating-inset for more details on why
    // notifications are used and how things are calculated.
    guard delegate != nil else { return }
    if shouldIgnoreKeyboardNotification(notification) {
      return
    }

    let info = notification.userInfo
    let beginKeyboardFrame =
      (info?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
    let keyboardFrame =
      (info?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
    let keyboardMode = calculateKeyboardAttachMode(notification)
    let calculatedInset = calculateKeyboardInset(keyboardFrame, keyboardMode: keyboardMode)
    let duration =
      info?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0

    // If the software keyboard is displayed before displaying the PasswordManager prompt,
    // UIKeyboardWillHideNotification will occur immediately after UIKeyboardWillShowNotification.
    // The duration of the animation will be 0.0, and the calculated inset will be 0.0. In this
    // case, it is necessary to cancel the animation and hide the keyboard immediately.
    // https://github.com/flutter/flutter/pull/164884
    if keyboardMode == .hidden && calculatedInset == 0.0 && duration == 0.0 {
      hideKeyboardImmediately()
      return
    }

    // Avoid double triggering startKeyBoardAnimation.
    if targetViewInsetBottom == calculatedInset {
      return
    }
    targetViewInsetBottom = calculatedInset

    // Flag for simultaneous compounding animation calls.
    // This captures animation calls made while the keyboard animation is currently animating. If
    // the new animation is in the same direction as the current animation, this flag lets the
    // current animation continue with an updated targetViewInsetBottom instead of starting a new
    // keyboard animation. This allows for smoother keyboard animation interpolation.
    let keyboardWillShow = beginKeyboardFrame.origin.y > keyboardFrame.origin.y
    let keyboardAnimationIsCompounding =
      keyboardAnimationIsShowing == keyboardWillShow && keyboardAnimationVSyncClient != nil

    // Mark keyboard as showing or hiding.
    keyboardAnimationIsShowing = keyboardWillShow

    if !keyboardAnimationIsCompounding {
      startKeyBoardAnimation(duration)
    } else if let keyboardSpringAnimation = keyboardSpringAnimation {
      keyboardSpringAnimation.toValue = targetViewInsetBottom
    }
  }

  @objc public func shouldIgnoreKeyboardNotification(_ notification: Notification) -> Bool {
    // Don't ignore UIKeyboardWillHideNotification notifications.
    // Even if the notification is triggered in the background or by a different app/view
    // controller, we want to always handle this notification to avoid inaccurate inset when in a
    // multitasking mode or when switching between apps.
    if notification.name == UIResponder.keyboardWillHideNotification {
      return false
    }

    let info = notification.userInfo
    let keyboardFrame =
      (info?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero

    // Ignore notification when keyboard's dimensions and position are all zeroes for
    // UIKeyboardWillChangeFrameNotification. This happens when keyboard is dragged. Do not ignore
    // if the notification is UIKeyboardWillShowNotification, as CGRectZero for that notification
    // only occurs when Minimized/Expanded Shortcuts Bar is dropped after dragging, which we later
    // use to categorize it as floating.
    if notification.name == UIResponder.keyboardWillChangeFrameNotification
      && keyboardFrame == .zero
    {
      return true
    }

    // When keyboard's height or width is set to 0, don't ignore. This does not happen often but can
    // happen sometimes when switching between multitasking modes.
    if keyboardFrame.isEmpty {
      return false
    }

    // Ignore keyboard notifications related to other apps or view controllers.
    if isKeyboardNotificationForDifferentView(notification) {
      return true
    }
    return false
  }

  @objc public func isKeyboardNotificationForDifferentView(_ notification: Notification) -> Bool {
    let info = notification.userInfo
    // Keyboard notifications related to other apps (e.g. in split view mode on iPad).
    // If the UIKeyboardIsLocalUserInfoKey key doesn't exist (this should not happen after iOS 8),
    // proceed as if it was local so that the notification is not ignored.
    if let isLocal = info?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool, !isLocal {
      return true
    }
    guard let delegate else { return false }
    return delegate.engine()?.viewController !== (delegate as AnyObject)
  }

  @objc public func calculateKeyboardAttachMode(_ notification: Notification) -> FlutterKeyboardMode
  {
    // There are multiple types of keyboard: docked, undocked, split, split docked,
    // floating, expanded shortcuts bar, minimized shortcuts bar.
    //
    // This function will categorize the keyboard as one of the following modes: docked, floating,
    // or hidden.
    //
    // Docked mode includes docked, split docked, expanded shortcuts bar (when opening via click),
    // and minimized shortcuts bar (when opened via click).
    //
    // Floating includes undocked, split, floating, expanded shortcuts bar (when dragged and
    // dropped), and minimized shortcuts bar (when dragged and dropped).
    guard let delegate else { return .hidden }

    if notification.name == UIResponder.keyboardWillHideNotification {
      return .hidden
    }

    let info = notification.userInfo
    let keyboardFrame =
      (info?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero

    // If keyboard's dimensions and position are all zeroes, that means it's a Minimized/Expanded
    // Shortcuts Bar that has been dropped after dragging, which we categorize as floating.
    if keyboardFrame == .zero {
      return .floating
    }

    // If keyboard's width or height are 0, it's hidden.
    if keyboardFrame.isEmpty {
      return .hidden
    }

    guard let screen = delegate.flutterScreenIfViewLoaded() else {
      return .hidden
    }

    let screenRect = screen.bounds
    var adjustedKeyboardFrame = keyboardFrame
    adjustedKeyboardFrame.origin.y += calculateMultitaskingAdjustment(
      screenRect, keyboardFrame: keyboardFrame)

    // If the keyboard is partially or fully showing within the screen, it's either docked or
    // floating. Sometimes with custom keyboard extensions, the keyboard's position may be off by a
    // small decimal amount (which is why CGRectIntersectRect can't be used). Round to compare.
    let intersection = adjustedKeyboardFrame.intersection(screenRect)
    let intersectionHeight = intersection.height
    let intersectionWidth = intersection.width

    if round(intersectionHeight) > 0 && intersectionWidth > 0 {
      let adjustedKeyboardBottom = adjustedKeyboardFrame.maxY
      let screenHeight = screenRect.height

      if round(adjustedKeyboardBottom) < screenHeight {
        return .floating
      }
      return .docked
    }
    return .hidden
  }

  @objc public func calculateMultitaskingAdjustment(_ screenRect: CGRect, keyboardFrame: CGRect)
    -> CGFloat
  {
    guard let delegate else { return 0 }
    if !delegate.isViewLoaded() {
      return 0
    }

    // In Slide Over mode, the keyboard's frame does not include the space below the app, even
    // though the keyboard may be at the bottom of the screen. To handle, shift the Y origin by the
    // amount of space below the app.
    if delegate.isPadInSlideOverOrStageManagerMode() {
      let screenHeight = screenRect.height
      let keyboardBottom = keyboardFrame.maxY

      // Stage Manager mode will also meet the above parameters, but it does not handle the keyboard
      // positioning the same way, so skip if keyboard is at bottom of page.
      if screenHeight == keyboardBottom {
        return 0
      }

      let offset = screenHeight - delegate.convertViewRect(toScreen: delegate.view().bounds).maxY
      if offset > 0 {
        return offset
      }
    }
    return 0
  }

  @objc public func calculateKeyboardInset(
    _ keyboardFrame: CGRect, keyboardMode: FlutterKeyboardMode
  ) -> CGFloat {
    // Only docked keyboards will have an inset.
    if keyboardMode != .docked {
      return 0
    }

    guard let delegate, delegate.isViewLoaded() else { return 0 }
    let viewRectRelativeToScreen = delegate.convertViewRect(toScreen: delegate.view().bounds)
    let intersection = keyboardFrame.intersection(viewRectRelativeToScreen)
    let portionOfKeyboardInView = intersection.height

    // The keyboard is treated as an inset since we want to effectively reduce the window size by
    // the keyboard height. The Dart side will compute a value accounting for the keyboard-consuming
    // bottom padding.
    let scale = delegate.flutterScreenIfViewLoaded()?.scale ?? 0.0
    return portionOfKeyboardInView * scale
  }

  @objc public func startKeyBoardAnimation(_ duration: TimeInterval) {
    guard let delegate, delegate.isViewLoaded() else { return }
    let view = delegate.view()

    // When this method is called for the first time, initialize the keyboardAnimationView to get
    // animation interpolation during animation.
    if keyboardAnimationView == nil {
      let animView = UIView()
      animView.isHidden = true
      keyboardAnimationView = animView
    }

    if let keyboardAnimationView = keyboardAnimationView,
      keyboardAnimationView.superview != view
    {
      view.addSubview(keyboardAnimationView)
    }

    // Remove running animation when start another animation.
    keyboardAnimationView?.layer.removeAllAnimations()

    // If current physical_view_inset_bottom == targetViewInsetBottom, do nothing.
    let currentInset = delegate.physicalViewInsetBottom()
    keyboardAnimationView?.frame = CGRect(x: 0, y: currentInset, width: 0, height: 0)

    // Set animation begin value and DisplayLink tracking values.
    keyboardAnimationStartTime = CACurrentMediaTime()
    originalViewInsetBottom = currentInset

    // Invalidate old vsync client if old animation is not completed.
    invalidateKeyboardAnimationVSyncClient()

    setUpKeyboardAnimationVsyncClient { [weak self] targetTime in
      self?.handleKeyboardAnimationCallback(withTargetTime: targetTime)
    }

    let currentVsyncClient = keyboardAnimationVSyncClient

    UIView.animate(
      withDuration: duration,
      animations: { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.keyboardAnimationView?.frame = CGRect(
          x: 0, y: strongSelf.targetViewInsetBottom, width: 0, height: 0)
        strongSelf.keyboardAnimationView?.layoutIfNeeded()

        let keyboardAnimation = strongSelf.keyboardAnimationView?.layer.animation(
          forKey: "position")
        strongSelf.setUpKeyboardSpringAnimationIfNeeded(keyboardAnimation)
      },
      completion: { [weak self] finished in
        guard let strongSelf = self else { return }
        // Indicates the vsync client captured by this block is the original one, which also
        // indicates the animation has not been interrupted from its beginning. Moreover,
        // indicates the animation is over and there is no more to execute.
        if strongSelf.keyboardAnimationVSyncClient === currentVsyncClient {
          strongSelf.invalidateKeyboardAnimationVSyncClient()
          strongSelf.removeKeyboardAnimationView()
          strongSelf.ensureViewportMetricsIsCorrect()
        }
      })
  }

  @objc public func handleKeyboardAnimationCallback(withTargetTime targetTime: CFTimeInterval) {
    guard let delegate else { return }
    if !delegate.isViewLoaded() { return }

    // Bail out if the view for tracking keyboard animation is nil.
    guard let keyboardAnimationView = keyboardAnimationView else { return }

    // If keyboardAnimationVSyncClient is nil, the animation ends and we should bail out.
    if keyboardAnimationVSyncClient == nil { return }

    if keyboardAnimationView.superview != delegate.view() {
      // Ensure the keyboardAnimationView is in the view hierarchy when the animation running.
      delegate.view().addSubview(keyboardAnimationView)
    }

    var currentInset: CGFloat = 0
    if let keyboardSpringAnimation = keyboardSpringAnimation {
      let timeElapsed = targetTime - keyboardAnimationStartTime
      currentInset = CGFloat(keyboardSpringAnimation.curveFunction(timeElapsed))
    } else if let presentationLayer = keyboardAnimationView.layer.presentation() {
      currentInset = presentationLayer.frame.origin.y
    }

    delegate.updateViewportMetrics(withInset: currentInset)
  }

  @objc public func hideKeyboardImmediately() {
    invalidateKeyboardAnimationVSyncClient()
    if let keyboardAnimationView = keyboardAnimationView {
      keyboardAnimationView.layer.removeAllAnimations()
      removeKeyboardAnimationView()
      self.keyboardAnimationView = nil
    }
    keyboardSpringAnimation = nil
    targetViewInsetBottom = 0
    ensureViewportMetricsIsCorrect()
  }

  @objc public func invalidate() {
    invalidateKeyboardAnimationVSyncClient()
    removeKeyboardAnimationView()
  }

  @objc public func invalidateKeyboardAnimationVSyncClient() {
    keyboardAnimationVSyncClient?.invalidate()
    keyboardAnimationVSyncClient = nil
  }

  @objc public func removeKeyboardAnimationView() {
    if keyboardAnimationView?.superview != nil {
      keyboardAnimationView?.removeFromSuperview()
    }
  }

  @objc public func setUpKeyboardSpringAnimationIfNeeded(_ keyboardAnimation: CAAnimation?) {
    // If keyboard animation is nil or not a spring animation, fallback to DisplayLink tracking.
    guard let keyboardCASpringAnimation = keyboardAnimation as? CASpringAnimation else {
      keyboardSpringAnimation = nil
      return
    }

    // Set up keyboard spring animation details for spring curve animation calculation.
    keyboardSpringAnimation = SpringAnimation(
      stiffness: keyboardCASpringAnimation.stiffness,
      damping: keyboardCASpringAnimation.damping,
      mass: keyboardCASpringAnimation.mass,
      initialVelocity: keyboardCASpringAnimation.initialVelocity,
      fromValue: originalViewInsetBottom,
      toValue: targetViewInsetBottom
    )
  }

  @objc public func setUpKeyboardAnimationVsyncClient(
    _ animationCallback: FlutterKeyboardAnimationCallback?
  ) {
    guard let animationCallback = animationCallback else { return }
    assert(
      keyboardAnimationVSyncClient == nil,
      "keyboardAnimationVSyncClient must be nil when setting up.")

    guard let delegate, let taskRunner = delegate.uiTaskRunner() else { return }

    // Make sure the new viewport metrics get sent after the begin frame event has processed.
    let vsyncCallback: (CFTimeInterval, CFTimeInterval) -> Void = { startTime, targetTime in
      let frameInterval = targetTime - startTime
      let projectedTargetTime = targetTime + frameInterval
      DispatchQueue.main.async {
        animationCallback(projectedTargetTime)
      }
    }

    keyboardAnimationVSyncClient = VSyncClient(
      taskRunner: taskRunner,
      isVariableRefreshRateEnabled: DisplayLinkManager.shared.maxRefreshRateEnabledOnIPhone,
      maxRefreshRate: DisplayLinkManager.shared.displayRefreshRate,
      callback: vsyncCallback)
    keyboardAnimationVSyncClient?.allowPauseAfterVsync = false
    keyboardAnimationVSyncClient?.await()
  }

  @objc public func ensureViewportMetricsIsCorrect() {
    delegate?.updateViewportMetrics(withInset: targetViewInsetBottom)
  }
}

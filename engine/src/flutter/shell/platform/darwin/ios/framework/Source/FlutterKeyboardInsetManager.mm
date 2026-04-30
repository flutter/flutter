// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeyboardInsetManager.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient+FML.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/embedder/embedder.h"
#import "flutter/third_party/spring_animation/spring_animation.h"

#include <memory>

#include "flutter/fml/platform/darwin/platform_version.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"

@interface FlutterKeyboardInsetManager ()

@property(nonatomic, weak) id<FlutterKeyboardInsetManagerDelegate> delegate;
@property(nonatomic, assign, readwrite) CGFloat targetViewInsetBottom;
@property(nonatomic, assign) CGFloat originalViewInsetBottom;
@property(nonatomic, strong) FlutterVSyncClient* keyboardAnimationVSyncClient;
@property(nonatomic, assign) BOOL keyboardAnimationIsShowing;
@property(nonatomic, assign) NSTimeInterval keyboardAnimationStartTime;
@property(nonatomic, strong) UIView* keyboardAnimationView;
@property(nonatomic, strong) SpringAnimation* keyboardSpringAnimation;

@end

@implementation FlutterKeyboardInsetManager

- (instancetype)initWithDelegate:(id<FlutterKeyboardInsetManagerDelegate>)delegate {
  self = [super init];
  if (self) {
    _delegate = delegate;
    _targetViewInsetBottom = 0.0;
  }
  return self;
}

- (void)handleKeyboardNotification:(NSNotification*)notification {
  // See https://flutter.dev/go/ios-keyboard-calculating-inset for more details
  // on why notifications are used and how things are calculated.
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;
  if (!delegate || [self shouldIgnoreKeyboardNotification:notification]) {
    return;
  }

  NSDictionary* info = notification.userInfo;
  CGRect beginKeyboardFrame = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
  CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  FlutterKeyboardMode keyboardMode = [self calculateKeyboardAttachMode:notification];
  CGFloat calculatedInset = [self calculateKeyboardInset:keyboardFrame keyboardMode:keyboardMode];
  NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

  // If the software keyboard is displayed before displaying the PasswordManager prompt,
  // UIKeyboardWillHideNotification will occur immediately after UIKeyboardWillShowNotification.
  // The duration of the animation will be 0.0, and the calculated inset will be 0.0.
  // In this case, it is necessary to cancel the animation and hide the keyboard immediately.
  // https://github.com/flutter/flutter/pull/164884
  if (keyboardMode == FlutterKeyboardModeHidden && calculatedInset == 0.0 && duration == 0.0) {
    [self hideKeyboardImmediately];
    return;
  }

  // Avoid double triggering startKeyBoardAnimation.
  if (self.targetViewInsetBottom == calculatedInset) {
    return;
  }
  self.targetViewInsetBottom = calculatedInset;

  // Flag for simultaneous compounding animation calls.
  // This captures animation calls made while the keyboard animation is currently animating. If the
  // new animation is in the same direction as the current animation, this flag lets the current
  // animation continue with an updated targetViewInsetBottom instead of starting a new keyboard
  // animation. This allows for smoother keyboard animation interpolation.
  BOOL keyboardWillShow = beginKeyboardFrame.origin.y > keyboardFrame.origin.y;
  BOOL keyboardAnimationIsCompounding =
      self.keyboardAnimationIsShowing == keyboardWillShow && _keyboardAnimationVSyncClient != nil;

  // Mark keyboard as showing or hiding.
  self.keyboardAnimationIsShowing = keyboardWillShow;

  if (!keyboardAnimationIsCompounding) {
    [self startKeyBoardAnimation:duration];
  } else if (self.keyboardSpringAnimation) {
    self.keyboardSpringAnimation.toValue = self.targetViewInsetBottom;
  }
}

- (BOOL)shouldIgnoreKeyboardNotification:(NSNotification*)notification {
  // Don't ignore UIKeyboardWillHideNotification notifications.
  // Even if the notification is triggered in the background or by a different app/view controller,
  // we want to always handle this notification to avoid inaccurate inset when in a mulitasking mode
  // or when switching between apps.
  if (notification.name == UIKeyboardWillHideNotification) {
    return NO;
  }

  // Ignore notification when keyboard's dimensions and position are all zeroes for
  // UIKeyboardWillChangeFrameNotification. This happens when keyboard is dragged. Do not ignore if
  // the notification is UIKeyboardWillShowNotification, as CGRectZero for that notfication only
  // occurs when Minimized/Expanded Shortcuts Bar is dropped after dragging, which we later use to
  // categorize it as floating.
  NSDictionary* info = notification.userInfo;
  CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  if (notification.name == UIKeyboardWillChangeFrameNotification &&
      CGRectEqualToRect(keyboardFrame, CGRectZero)) {
    return YES;
  }

  // When keyboard's height or width is set to 0, don't ignore. This does not happen
  // often but can happen sometimes when switching between multitasking modes.
  if (CGRectIsEmpty(keyboardFrame)) {
    return NO;
  }

  // Ignore keyboard notifications related to other apps or view controllers.
  if ([self isKeyboardNotificationForDifferentView:notification]) {
    return YES;
  }
  return NO;
}

- (BOOL)isKeyboardNotificationForDifferentView:(NSNotification*)notification {
  NSDictionary* info = notification.userInfo;

  // Keyboard notifications related to other apps.
  // If the UIKeyboardIsLocalUserInfoKey key doesn't exist (this should not happen after iOS 8),
  // proceed as if it was local so that the notification is not ignored.
  id isLocal = info[UIKeyboardIsLocalUserInfoKey];
  if (isLocal && ![isLocal boolValue]) {
    return YES;
  }
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;
  return (id)delegate.engine.viewController != (id)delegate;
}

- (FlutterKeyboardMode)calculateKeyboardAttachMode:(NSNotification*)notification {
  // There are multiple types of keyboard: docked, undocked, split, split docked,
  // floating, expanded shortcuts bar, minimized shortcuts bar. This function will categorize
  // the keyboard as one of the following modes: docked, floating, or hidden.
  // Docked mode includes docked, split docked, expanded shortcuts bar (when opening via click),
  // and minimized shortcuts bar (when opened via click).
  // Floating includes undocked, split, floating, expanded shortcuts bar (when dragged and dropped),
  // and minimized shortcuts bar (when dragged and dropped).
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;
  if (!delegate) {
    return FlutterKeyboardModeHidden;
  }
  NSDictionary* info = notification.userInfo;
  CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];

  if (notification.name == UIKeyboardWillHideNotification) {
    return FlutterKeyboardModeHidden;
  }

  // If keyboard's dimensions and position are all zeroes, that means it's a Minimized/Expanded
  // Shortcuts Bar that has been dropped after dragging, which we categorize as floating.
  if (CGRectEqualToRect(keyboardFrame, CGRectZero)) {
    return FlutterKeyboardModeFloating;
  }
  // If keyboard's width or height are 0, it's hidden.
  if (CGRectIsEmpty(keyboardFrame)) {
    return FlutterKeyboardModeHidden;
  }

  CGRect screenRect = delegate.flutterScreenIfViewLoaded.bounds;
  CGRect adjustedKeyboardFrame = keyboardFrame;
  adjustedKeyboardFrame.origin.y += [self calculateMultitaskingAdjustment:screenRect
                                                            keyboardFrame:keyboardFrame];

  // If the keyboard is partially or fully showing within the screen, it's either docked or
  // floating. Sometimes with custom keyboard extensions, the keyboard's position may be off by a
  // small decimal amount (which is why CGRectIntersectRect can't be used). Round to compare.
  CGRect intersection = CGRectIntersection(adjustedKeyboardFrame, screenRect);
  CGFloat intersectionHeight = CGRectGetHeight(intersection);
  CGFloat intersectionWidth = CGRectGetWidth(intersection);
  if (round(intersectionHeight) > 0 && intersectionWidth > 0) {
    CGFloat screenHeight = CGRectGetHeight(screenRect);
    CGFloat adjustedKeyboardBottom = CGRectGetMaxY(adjustedKeyboardFrame);
    if (round(adjustedKeyboardBottom) < screenHeight) {
      return FlutterKeyboardModeFloating;
    }
    return FlutterKeyboardModeDocked;
  }
  return FlutterKeyboardModeHidden;
}

/**
 * @brief Calculates the adjustment needed for multitasking modes like Slide Over on iPad.
 *
 * In Slide Over mode, the keyboard's frame does not include the space below the app,
 * even though the keyboard may be at the bottom of the screen. This method calculates
 * that offset so we can shift the y origin correctly.
 */
- (CGFloat)calculateMultitaskingAdjustment:(CGRect)screenRect keyboardFrame:(CGRect)keyboardFrame {
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;
  if (!delegate.isViewLoaded) {
    return 0;
  }

  // In Slide Over mode, the keyboard's frame does not include the space
  // below the app, even though the keyboard may be at the bottom of the screen.
  // To handle, shift the Y origin by the amount of space below the app.
  UIView* view = delegate.view;
  if ([delegate isPadInSlideOverOrStageManagerMode]) {
    CGFloat screenHeight = CGRectGetHeight(screenRect);
    CGFloat keyboardBottom = CGRectGetMaxY(keyboardFrame);

    // Stage Manager mode will also meet the above parameters, but it does not handle
    // the keyboard positioning the same way, so skip if keyboard is at bottom of page.
    if (screenHeight == keyboardBottom) {
      return 0;
    }
    CGRect viewRectRelativeToScreen = [delegate convertViewRectToScreen:view.bounds];
    CGFloat viewBottom = CGRectGetMaxY(viewRectRelativeToScreen);
    CGFloat offset = screenHeight - viewBottom;
    if (offset > 0) {
      return offset;
    }
  }
  return 0;
}

- (CGFloat)calculateKeyboardInset:(CGRect)keyboardFrame
                     keyboardMode:(FlutterKeyboardMode)keyboardMode {
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;

  // Only docked keyboards will have an inset.
  if (keyboardMode == FlutterKeyboardModeDocked) {
    if (!delegate.isViewLoaded) {
      return 0;
    }
    UIView* view = delegate.view;
    CGRect viewRectRelativeToScreen = [delegate convertViewRectToScreen:view.bounds];
    CGRect intersection = CGRectIntersection(keyboardFrame, viewRectRelativeToScreen);
    CGFloat portionOfKeyboardInView = CGRectGetHeight(intersection);

    // The keyboard is treated as an inset since we want to effectively reduce the window size by
    // the keyboard height. The Dart side will compute a value accounting for the keyboard-consuming
    // bottom padding.
    CGFloat scale = delegate.flutterScreenIfViewLoaded.scale;
    return portionOfKeyboardInView * scale;
  }
  return 0;
}

- (void)startKeyBoardAnimation:(NSTimeInterval)duration {
  // If current physical_view_inset_bottom == targetViewInsetBottom, do nothing.
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;
  if (!delegate.isViewLoaded) {
    return;
  }
  UIView* view = delegate.view;

  // When this method is called for the first time,
  // initialize the keyboardAnimationView to get animation interpolation during animation.
  if (!self.keyboardAnimationView) {
    UIView* keyboardAnimationView = [[UIView alloc] init];
    keyboardAnimationView.hidden = YES;
    self.keyboardAnimationView = keyboardAnimationView;
  }

  if (self.keyboardAnimationView.superview != view) {
    [view addSubview:self.keyboardAnimationView];
  }

  // Remove running animation when start another animation.
  [self.keyboardAnimationView.layer removeAllAnimations];

  // Set animation begin value and DisplayLink tracking values.
  CGFloat currentInset = delegate.physicalViewInsetBottom;
  self.keyboardAnimationView.frame = CGRectMake(0, currentInset, 0, 0);
  self.keyboardAnimationStartTime = fml::TimePoint::Now().ToEpochDelta().ToSeconds();
  self.originalViewInsetBottom = currentInset;

  // Invalidate old vsync client if old animation is not completed.
  [self invalidateKeyboardAnimationVSyncClient];

  __weak FlutterKeyboardInsetManager* weakSelf = self;
  [self setUpKeyboardAnimationVsyncClient:^(NSTimeInterval targetTime) {
    [weakSelf handleKeyboardAnimationCallbackWithTargetTime:targetTime];
  }];
  FlutterVSyncClient* currentVsyncClient = _keyboardAnimationVSyncClient;

  [UIView animateWithDuration:duration
      animations:^{
        FlutterKeyboardInsetManager* strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        // Set end value.
        strongSelf.keyboardAnimationView.frame =
            CGRectMake(0, strongSelf.targetViewInsetBottom, 0, 0);

        // Setup keyboard animation interpolation.
        [strongSelf.keyboardAnimationView layoutIfNeeded];
        CAAnimation* keyboardAnimation =
            [strongSelf.keyboardAnimationView.layer animationForKey:@"position"];
        [strongSelf setUpKeyboardSpringAnimationIfNeeded:keyboardAnimation];
      }
      completion:^(BOOL finished) {
        FlutterKeyboardInsetManager* strongSelf = weakSelf;
        if (strongSelf && strongSelf.keyboardAnimationVSyncClient == currentVsyncClient) {
          // Indicates the vsync client captured by this block is the original one, which also
          // indicates the animation has not been interrupted from its beginning. Moreover,
          // indicates the animation is over and there is no more to execute.
          [strongSelf invalidateKeyboardAnimationVSyncClient];
          [strongSelf removeKeyboardAnimationView];
          [strongSelf ensureViewportMetricsIsCorrect];
        }
      }];
}

- (void)hideKeyboardImmediately {
  [self invalidateKeyboardAnimationVSyncClient];
  if (self.keyboardAnimationView) {
    [self.keyboardAnimationView.layer removeAllAnimations];
    [self removeKeyboardAnimationView];
    self.keyboardAnimationView = nil;
  }
  if (self.keyboardSpringAnimation) {
    self.keyboardSpringAnimation = nil;
  }
  self.targetViewInsetBottom = 0.0;
  [self ensureViewportMetricsIsCorrect];
}

- (void)setUpKeyboardSpringAnimationIfNeeded:(CAAnimation*)keyboardAnimation {
  // If keyboard animation is null or not a spring animation, fallback to DisplayLink tracking.
  if (keyboardAnimation == nil || ![keyboardAnimation isKindOfClass:[CASpringAnimation class]]) {
    _keyboardSpringAnimation = nil;
    return;
  }

  // Set up keyboard spring animation details for spring curve animation calculation.
  CASpringAnimation* keyboardCASpringAnimation = (CASpringAnimation*)keyboardAnimation;
  _keyboardSpringAnimation =
      [[SpringAnimation alloc] initWithStiffness:keyboardCASpringAnimation.stiffness
                                         damping:keyboardCASpringAnimation.damping
                                            mass:keyboardCASpringAnimation.mass
                                 initialVelocity:keyboardCASpringAnimation.initialVelocity
                                       fromValue:self.originalViewInsetBottom
                                         toValue:self.targetViewInsetBottom];
}

- (void)handleKeyboardAnimationCallbackWithTargetTime:(NSTimeInterval)targetTime {
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;

  // If the view controller's view is not loaded, bail out.
  if (!delegate.isViewLoaded) {
    return;
  }
  // If the view for tracking keyboard animation is nil, means it is not
  // created, bail out.
  if (!self.keyboardAnimationView) {
    return;
  }
  // If keyboardAnimationVSyncClient is nil, means the animation ends.
  // And should bail out.
  if (!self.keyboardAnimationVSyncClient) {
    return;
  }

  if (self.keyboardAnimationView.superview != delegate.view) {
    // Ensure the keyboardAnimationView is in view hierarchy when animation running.
    [delegate.view addSubview:self.keyboardAnimationView];
  }

  CGFloat currentInset = 0;
  if (!self.keyboardSpringAnimation) {
    if (self.keyboardAnimationView.layer.presentationLayer) {
      currentInset = self.keyboardAnimationView.layer.presentationLayer.frame.origin.y;
    }
  } else {
    NSTimeInterval timeElapsed = targetTime - self.keyboardAnimationStartTime;
    currentInset = [self.keyboardSpringAnimation curveFunction:timeElapsed];
  }

  [delegate updateViewportMetricsWithInset:currentInset];
}

- (void)setUpKeyboardAnimationVsyncClient:
    (FlutterKeyboardAnimationCallback)keyboardAnimationCallback {
  if (!keyboardAnimationCallback) {
    return;
  }
  NSAssert(_keyboardAnimationVSyncClient == nil,
           @"_keyboardAnimationVSyncClient must be nil when setting up.");

  // Make sure the new viewport metrics get sent after the begin frame event has processed.
  FlutterKeyboardAnimationCallback animationCallback = [keyboardAnimationCallback copy];

  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;
  auto vsyncCallback = ^(CFTimeInterval startTime, CFTimeInterval targetTime) {
    CFTimeInterval frameInterval = targetTime - startTime;
    CFTimeInterval projectedTargetTime = targetTime + frameInterval;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      animationCallback(projectedTargetTime);
    });
  };
  _keyboardAnimationVSyncClient =
      [[FlutterVSyncClient alloc] initWithTaskRunner:delegate.engine.uiTaskRunner
                                            callback:vsyncCallback];
  _keyboardAnimationVSyncClient.allowPauseAfterVsync = NO;
  [_keyboardAnimationVSyncClient await];
}

- (void)invalidateKeyboardAnimationVSyncClient {
  [_keyboardAnimationVSyncClient invalidate];
  _keyboardAnimationVSyncClient = nil;
}

- (void)removeKeyboardAnimationView {
  if (self.keyboardAnimationView.superview != nil) {
    [self.keyboardAnimationView removeFromSuperview];
  }
}

- (void)ensureViewportMetricsIsCorrect {
  id<FlutterKeyboardInsetManagerDelegate> delegate = self.delegate;
  [delegate updateViewportMetricsWithInset:self.targetViewInsetBottom];
}

- (void)invalidate {
  [self invalidateKeyboardAnimationVSyncClient];
  [self removeKeyboardAnimationView];
}

@end

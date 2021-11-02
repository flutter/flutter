// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSemanticsScrollView.h"

#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"

@implementation FlutterSemanticsScrollView

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _semanticsObject = semanticsObject;
  }
  return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  return nil;
}

// The following methods are explicitly forwarded to the wrapped SemanticsObject because the
// forwarding logic above doesn't apply to them since they are also implemented in the
// UIScrollView class, the base class.

- (BOOL)isAccessibilityElement {
  if (![_semanticsObject isAccessibilityBridgeAlive]) {
    return NO;
  }

  if ([_semanticsObject isAccessibilityElement]) {
    return YES;
  }
  if (self.contentSize.width > self.frame.size.width ||
      self.contentSize.height > self.frame.size.height) {
    // In SwitchControl or VoiceControl, the isAccessibilityElement must return YES
    // in order to use scroll actions.
    return ![_semanticsObject bridge]->isVoiceOverRunning();
  } else {
    return NO;
  }
}

- (NSString*)accessibilityLabel {
  return [_semanticsObject accessibilityLabel];
}

- (NSAttributedString*)accessibilityAttributedLabel {
  return [_semanticsObject accessibilityAttributedLabel];
}

- (NSString*)accessibilityValue {
  return [_semanticsObject accessibilityValue];
}

- (NSAttributedString*)accessibilityAttributedValue {
  return [_semanticsObject accessibilityAttributedValue];
}

- (NSString*)accessibilityHint {
  return [_semanticsObject accessibilityHint];
}

- (NSAttributedString*)accessibilityAttributedHint {
  return [_semanticsObject accessibilityAttributedHint];
}

- (BOOL)accessibilityActivate {
  return [_semanticsObject accessibilityActivate];
}

- (void)accessibilityIncrement {
  [_semanticsObject accessibilityIncrement];
}

- (void)accessibilityDecrement {
  [_semanticsObject accessibilityDecrement];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  return [_semanticsObject accessibilityScroll:direction];
}

- (BOOL)accessibilityPerformEscape {
  return [_semanticsObject accessibilityPerformEscape];
}

- (void)accessibilityElementDidBecomeFocused {
  [_semanticsObject accessibilityElementDidBecomeFocused];
}

- (void)accessibilityElementDidLoseFocus {
  [_semanticsObject accessibilityElementDidLoseFocus];
}

- (id)accessibilityContainer {
  return [_semanticsObject accessibilityContainer];
}

- (NSInteger)accessibilityElementCount {
  return [[_semanticsObject children] count];
}

@end

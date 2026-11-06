// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSemanticsScrollView.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"

FLUTTER_ASSERT_ARC

@implementation FlutterSemanticsScrollView

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _semanticsObject = semanticsObject;
    _isDoingSystemScrolling = NO;
    self.delegate = self;
  }
  return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  return nil;
}

- (id)_accessibilityHitTest:(CGPoint)point withEvent:(UIEvent*)event {
  SemanticsObject* semanticsObject = self.semanticsObject;
  UIView* bridgeView = semanticsObject.bridgeView;
  if (!bridgeView) {
    return nil;
  }
  CGPoint pointInBridgeView = [self convertPoint:point toView:bridgeView];
  return [semanticsObject _accessibilityHitTest:pointInBridgeView withEvent:event];
}

// The following methods are explicitly forwarded to the wrapped SemanticsObject because the
// forwarding logic above doesn't apply to them since they are also implemented in the
// UIScrollView class, the base class.

- (BOOL)isAccessibilityElement {
  SemanticsObject* semanticsObject = self.semanticsObject;
  flutter::AccessibilityBridgeIos* bridge = semanticsObject.bridge;
  if (!bridge) {
    return NO;
  }

  if ([semanticsObject hasChildren]) {
    return NO;
  }

  if (bridge->isVoiceOverRunning()) {
    return semanticsObject.accessibilityLabel.length > 0;
  }

  if (semanticsObject.isAccessibilityElement) {
    return YES;
  }

  if (self.contentSize.width > self.frame.size.width ||
      self.contentSize.height > self.frame.size.height) {
    return YES;
  }

  return NO;
}

- (NSString*)accessibilityLabel {
  return self.semanticsObject.accessibilityLabel;
}

- (NSAttributedString*)accessibilityAttributedLabel {
  return self.semanticsObject.accessibilityAttributedLabel;
}

- (NSString*)accessibilityValue {
  return self.semanticsObject.accessibilityValue;
}

- (NSAttributedString*)accessibilityAttributedValue {
  return self.semanticsObject.accessibilityAttributedValue;
}

- (NSString*)accessibilityHint {
  return self.semanticsObject.accessibilityHint;
}

- (NSAttributedString*)accessibilityAttributedHint {
  return self.semanticsObject.accessibilityAttributedHint;
}

- (BOOL)accessibilityActivate {
  return [self.semanticsObject accessibilityActivate];
}

- (void)accessibilityIncrement {
  [self.semanticsObject accessibilityIncrement];
}

- (void)accessibilityDecrement {
  [self.semanticsObject accessibilityDecrement];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  return [self.semanticsObject accessibilityScroll:direction];
}

- (BOOL)accessibilityPerformEscape {
  return [self.semanticsObject accessibilityPerformEscape];
}

- (void)accessibilityElementDidBecomeFocused {
  [self.semanticsObject accessibilityElementDidBecomeFocused];
}

- (void)accessibilityElementDidLoseFocus {
  [self.semanticsObject accessibilityElementDidLoseFocus];
}

- (id)accessibilityContainer {
  SemanticsObject* semanticsObject = self.semanticsObject;
  if (!semanticsObject.bridge) {
    return nil;
  }
  return ([semanticsObject uid] == kRootNodeId) ? semanticsObject.bridgeView
                                                : semanticsObject.parent.accessibilityContainer;
}

- (NSInteger)accessibilityElementCount {
  return self.semanticsObject.children.count;
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index {
  NSArray<SemanticsObject*>* children = self.semanticsObject.children;
  if (index < 0 || index >= static_cast<NSInteger>(children.count)) {
    return nil;
  }
  SemanticsObject* child = children[index];
  if ([child hasChildren]) {
    return child.accessibilityContainer;
  }
  return child.nativeAccessibility;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  NSArray<SemanticsObject*>* children = self.semanticsObject.children;
  for (size_t i = 0; i < children.count; i++) {
    SemanticsObject* child = children[i];
    if ((![child hasChildren] && child.nativeAccessibility == element) ||
        ([child hasChildren] && [child accessibilityContainer] == element)) {
      return i;
    }
  }
  return NSNotFound;
}

- (void)scrollViewWillEndDragging:(UIScrollView*)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint*)targetContentOffset {
  _isDoingSystemScrolling = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
  _isDoingSystemScrolling = NO;
}

@end

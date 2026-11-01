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
  CGPoint pointInScreenCoordinates =
      UIAccessibilityConvertFrameToScreenCoordinates(CGRectMake(point.x, point.y, 0, 0), self)
          .origin;
  return [self.semanticsObject _accessibilityHitTest:pointInScreenCoordinates withEvent:event];
}

// The following methods are explicitly forwarded to the wrapped SemanticsObject because the
// forwarding logic above doesn't apply to them since they are also implemented in the
// UIScrollView class, the base class.

- (BOOL)isAccessibilityElement {
  flutter::AccessibilityBridgeIos* bridge = self.semanticsObject.bridge;
  if (!bridge) {
    return NO;
  }

  if ([self.semanticsObject hasChildren]) {
    return NO;
  }

  if (bridge->isVoiceOverRunning()) {
    return self.semanticsObject.accessibilityLabel.length > 0;
  }

  if (self.semanticsObject.isAccessibilityElement) {
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
  if (!self.semanticsObject.bridge) {
    return nil;
  }
  if ([self.semanticsObject hasChildren]) {
    // When `semanticsObject` has children, this scroll view itself serves as
    // `semanticsObject.accessibilityContainer` (replacing `SemanticsObjectContainer`), so its own
    // parent container in the accessibility hierarchy is `semanticsObject.parent`'s container.
    return ([self.semanticsObject uid] == kRootNodeId)
               ? self.semanticsObject.bridgeView
               : self.semanticsObject.parent.accessibilityContainer;
  }
  return self.semanticsObject.accessibilityContainer;
}

- (NSInteger)accessibilityElementCount {
  return self.semanticsObject.children.count;
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index {
  if (index < 0 || index >= self.accessibilityElementCount) {
    return nil;
  }
  SemanticsObject* child = self.semanticsObject.children[index];
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

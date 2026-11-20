// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSEMANTICSSCROLLVIEW_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSEMANTICSSCROLLVIEW_H_

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class SemanticsObject;

/**
 * A hidden UIScrollView that represents a Flutter scrollable in iOS
 * accessibility services.
 *
 * UIKit's accessibility runtime only recognizes scrollable regions that are
 * `UIScrollView` subclasses (checking `[obj isKindOfClass:[UIScrollView class]]`
 * and inspecting `frame`, `contentSize`, and `contentOffset`). Because
 * `FlutterScrollableSemanticsObject` subclasses `SemanticsObject`
 * (`UIAccessibilityElement`), it creates this `UIScrollView` to represent
 * itself to iOS and forwards accessibility callbacks back to `semanticsObject`.
 *
 * This view also serves directly as `semanticsObject`'s
 * `UIAccessibilityContainer` (instead of `SemanticsObjectContainer`) so that
 * child elements have this `UIScrollView` as their `accessibilityContainer`.
 */
@interface FlutterSemanticsScrollView : UIScrollView <UIScrollViewDelegate>

@property(nonatomic, weak, nullable) SemanticsObject* semanticsObject;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)coder NS_UNAVAILABLE;
- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject;
- (nullable id)accessibilityContainer;
- (nullable id)_accessibilityHitTest:(CGPoint)point withEvent:(nullable UIEvent*)event;

@end
NS_ASSUME_NONNULL_END
#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSEMANTICSSCROLLVIEW_H_

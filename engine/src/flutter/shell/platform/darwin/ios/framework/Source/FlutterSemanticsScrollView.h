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
 * When `semanticsObject` has children, this view also serves directly as its
 * `UIAccessibilityContainer` (instead of `SemanticsObjectContainer`) so that
 * child elements have this `UIScrollView` as their `accessibilityContainer`.
 */
@interface FlutterSemanticsScrollView : UIScrollView <UIScrollViewDelegate>

@property(nonatomic, weak, nullable) SemanticsObject* semanticsObject;

/// Whether this scroll view's content offset is actively being updated by UIKit
/// or other the system services.
///
/// This flag is set by the `FlutterSemanticsScrollView` itself, typically in
/// one of the `UIScrollViewDelegate` methods.
///
/// When this flag is true, the `SemanticsObject` implementation ignores all
/// content offset updates coming from the Flutter framework, to prevent
/// potential feedback loops (especially when the framework is only echoing
/// the new content offset back to this scroll view).
///
/// For example, to scroll a scrollable container with iOS full keyboard access,
/// the iOS focus system uses a display link to scroll the container to the
/// desired offset animatedly. If the user changes the scroll offset during the
/// animation, the display link will be invalidated and the scrolling animation
/// will be interrupted. For simplicity, content offset updates coming from the
/// framework will be ignored in the relatively short animation duration (~1s),
/// allowing the scrolling animation to finish.
@property(nonatomic, readonly) BOOL isDoingSystemScrolling;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)coder NS_UNAVAILABLE;
- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject;
- (nullable id)accessibilityContainer;

@end
NS_ASSUME_NONNULL_END
#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSEMANTICSSCROLLVIEW_H_

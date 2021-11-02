// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_SEMANTICS_SCROLL_VIEW_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_SEMANTICS_SCROLL_VIEW_H_

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class SemanticsObject;

/**
 * A UIScrollView to represent Flutter scrollable in iOS accessibility
 * services.
 *
 * This class is hidden from the user and can't be interacted with. It
 * sends all of selector calls from accessibility services to the
 * owner SemanticsObject.
 */
@interface FlutterSemanticsScrollView : UIScrollView

@property(nonatomic, assign, nullable) SemanticsObject* semanticsObject;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)coder NS_UNAVAILABLE;
- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject;

@end
NS_ASSUME_NONNULL_END
#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_SEMANTICS_SCROLL_VIEW_H_

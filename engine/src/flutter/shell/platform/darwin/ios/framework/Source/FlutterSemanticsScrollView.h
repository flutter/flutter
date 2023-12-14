// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSEMANTICSSCROLLVIEW_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSEMANTICSSCROLLVIEW_H_

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
#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSEMANTICSSCROLLVIEW_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWRESPONDER_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWRESPONDER_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol FlutterViewResponder <NSObject>

@property(nonatomic, strong) UIView* view;

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEstimatedPropertiesUpdated:(NSSet*)touches;

@end
NS_ASSUME_NONNULL_END

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWRESPONDER_H_

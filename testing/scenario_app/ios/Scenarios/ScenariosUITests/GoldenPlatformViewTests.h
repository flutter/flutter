// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>
#import "PlatformViewGoldenTestManager.h"

NS_ASSUME_NONNULL_BEGIN

// The base class of all the PlatformView golden tests.
//
// A new PlatformView golden tests can subclass this and override the `-initiWithInvocation:`
// method, which then retun the `-initWithManager:invocation:`
//
// Then in any test method, call `checkGolden` to perform the golden test.
//
// This base class doesn't run any test case on its own.
@interface GoldenPlatformViewTests : XCTestCase

@property(nonatomic, strong) XCUIApplication* application;

// Initialize with a `PlatformViewGoldenTestManager`.
- (instancetype)initWithManager:(PlatformViewGoldenTestManager*)manager
                     invocation:(NSInvocation*)invocation;

// Take a sceenshot of the test app and check it has the same pixels with goldenImage inside the
// `PlatformViewGoldenTestManager`.
- (void)checkGolden;

@end

NS_ASSUME_NONNULL_END

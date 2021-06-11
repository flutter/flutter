// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>

#import <EarlGreyTest/GREYHostApplicationDistantObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface GREYHostApplicationDistantObject (AppDelegate)
- (NSNotificationCenter *)notificationCenter;
@end

@interface AppDelegate : FlutterAppDelegate
@property(nonatomic, strong, readonly) FlutterEngine* engine;
@end

NS_ASSUME_NONNULL_END

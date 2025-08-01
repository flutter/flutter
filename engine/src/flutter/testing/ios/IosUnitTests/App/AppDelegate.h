// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_
#define FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_

#import <UIKit/UIKit.h>

@class FlutterEngine;
@protocol FlutterPluginRegistrant;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(nonatomic, strong, nullable) UIWindow* window;

//  A mirror of the FlutterAppDelegate API for integration testing.
@property(nonatomic, strong, nullable) NSObject<FlutterPluginRegistrant>* pluginRegistrant;

/** The FlutterEngine that will be served by `takeLaunchEngine`. */
@property(nonatomic, strong, nullable) FlutterEngine* mockLaunchEngine;

- (nullable FlutterEngine*)takeLaunchEngine;

@end

#endif  // FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_

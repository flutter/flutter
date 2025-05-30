// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_
#define FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_

#import <UIKit/UIKit.h>

@protocol FlutterPluginRegistrant;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(nonatomic, strong, nullable) UIWindow* window;

//  A mirror of the FlutterAppDelegate API for integration testing.
@property(nonatomic, strong, nullable) NSObject<FlutterPluginRegistrant>* pluginRegistrant;

@end

#endif  // FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_
#define FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_

#import <UIKit/UIKit.h>

@class FlutterEngine;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow* window;
/** The FlutterEngine that will be served by `takeLaunchEngine`. */
@property(strong, nonatomic) FlutterEngine* mockLaunchEngine;

- (FlutterEngine*)takeLaunchEngine;

@end

#endif  // FLUTTER_TESTING_IOS_IOSUNITTESTS_APP_APPDELEGATE_H_

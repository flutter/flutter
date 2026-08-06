// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_
#define FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_

#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface SceneDelegate : FlutterSceneDelegate

/**
 * The window of the app's connected scene, or nil if no scene is connected.
 *
 * Under the UIScene life cycle the window belongs to the scene delegate rather than the
 * application delegate. Tests use this to reach the root view controller.
 */
@property(class, nonatomic, readonly, nullable) UIWindow* mainWindow;

@end

#endif  // FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_

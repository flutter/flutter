// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_
#define FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_

#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface SceneDelegate : FlutterSceneDelegate

/**
 * The main window of the first connected scene, or nil if no scene is connected.
 *
 * Under the UIScene life cycle a window belongs to a scene rather than to the application
 * delegate, and a single scene delegate may serve more than one scene. The scenario app only
 * ever has one scene, so tests use this to reach its root view controller.
 */
@property(class, nonatomic, readonly, nullable) UIWindow* mainWindowOfFirstConnectedScene;

@end

#endif  // FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_

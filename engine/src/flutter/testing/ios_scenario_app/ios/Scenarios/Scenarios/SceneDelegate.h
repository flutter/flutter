// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_
#define FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_

@import UIKit;

@interface SceneDelegate : NSObject <UIWindowSceneDelegate>
@property(nullable, nonatomic, strong) UIWindow* window;
@end

#endif  // FLUTTER_TESTING_IOS_SCENARIO_APP_IOS_SCENARIOS_SCENARIOS_SCENEDELEGATE_H_

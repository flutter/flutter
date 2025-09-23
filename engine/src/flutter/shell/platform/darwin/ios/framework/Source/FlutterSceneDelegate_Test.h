// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENEDELEGATE_TEST_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENEDELEGATE_TEST_H_

// Category to add test-only visibility.
@interface FlutterSceneDelegate (Test)

- (void)moveRootViewControllerFrom:(NSObject<UIApplicationDelegate>*)appDelegate
                                to:(UIWindowScene*)windowScene;

@end

@interface TestAppDelegate : UIResponder <UIApplicationDelegate>
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENEDELEGATE_TEST_H_

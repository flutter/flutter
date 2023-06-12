// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char *argv[]) {
  @autoreleasepool {
    // The setup logic in `AppDelegate::didFinishLaunchingWithOptions:` eventually sends camera
    // operations on the background queue, which would run concurrently with the test cases during
    // unit tests, making the debugging process confusing. This setup is actually not necessary for
    // the unit tests, so it is better to skip the AppDelegate when running unit tests.
    BOOL isTesting = NSClassFromString(@"XCTestCase") != nil;
    return UIApplicationMain(argc, argv, nil,
                             isTesting ? nil : NSStringFromClass([AppDelegate class]));
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"

@interface FlutterAppDelegate ()

/**
 * Returns the display name of the application as set in the Info.plist.
 */
- (NSString*)applicationName;

@end

@implementation FlutterAppDelegate

// TODO(stuartmorgan): Implement application lifecycle forwarding to plugins here, as is done
// on iOS. Currently macOS plugins don't have access to lifecycle messages.

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
  // Update UI elements to match the application name.
  NSString* applicationName = [self applicationName];
  _mainFlutterWindow.title = applicationName;
  for (NSMenuItem* menuItem in _applicationMenu.itemArray) {
    menuItem.title = [menuItem.title stringByReplacingOccurrencesOfString:@"APP_NAME"
                                                               withString:applicationName];
  }
}

#pragma mark Private Methods

- (NSString*)applicationName {
  NSString* applicationName =
      [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
  if (!applicationName) {
    applicationName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
  }
  return applicationName;
}

@end

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterAppDelegate_Internal.h"

#import <AppKit/AppKit.h>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/embedder.h"

@interface FlutterAppDelegate ()

/**
 * Returns the display name of the application as set in the Info.plist.
 */
- (NSString*)applicationName;

@end

@implementation FlutterAppDelegate

// TODO(gspencergoog): Implement application lifecycle forwarding to plugins here, as is done
// on iOS. Currently macOS plugins don't have access to lifecycle messages.
// https://github.com/flutter/flutter/issues/30735

- (instancetype)init {
  if (self = [super init]) {
    _terminationHandler = nil;
  }
  return self;
}

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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication* _Nonnull)sender {
  // If the framework has already told us to terminate, terminate immediately.
  if ([[self terminationHandler] shouldTerminate]) {
    return NSTerminateNow;
  }

  // Send a termination request to the framework.
  FlutterEngineTerminationHandler* terminationHandler = [self terminationHandler];
  [terminationHandler requestApplicationTermination:sender
                                           exitType:kFlutterAppExitTypeCancelable
                                             result:nil];

  // Cancel termination to allow the framework to handle the request asynchronously. When the
  // termination request returns from the app, if termination is desired, this method will be
  // reinvoked with self.terminationHandler.shouldTerminate set to YES.
  return NSTerminateCancel;
}

@end

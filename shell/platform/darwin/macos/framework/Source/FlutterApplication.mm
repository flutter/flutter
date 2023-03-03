// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterApplication.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterApplication_Internal.h"

#include "flutter/shell/platform/embedder/embedder.h"
#import "shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"
#import "shell/platform/darwin/macos/framework/Source/FlutterAppDelegate_Internal.h"
#import "shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"

// An NSApplication subclass that implements overrides necessary for some
// Flutter features, like application lifecycle handling.
@implementation FlutterApplication

// Initialize NSApplication using the custom subclass. Check whether NSApp was
// already initialized using another class, because that would break some
// things. Warn about the mismatch only once, and only in debug builds.
+ (NSApplication*)sharedApplication {
  NSApplication* app = [super sharedApplication];

  // +sharedApplication initializes the global NSApp, so if we're delivering
  // something other than a FlutterApplication, warn the developer once.
#ifndef FLUTTER_RELEASE
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    if (![app respondsToSelector:@selector(terminateApplication:)]) {
      NSLog(@"NSApp should be of type %s, not %s.\n"
             "System requests for the application to terminate will not be sent to "
             "the Flutter framework, so the framework will be unable to cancel "
             "those requests.\n"
             "Modify the application's NSPrincipleClass to be %s in the "
             "Info.plist to fix this.",
            [[self className] UTF8String], [[NSApp className] UTF8String],
            [[self className] UTF8String]);
    }
  });
#endif  // !FLUTTER_RELEASE
  return app;
}

// |terminate| is the entry point for orderly "quit" operations in Cocoa. This
// includes the application menu's Quit menu item and keyboard equivalent, the
// application's dock icon menu's Quit menu item, "quit" (not "force quit") in
// the Activity Monitor, and quits triggered by user logout and system restart
// and shutdown.
//
// We override the normal |terminate| implementation. Our implementation, which
// is specific to the asynchronous nature of Flutter, works by asking the
// application delegate to terminate using its |requestApplicationTermination|
// method instead of going through |applicationShouldTerminate|.
//
// The standard |applicationShouldTerminate| is not used because returning
// NSTerminateLater from that function moves the run loop into a modal dialog
// mode (NSModalPanelRunLoopMode), which stops the main run loop from processing
// messages like, for instance, the response to the method channel call, and
// code paths leading to it must be redirected to |requestApplicationTermination|.
//
// |requestApplicationTermination| differs from the standard
// |applicationShouldTerminate| in that no special event loop is run in the case
// that immediate termination is not possible (e.g., if dialog boxes allowing
// the user to cancel have to be shown, or data needs to be saved). Instead,
// requestApplicationTermination sends a method channel call to the framework asking
// it if it is OK to terminate. When that method channel call returns with a
// result, the application either terminates or continues running.
- (void)terminate:(id)sender {
  FlutterAppDelegate* delegate = [self delegate];
  if (!delegate || ![delegate respondsToSelector:@selector(terminationHandler)] ||
      [delegate terminationHandler] == nil) {
    // If there's no termination handler, then just terminate.
    [super terminate:sender];
  }
  FlutterEngineTerminationHandler* terminationHandler =
      [static_cast<FlutterAppDelegate*>([self delegate]) terminationHandler];
  [terminationHandler requestApplicationTermination:sender
                                           exitType:kFlutterAppExitTypeCancelable
                                             result:nil];
  // Return, don't exit. The application delegate is responsible for exiting on
  // its own by calling |terminateApplication|.
}

// Starts the regular Cocoa application termination flow, so that plugins will
// get the appropriate notifications after the application has already decided
// to quit. This is called after the application has decided that
// it's OK to terminate.
- (void)terminateApplication:(id)sender {
  [super terminate:sender];
}
@end

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#include "impeller_host_view_controller.h"

@interface ImpellerAppDelegate
    : NSObject <NSApplicationDelegate, NSWindowDelegate> {
  NSWindow* window_;
  ImpellerHostViewController* view_controller_;
}
@end

@implementation ImpellerAppDelegate : NSObject

- (id)init {
  if (self = [super init]) {
    view_controller_ = [[ImpellerHostViewController alloc] init];
    window_ = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 800, 600)
                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                    backing:NSBackingStoreBuffered
                      defer:NO];
    [window_ setContentViewController:view_controller_];
  }
  return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
  [window_ setTitle:@"Impeller Host"];
  [window_ makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
  return YES;
}

@end

int main(int argc, const char* argv[]) {
  NSApplication* app = [NSApplication sharedApplication];
  [app setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSMenuItem* item = [[NSMenuItem alloc] init];
  NSApp.mainMenu = [[NSMenu alloc] init];
  item.submenu = [[NSMenu alloc] init];
  [app.mainMenu addItem:item];
  [item.submenu
      addItem:[[NSMenuItem alloc]
                  initWithTitle:[@"Quit "
                                    stringByAppendingString:[NSProcessInfo
                                                                processInfo]
                                                                .processName]
                         action:@selector(terminate:)
                  keyEquivalent:@"q"]];
  ImpellerAppDelegate* appDelegate = [[ImpellerAppDelegate alloc] init];
  [app setDelegate:appDelegate];
  [app run];
  return 0;
}

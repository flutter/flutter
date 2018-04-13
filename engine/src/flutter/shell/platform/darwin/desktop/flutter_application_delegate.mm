// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/desktop/flutter_application_delegate.h"
#include "flutter/shell/platform/darwin/desktop/flutter_window.h"

#include <AppKit/AppKit.h>

@implementation FlutterApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
  [self configureMainMenuBar];
  [self onNewFlutterWindow:self];
}

- (void)configureMainMenuBar {
  NSMenu* mainMenu = [[[NSMenu alloc] initWithTitle:@"MainMenu"] autorelease];

  NSMenuItem* engineItem =
      [[[NSMenuItem alloc] initWithTitle:@"Engine" action:NULL keyEquivalent:@""] autorelease];

  NSMenu* engineMenu = [[[NSMenu alloc] initWithTitle:@"EngineMenu"] autorelease];

  NSMenuItem* newEngineItem = [[[NSMenuItem alloc] initWithTitle:@"New Engine"
                                                          action:@selector(onNewFlutterWindow:)
                                                   keyEquivalent:@""] autorelease];
  newEngineItem.keyEquivalent = @"n";
  newEngineItem.keyEquivalentModifierMask = NSCommandKeyMask;

  NSMenuItem* shutdownEngineItem =
      [[[NSMenuItem alloc] initWithTitle:@"Shutdown Engine"
                                  action:@selector(onShutdownFlutterWindow:)
                           keyEquivalent:@""] autorelease];
  shutdownEngineItem.keyEquivalent = @"w";
  shutdownEngineItem.keyEquivalentModifierMask = NSCommandKeyMask;

  NSMenuItem* quitItem = [[[NSMenuItem alloc] initWithTitle:@"Quit"
                                                     action:@selector(onQuitFlutterApplication:)
                                              keyEquivalent:@""] autorelease];
  quitItem.keyEquivalent = @"q";
  quitItem.keyEquivalentModifierMask = NSCommandKeyMask;

  [mainMenu addItem:engineItem];
  [engineItem setSubmenu:engineMenu];
  [engineMenu addItem:newEngineItem];
  [engineMenu addItem:shutdownEngineItem];
  [engineMenu addItem:quitItem];

  [NSApplication sharedApplication].mainMenu = mainMenu;
}

- (void)onNewFlutterWindow:(id)sender {
  FlutterWindow* window = [[FlutterWindow alloc] init];
  [window setReleasedWhenClosed:YES];

  NSWindow* currentKeyWindow = [NSApplication sharedApplication].keyWindow;

  if (currentKeyWindow == nil) {
    [window center];
  } else {
    [window center];
    NSPoint currentWindowFrameOrigin = window.frame.origin;
    currentWindowFrameOrigin.x = currentKeyWindow.frame.origin.x + 20;
    currentWindowFrameOrigin.y = currentKeyWindow.frame.origin.y - 20;
    [window setFrameOrigin:currentWindowFrameOrigin];
  }

  [window makeKeyAndOrderFront:sender];
}

- (void)onShutdownFlutterWindow:(id)sender {
  [[NSApplication sharedApplication].keyWindow close];
}

- (void)onQuitFlutterApplication:(id)sender {
  exit(0);
}

@end

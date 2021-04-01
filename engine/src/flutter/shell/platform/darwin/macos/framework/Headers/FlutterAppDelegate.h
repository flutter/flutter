// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERAPPDELEGATE_H_
#define FLUTTER_FLUTTERAPPDELEGATE_H_

#import <Cocoa/Cocoa.h>

#import "FlutterMacros.h"

/**
 * `NSApplicationDelegate` subclass for simple apps that want default behavior.
 *
 * This class implements the following behaviors:
 *   * Updates the application name of items in the application menu to match the name in
 *     the app's Info.plist, assuming it is set to APP_NAME initially. |applicationMenu| must be
 *     set before the application finishes launching for this to take effect.
 *   * Updates the main Flutter window's title to match the name in the app's Info.plist.
 *     |mainFlutterWindow| must be set before the application finishes launching for this to take
 *     effect.
 *
 * App delegates for Flutter applications are *not* required to inherit from
 * this class. Developers of custom app delegate classes should copy and paste
 * code as necessary from FlutterAppDelegate.mm.
 */
FLUTTER_DARWIN_EXPORT
@interface FlutterAppDelegate : NSObject <NSApplicationDelegate>

/**
 * The application menu in the menu bar.
 */
@property(weak, nonatomic) IBOutlet NSMenu* applicationMenu;

/**
 * The primary application window containing a FlutterViewController. This is primarily intended
 * for use in single-window applications.
 */
@property(weak, nonatomic) IBOutlet NSWindow* mainFlutterWindow;

@end

#endif  // FLUTTER_FLUTTERAPPDELEGATE_H_

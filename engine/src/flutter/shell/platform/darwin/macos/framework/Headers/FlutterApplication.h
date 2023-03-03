// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERAPPLICATION_H_
#define FLUTTER_FLUTTERAPPLICATION_H_

#import <Cocoa/Cocoa.h>

/**
 * A Flutter-specific subclass of NSApplication that overrides |terminate| and
 * provides an additional |terminateApplication| method so that Flutter can
 * handle requests for termination in an asynchronous fashion.
 *
 * When a call to |terminate| comes in, either from the OS through a Quit menu
 * item, through the Quit item in the dock context menu, or from the application
 * itself, a request is sent to the Flutter framework. If that request is
 * granted, this subclass will (in |terminateApplication|) call
 * |NSApplication|'s version of |terminate| to proceed with terminating the
 * application normally by calling |applicationShouldTerminate|, etc.
 *
 * If the termination request is denied by the framework, then the application
 * will continue to execute normally, as if no |terminate| call were made.
 *
 * The |FlutterAppDelegate| always returns |NSTerminateNow| from
 * |applicationShouldTerminate|, since it has already decided by that point that
 * it should terminate.
 *
 * In order for this class to be used in place of |NSApplication|, the
 * "NSPrincipalClass" entry in the Info.plist for the application must be set to
 * "FlutterApplication". If it is not, then the application will not be given
 * the chance to deny a termination request, and calls to requestAppExit on the
 * engine (from the framework, typically) will simply exit the application
 * without ceremony.
 *
 * If the |NSApp| global isn't of type |FlutterApplication|, a log message will
 * be printed once in debug mode when the application is first accessed through
 * the singleton's |sharedApplication|, describing how to fix this.
 *
 * Flutter applications are *not* required to inherit from this class.
 * Developers of custom |NSApplication| subclasses should copy and paste code as
 * necessary from FlutterApplication.mm.
 */
@interface FlutterApplication : NSApplication
@end

#endif  // FLUTTER_FLUTTERAPPLICATION_H_

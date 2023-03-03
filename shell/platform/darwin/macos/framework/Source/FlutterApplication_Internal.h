// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERAPPLICATION_INTERNAL_H_
#define FLUTTER_FLUTTERAPPLICATION_INTERNAL_H_

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterApplication.h"

/**
 * Define |terminateApplication| for internal use.
 */
@interface FlutterApplication ()

/**
 * FlutterApplication's implementation of |terminate| doesn't terminate the
 * application: that is left up to the engine, which will call this function if
 * it decides that termination request is granted, which will start the regular
 * Cocoa flow for terminating the application, calling
 * |applicationShouldTerminate|, etc.
 *
 * @param(sender) The id of the object requesting the termination, or nil.
 */
- (void)terminateApplication:(id)sender;
@end

#endif  // FLUTTER_FLUTTERAPPLICATION_INTERNAL_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

/**
 * An interface to query FlutterView.
 *
 * See also:
 *
 *  * FlutterViewEngineProvider, a typical implementation.
 */
@protocol FlutterViewProvider

/**
 * Get the FlutterView with the given view ID.
 *
 * Returns nil if the ID is invalid.
 */
- (nullable FlutterView*)getView:(uint64_t)id;

@end

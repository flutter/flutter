// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@interface FlutterPluginAppLifeCycleDelegate ()

/**
 * Check whether the selector should be handled dynamically.
 */
- (BOOL)isSelectorAddedDynamically:(SEL)selector;

/**
 * Check whether there is at least one plugin responds to the selector.
 */
- (BOOL)hasPluginThatRespondsToSelector:(SEL)selector;

@end
;

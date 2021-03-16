// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

/**
 * An interface for a responder that can process a key event and decides whether
 * to handle an event synchronously.
 *
 * To use this class, add it to a |FlutterKeyboardManager| with
 * |addSecondaryResponder|.
 */
@protocol FlutterKeySecondaryResponder
/**
 * Informs the receiver that the user has interacted with a key.
 *
 * The return value indicates whether it has handled the given event.
 *
 * Default implementation returns NO.
 */
@required
- (BOOL)handleKeyEvent:(nonnull NSEvent*)event;
@end

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

/*
 * An interface for a key responder that can declare itself as the final
 * responder of the event, terminating the event propagation.
 *
 * It differs from an NSResponder in that it returns a boolean from the
 * handleKeyUp and handleKeyDown calls, where true means it has handled the
 * given event.
 */
@interface FlutterIntermediateKeyResponder : NSObject
/*
 * Informs the receiver that the user has released a key.
 *
 * Default implementation returns NO.
 */
- (BOOL)handleKeyUp:(nonnull NSEvent*)event;
/*
 * Informs the receiver that the user has pressed a key.
 *
 * Default implementation returns NO.
 */
- (BOOL)handleKeyDown:(nonnull NSEvent*)event;
@end

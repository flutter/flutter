// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyPrimaryResponder.h"

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyPrimaryResponder.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeySecondaryResponder.h"

/**
 * A hub that manages how key events are dispatched to various Flutter key
 * responders, and whether the event is propagated to the next NSResponder.
 *
 * This class manages one or more primary responders, as well as zero or more
 * secondary responders.
 *
 * An event that is received by |handleEvent| is first dispatched to *all*
 * primary responders. Each primary responder responds *asynchronously* with a
 * boolean, indicating whether it handles the event.
 *
 * An event that is not handled by any primary responders is then passed to to
 * the first secondary responder (in the chronological order of addition),
 * which responds *synchronously* with a boolean, indicating whether it handles
 * the event. If not, the event is passed to the next secondary responder, and
 * so on.
 *
 * If no responders handle the event, the event is then handed over to the
 * owner's |nextResponder| if not nil, dispatching to method |keyDown|,
 * |keyUp|, or |flagsChanged| depending on the event's type. If the
 * |nextResponder| is nil, then the event will be propagated no further.
 *
 * Preventing primary responders from receiving events is not supported,
 * because in reality this class will only support 2 hardcoded ones (channel
 * and embedder), where the only purpose of supporting two is to support the
 * legacy API (channel) during the deprecation window, after which the channel
 * responder should be removed.
 */
@interface FlutterKeyboardManager : NSObject

/**
 * Create a manager by specifying the owner.
 *
 * The owner should be an object that handles the lifecycle of this instance.
 * The |owner.nextResponder| can be nil, but if it isn't, it will be where the
 * key events are propagated to if no responders handle the event. The owner
 * is typically a |FlutterViewController|.
 */
- (nonnull instancetype)initWithOwner:(nonnull NSResponder*)weakOwner;

/**
 * Add a primary responder, which asynchronously decides whether to handle an
 * event.
 */
- (void)addPrimaryResponder:(nonnull id<FlutterKeyPrimaryResponder>)responder;

/**
 * Add a secondary responder, which synchronously decides whether to handle an
 * event in order if no earlier responders handle.
 */
- (void)addSecondaryResponder:(nonnull id<FlutterKeySecondaryResponder>)responder;

/**
 * Dispatch a key event to all responders, and possibly the next |NSResponder|
 * afterwards.
 */
- (void)handleEvent:(nonnull NSEvent*)event;

@end

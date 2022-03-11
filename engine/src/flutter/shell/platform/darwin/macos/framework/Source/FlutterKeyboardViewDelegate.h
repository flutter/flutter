// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/embedder/embedder.h"

/**
 * An interface for a class that can provides |FlutterKeyboardManager| with
 * platform-related features.
 *
 * This protocol is typically implemented by |FlutterViewController|.
 */
@protocol FlutterKeyboardViewDelegate

@required

/**
 * Get the next responder to dispatch events that the keyboard system
 * (including text input) do not handle.
 *
 * If the |nextResponder| is null, then those events will be discarded.
 */
@property(nonatomic, readonly, nullable) NSResponder* nextResponder;

/**
 * Dispatch events to the framework to be processed by |HardwareKeyboard|.
 *
 * This method typically forwards events to
 * |FlutterEngine.sendKeyEvent:callback:userData:|.
 */
- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(nullable FlutterKeyEventCallback)callback
            userData:(nullable void*)userData;

/**
 * Get a binary messenger to send channel messages with.
 *
 * This method is used to create the key data channel and typically
 * forwards to |FlutterEngine.binaryMessenger|.
 */
- (nonnull id<FlutterBinaryMessenger>)getBinaryMessenger;

/**
 * Dispatch events that are not handled by the keyboard event handlers
 * to the text input handler.
 *
 * This method typically forwards events to |TextInputPlugin.handleKeyEvent|.
 */
- (BOOL)onTextInputKeyEvent:(nonnull NSEvent*)event;

@end

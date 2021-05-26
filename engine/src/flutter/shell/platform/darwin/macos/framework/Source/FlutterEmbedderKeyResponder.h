// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyPrimaryResponder.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace {
typedef void* _VoidPtr;
}

typedef void (^FlutterSendEmbedderKeyEvent)(const FlutterKeyEvent& /* event */,
                                            _Nullable FlutterKeyEventCallback /* callback */,
                                            _Nullable _VoidPtr /* user_data */);

/**
 * A primary responder of |FlutterKeyboardManager| that handles events by
 * sending the converted events through the embedder API.
 *
 * This class communicates with the HardwareKeyboard API in the framework.
 */
@interface FlutterEmbedderKeyResponder : NSObject <FlutterKeyPrimaryResponder>

/**
 * Create an instance by specifying the function to send converted events to.
 *
 * The |sendEvent| is typically |FlutterEngine|'s |sendKeyEvent|.
 */
- (nonnull instancetype)initWithSendEvent:(_Nonnull FlutterSendEmbedderKeyEvent)sendEvent;

@end

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <objc/message.h>

#import "FlutterChannelKeyResponder.h"
#import "KeyCodeMap_Internal.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/embedder/embedder.h"

@interface FlutterChannelKeyResponder ()

/**
 * The channel used to communicate with Flutter.
 */
@property(nonatomic) FlutterBasicMessageChannel* channel;

/**
 * The |NSEvent.modifierFlags| of the last event received.
 *
 * Used to determine whether a FlagsChanged event should count as a keydown or
 * a keyup event.
 */
@property(nonatomic) uint64_t previouslyPressedFlags;

@end

@implementation FlutterChannelKeyResponder

@synthesize layoutMap;

- (nonnull instancetype)initWithChannel:(nonnull FlutterBasicMessageChannel*)channel {
  self = [super init];
  if (self != nil) {
    _channel = channel;
    _previouslyPressedFlags = 0;
  }
  return self;
}

- (void)handleEvent:(NSEvent*)event callback:(FlutterAsyncKeyCallback)callback {
  // Remove the modifier bits that Flutter is not interested in.
  NSEventModifierFlags modifierFlags = event.modifierFlags & ~0x100;
  NSString* type;
  switch (event.type) {
    case NSEventTypeKeyDown:
      type = @"keydown";
      break;
    case NSEventTypeKeyUp:
      type = @"keyup";
      break;
    case NSEventTypeFlagsChanged:
      if (modifierFlags < _previouslyPressedFlags) {
        type = @"keyup";
      } else if (modifierFlags > _previouslyPressedFlags) {
        type = @"keydown";
      } else {
        // ignore duplicate modifiers; This can happen in situations like switching
        // between application windows when MacOS only sends the up event to new window.
        callback(true);
        return;
      }
      break;
    default: {
      NSAssert(false, @"Unexpected key event type (got %lu).", event.type);
      callback(false);
    }
  }
  _previouslyPressedFlags = modifierFlags;
  NSMutableDictionary* keyMessage = [@{
    @"keymap" : @"macos",
    @"type" : type,
    @"keyCode" : @(event.keyCode),
    @"modifiers" : @(modifierFlags),
  } mutableCopy];
  // Calling these methods on any other type of event
  // (e.g NSEventTypeFlagsChanged) will raise an exception.
  if (event.type == NSEventTypeKeyDown || event.type == NSEventTypeKeyUp) {
    keyMessage[@"characters"] = event.characters;
    keyMessage[@"charactersIgnoringModifiers"] = event.charactersIgnoringModifiers;
  }
  NSNumber* specifiedLogicalKey = layoutMap[@(event.keyCode)];
  if (specifiedLogicalKey != nil) {
    keyMessage[@"specifiedLogicalKey"] = specifiedLogicalKey;
  }
  [self.channel sendMessage:keyMessage
                      reply:^(id reply) {
                        if (!reply) {
                          return callback(true);
                        }
                        // Only propagate the event to other responders if the framework didn't
                        // handle it.
                        callback([[reply valueForKey:@"handled"] boolValue]);
                      }];
}

#pragma mark - Private

@end

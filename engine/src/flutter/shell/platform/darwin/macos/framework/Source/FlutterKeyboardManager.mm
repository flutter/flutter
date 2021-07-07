// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyboardManager.h"

@interface FlutterKeyboardManager ()

/**
 * The owner set by initWithOwner.
 */
@property(nonatomic, weak) NSResponder* owner;

/**
 * The primary responders added by addPrimaryResponder.
 */
@property(nonatomic) NSMutableArray<id<FlutterKeyPrimaryResponder>>* primaryResponders;

/**
 * The secondary responders added by addSecondaryResponder.
 */
@property(nonatomic) NSMutableArray<id<FlutterKeySecondaryResponder>>* secondaryResponders;

- (void)dispatchToSecondaryResponders:(NSEvent*)event;

@end

@implementation FlutterKeyboardManager

- (nonnull instancetype)initWithOwner:(NSResponder*)weakOwner {
  self = [super init];
  if (self != nil) {
    _owner = weakOwner;
    _primaryResponders = [[NSMutableArray alloc] init];
    _secondaryResponders = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addPrimaryResponder:(nonnull id<FlutterKeyPrimaryResponder>)responder {
  [_primaryResponders addObject:responder];
}

- (void)addSecondaryResponder:(nonnull id<FlutterKeySecondaryResponder>)responder {
  [_secondaryResponders addObject:responder];
}

- (void)handleEvent:(nonnull NSEvent*)event {
  // Be sure to add a handling method in propagateKeyEvent when allowing more
  // event types here.
  if (event.type != NSEventTypeKeyDown && event.type != NSEventTypeKeyUp &&
      event.type != NSEventTypeFlagsChanged) {
    return;
  }
  // Having no primary responders require extra logic, but Flutter hard-codes
  // all primary responders, so this is a situation that Flutter will never
  // encounter.
  NSAssert([_primaryResponders count] >= 0, @"At least one primary responder must be added.");

  __weak __typeof__(self) weakSelf = self;
  __block int unreplied = [_primaryResponders count];
  __block BOOL anyHandled = false;
  FlutterAsyncKeyCallback replyCallback = ^(BOOL handled) {
    unreplied -= 1;
    NSAssert(unreplied >= 0, @"More primary responders replied than possible.");
    anyHandled = anyHandled || handled;
    if (unreplied == 0 && !anyHandled) {
      [weakSelf dispatchToSecondaryResponders:event];
    }
  };

  for (id<FlutterKeyPrimaryResponder> responder in _primaryResponders) {
    [responder handleEvent:event callback:replyCallback];
  }
}

#pragma mark - Private

- (void)dispatchToSecondaryResponders:(NSEvent*)event {
  for (id<FlutterKeySecondaryResponder> responder in _secondaryResponders) {
    if ([responder handleKeyEvent:event]) {
      return;
    }
  }
  switch (event.type) {
    case NSEventTypeKeyDown:
      if ([_owner.nextResponder respondsToSelector:@selector(keyDown:)]) {
        [_owner.nextResponder keyDown:event];
      }
      break;
    case NSEventTypeKeyUp:
      if ([_owner.nextResponder respondsToSelector:@selector(keyUp:)]) {
        [_owner.nextResponder keyUp:event];
      }
      break;
    case NSEventTypeFlagsChanged:
      if ([_owner.nextResponder respondsToSelector:@selector(flagsChanged:)]) {
        [_owner.nextResponder flagsChanged:event];
      }
      break;
    default:
      NSAssert(false, @"Unexpected key event type (got %lu).", event.type);
  }
}

@end

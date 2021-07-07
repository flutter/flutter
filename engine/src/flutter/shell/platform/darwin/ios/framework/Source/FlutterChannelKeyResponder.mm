// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterChannelKeyResponder.h"

#import <objc/message.h>
#include <sys/types.h>
#include "fml/memory/weak_ptr.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterUIPressProxy.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/KeyCodeMap_Internal.h"

namespace {
// An enumeration of the modifier values that the framework expects. These are
// largely the same values as the OS (UIKeyModifierShift, etc.), but because the
// framework code expects certain values, and has additional values (like the
// sided modifier values below), we translate the iOS values to the framework
// values, and add a mask for all the possible values.
typedef NS_OPTIONS(NSInteger, KeyboardModifier) {
  KeyboardModifierAlphaShift = 0x10000,
  KeyboardModifierShift = 0x20000,
  KeyboardModifierLeftShift = 0x02,
  KeyboardModifierRightShift = 0x04,
  KeyboardModifierControl = 0x40000,
  KeyboardModifierLeftControl = 0x01,
  KeyboardModifierRightControl = 0x2000,
  KeyboardModifierOption = 0x80000,
  KeyboardModifierLeftOption = 0x20,
  KeyboardModifierRightOption = 0x40,
  KeyboardModifierCommand = 0x100000,
  KeyboardModifierLeftCommand = 0x08,
  KeyboardModifierRightCommand = 0x10,
  KeyboardModifierNumericPad = 0x200000,
  KeyboardModifierMask = KeyboardModifierAlphaShift | KeyboardModifierShift |
                         KeyboardModifierLeftShift | KeyboardModifierRightShift |
                         KeyboardModifierControl | KeyboardModifierLeftControl |
                         KeyboardModifierRightControl | KeyboardModifierOption |
                         KeyboardModifierLeftOption | KeyboardModifierRightOption |
                         KeyboardModifierCommand | KeyboardModifierLeftCommand |
                         KeyboardModifierRightCommand | KeyboardModifierNumericPad,
};

/**
 * Filters out some special cases in the characters field on UIKey.
 */
static NSString* getEventCharacters(NSString* characters, UIKeyboardHIDUsage keyCode)
    API_AVAILABLE(ios(13.4)) {
  if (characters == nil) {
    return nil;
  }
  if ([characters length] == 0) {
    return nil;
  }
  if (@available(iOS 13.4, *)) {
    // On iOS, function keys return the UTF8 string "\^P" (with a literal '/',
    // '^' and a 'P', not escaped ctrl-P) as their "characters" field. This
    // isn't a valid (single) UTF8 character. Looking at the only UTF16
    // character for a function key yields a value of "16", which is a Unicode
    // "SHIFT IN" character, which is just odd. UTF8 conversion of that string
    // is what generates the three characters "\^P".
    //
    // Anyhow, we strip them all out and replace them with empty strings, since
    // function keys shouldn't be printable.
    if (functionKeyCodes.find(keyCode) != functionKeyCodes.end()) {
      return nil;
    }
  }
  return characters;
}

}  // namespace
@interface FlutterChannelKeyResponder ()

/**
 * The channel used to communicate with Flutter.
 */
@property(nonatomic) FlutterBasicMessageChannel* channel;

- (NSInteger)adjustModifiers:(nonnull FlutterUIPressProxy*)press API_AVAILABLE(ios(13.4));
- (void)updatePressedModifiers:(nonnull FlutterUIPressProxy*)press API_AVAILABLE(ios(13.4));

@property(nonatomic) KeyboardModifier pressedModifiers;
@end

@implementation FlutterChannelKeyResponder

- (nonnull instancetype)initWithChannel:(nonnull FlutterBasicMessageChannel*)channel {
  self = [super init];
  if (self != nil) {
    _channel = channel;
    _pressedModifiers = 0;
  }
  return self;
}

- (void)handlePress:(nonnull FlutterUIPressProxy*)press
           callback:(nonnull FlutterAsyncKeyCallback)callback API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // no-op
  } else {
    return;
  }
  NSString* type;
  switch (press.phase) {
    case UIPressPhaseBegan:
      type = @"keydown";
      break;
    case UIPressPhaseCancelled:
      // This event doesn't appear to happen on iOS, at least when switching
      // apps. Maybe on tvOS? In any case, it's probably best to send a keyup if
      // we do receive one, since if the event was canceled, it's likely that a
      // keyup will never be received otherwise.
    case UIPressPhaseEnded:
      type = @"keyup";
      break;
    case UIPressPhaseChanged:
      // This only happens for analog devices like joysticks.
      return;
    case UIPressPhaseStationary:
      // The entire volume of documentation of this phase on the Apple site, and
      // indeed the Internet, is:
      //   "A button was pressed but hasn’t moved since the previous event."
      // It's unclear what this is actually used for, and we've yet to see it in
      // the wild.
      return;
  }

  NSString* characters = getEventCharacters(press.key.characters, press.key.keyCode);
  NSString* charactersIgnoringModifiers =
      getEventCharacters(press.key.charactersIgnoringModifiers, press.key.keyCode);
  NSMutableDictionary* keyMessage = [@{
    @"keymap" : @"ios",
    @"type" : type,
    @"keyCode" : @(press.key.keyCode),
    @"modifiers" : @([self adjustModifiers:press]),
    @"characters" : characters == nil ? @"" : characters,
    @"charactersIgnoringModifiers" : charactersIgnoringModifiers == nil
        ? @""
        : charactersIgnoringModifiers,
  } mutableCopy];
  [self.channel sendMessage:keyMessage
                      reply:^(id reply) {
                        bool handled = reply ? [[reply valueForKey:@"handled"] boolValue] : true;
                        callback(handled);
                      }];
}

#pragma mark - Private

- (void)updatePressedModifiers:(nonnull FlutterUIPressProxy*)press API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // no-op
  } else {
    return;
  }

  bool isKeyDown = false;
  switch (press.phase) {
    case UIPressPhaseStationary:
    case UIPressPhaseChanged:
      // These kinds of events shouldn't get this far.
      NSAssert(false, @"Unexpected key event type received in updatePressedModifiers.");
      return;
    case UIPressPhaseBegan:
      isKeyDown = true;
      break;
    case UIPressPhaseCancelled:
    case UIPressPhaseEnded:
      isKeyDown = false;
      break;
  }

  void (^update)(KeyboardModifier, bool) = ^(KeyboardModifier mod, bool isOn) {
    if (isOn) {
      _pressedModifiers |= mod;
    } else {
      _pressedModifiers &= ~mod;
    }
  };
  switch (press.key.keyCode) {
    case UIKeyboardHIDUsageKeyboardCapsLock:
      update(KeyboardModifierAlphaShift, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeypadNumLock:
      update(KeyboardModifierNumericPad, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardLeftShift:
      update(KeyboardModifierLeftShift, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardRightShift:
      update(KeyboardModifierRightShift, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardLeftControl:
      update(KeyboardModifierLeftControl, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardRightControl:
      update(KeyboardModifierRightControl, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardLeftAlt:
      update(KeyboardModifierLeftOption, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardRightAlt:
      update(KeyboardModifierRightOption, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardLeftGUI:
      update(KeyboardModifierLeftCommand, isKeyDown);
      break;
    case UIKeyboardHIDUsageKeyboardRightGUI:
      update(KeyboardModifierRightCommand, isKeyDown);
      break;
    default:
      // If we didn't update any of the modifiers above, we're done.
      return;
  }
  // Update the non-sided modifier flags to match the content of the sided ones.
  update(KeyboardModifierShift,
         _pressedModifiers & (KeyboardModifierRightShift | KeyboardModifierLeftShift));
  update(KeyboardModifierControl,
         _pressedModifiers & (KeyboardModifierRightControl | KeyboardModifierLeftControl));
  update(KeyboardModifierOption,
         _pressedModifiers & (KeyboardModifierRightOption | KeyboardModifierLeftOption));
  update(KeyboardModifierCommand,
         _pressedModifiers & (KeyboardModifierRightCommand | KeyboardModifierLeftCommand));
}

// Because iOS differs from macOS in that the modifier flags still contain the
// flag for the key that is being released on the keyup event, we adjust the
// modifiers when the key being released is the matching modifier key itself.
- (NSInteger)adjustModifiers:(nonnull FlutterUIPressProxy*)press API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // no-op
  } else {
    return press.key.modifierFlags;
  }

  [self updatePressedModifiers:press];
  // Replace the supplied modifier flags with our computed ones.
  return _pressedModifiers | (press.key.modifierFlags & ~KeyboardModifierMask);
}

@end

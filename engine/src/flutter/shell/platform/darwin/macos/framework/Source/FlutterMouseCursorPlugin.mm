// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <objc/message.h>

#import "FlutterMouseCursorPlugin.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"

static NSString* const kMouseCursorChannel = @"flutter/mousecursor";

static NSString* const kActivateSystemCursorMethod = @"activateSystemCursor";
static NSString* const kKindKey = @"kind";

static NSString* const kKindValueNone = @"none";

/**
 * Maps a Flutter's constant to a platform's cursor object.
 *
 * Returns the arrow cursor for unknown constants, including kSystemShapeNone.
 */
static NSCursor* GetCursorForKind(NSString* kind) {
  // The following mapping must be kept in sync with Flutter framework's
  // mouse_cursor.dart
  if ([kind isEqualToString:@"basic"])
    return [NSCursor arrowCursor];
  else if ([kind isEqualToString:@"click"])
    return [NSCursor pointingHandCursor];
  else if ([kind isEqualToString:@"text"])
    return [NSCursor IBeamCursor];
  else if ([kind isEqualToString:@"forbidden"])
    return [NSCursor operationNotAllowedCursor];
  else if ([kind isEqualToString:@"grab"])
    return [NSCursor openHandCursor];
  else if ([kind isEqualToString:@"grabbing"])
    return [NSCursor closedHandCursor];
  else if ([kind isEqualToString:@"horizontalDoubleArrow"])
    return [NSCursor resizeLeftRightCursor];
  else if ([kind isEqualToString:@"verticalDoubleArrow"])
    return [NSCursor resizeUpDownCursor];
  else
    return [NSCursor arrowCursor];
}

@interface FlutterMouseCursorPlugin ()
/**
 * Whether the cursor is currently hidden.
 */
@property(nonatomic) BOOL hidden;

/**
 * Handles the method call that activates a system cursor.
 *
 * Returns a FlutterError if the arguments can not be recognized. Otherwise
 * returns nil.
 */
- (FlutterError*)activateSystemCursor:(nonnull NSDictionary*)arguments;

/**
 * Displays the specified cursor.
 *
 * Unhides the cursor before displaying the cursor, and updates
 * internal states.
 */
- (void)displayCursorObject:(nonnull NSCursor*)cursorObject;

/**
 * Hides the cursor.
 */
- (void)hide;

/**
 * Handles all method calls from Flutter.
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

@implementation FlutterMouseCursorPlugin

#pragma mark - Private

NSMutableDictionary* cachedSystemCursors;

- (instancetype)init {
  self = [super init];
  if (self) {
    cachedSystemCursors = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)dealloc {
  if (_hidden) {
    [NSCursor unhide];
  }
}

- (FlutterError*)activateSystemCursor:(nonnull NSDictionary*)arguments {
  NSString* kindArg = arguments[kKindKey];
  if (!kindArg) {
    return [FlutterError errorWithCode:@"error"
                               message:@"Missing argument"
                               details:@"Missing argument while trying to activate system cursor"];
  }
  if ([kindArg isEqualToString:kKindValueNone]) {
    [self hide];
    return nil;
  }
  NSCursor* cursorObject = [FlutterMouseCursorPlugin cursorFromKind:kindArg];
  [self displayCursorObject:cursorObject];
  return nil;
}

- (void)displayCursorObject:(nonnull NSCursor*)cursorObject {
  [cursorObject set];
  if (_hidden) {
    [NSCursor unhide];
  }
  _hidden = NO;
}

- (void)hide {
  if (!_hidden) {
    [NSCursor hide];
  }
  _hidden = YES;
}

+ (NSCursor*)cursorFromKind:(NSString*)kind {
  NSCursor* cachedValue = [cachedSystemCursors objectForKey:kind];
  if (!cachedValue) {
    cachedValue = GetCursorForKind(kind);
    [cachedSystemCursors setValue:cachedValue forKey:kind];
  }
  return cachedValue;
}

#pragma mark - FlutterPlugin implementation

+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:kMouseCursorChannel
                                                              binaryMessenger:registrar.messenger];
  FlutterMouseCursorPlugin* instance = [[FlutterMouseCursorPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* method = call.method;
  if ([method isEqualToString:kActivateSystemCursorMethod]) {
    result([self activateSystemCursor:call.arguments]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end

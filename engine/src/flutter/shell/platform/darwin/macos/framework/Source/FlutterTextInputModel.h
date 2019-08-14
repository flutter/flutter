// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

/**
 * The affinity of the current cursor position. If the cursor is at a position representing
 * a line break, the cursor may be drawn either at the end of the current line (upstream)
 * or at the beginning of the next (downstream).
 */
typedef NS_ENUM(NSUInteger, FlutterTextAffinity) {
  FlutterTextAffinityUpstream,
  FlutterTextAffinityDownstream
};

/**
 * Data model representing text input state during an editing session.
 */
@interface FlutterTextInputModel : NSObject

/**
 * The full text being edited.
 */
@property(nonnull, copy) NSMutableString* text;
/**
 * The range of text currently selected. This may have length zero to represent a single
 * cursor position.
 */
@property NSRange selectedRange;
/**
 * The affinity for the current cursor position.
 */
@property FlutterTextAffinity textAffinity;
/**
 * The range of text that is marked for edit, i.e. under the effects of a multi-keystroke input
 * combination.
 */
@property NSRange markedRange;

/**
 * Representation of the model's data as a state dictionary suitable for interchange with the
 * Flutter Dart layer.
 */
@property(nonnull) NSDictionary* state;

/**
 * ID of the text input client.
 */
@property(nonatomic, readonly, nonnull) NSNumber* clientID;

/**
 * Keyboard type of the client. See available options:
 * https://docs.flutter.io/flutter/services/TextInputType-class.html
 */
@property(nonatomic, readonly, nonnull) NSString* inputType;

/**
 * An action requested by the user on the input client. See available options:
 * https://docs.flutter.io/flutter/services/TextInputAction-class.html
 */
@property(nonatomic, readonly, nonnull) NSString* inputAction;

- (nullable instancetype)init NS_UNAVAILABLE;

/**
 * Initializes a text input model with a [clientId] and [config] arguments. [config] arguments
 * provide information on the text input connection.
 */
- (nullable instancetype)initWithClientID:(nonnull NSNumber*)clientID
                            configuration:(nonnull NSDictionary*)config;
@end

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERTEXTINPUTDELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERTEXTINPUTDELEGATE_H_

#import <Foundation/Foundation.h>

@class FlutterTextInputPlugin;
@class FlutterTextInputView;

typedef NS_ENUM(NSInteger, FlutterTextInputAction) {
  // NOLINTBEGIN(readability-identifier-naming)
  FlutterTextInputActionUnspecified,
  FlutterTextInputActionDone,
  FlutterTextInputActionGo,
  FlutterTextInputActionSend,
  FlutterTextInputActionSearch,
  FlutterTextInputActionNext,
  FlutterTextInputActionContinue,
  FlutterTextInputActionJoin,
  FlutterTextInputActionRoute,
  FlutterTextInputActionEmergencyCall,
  FlutterTextInputActionNewline,
  // NOLINTEND(readability-identifier-naming)
};

typedef NS_ENUM(NSInteger, FlutterFloatingCursorDragState) {
  // NOLINTBEGIN(readability-identifier-naming)
  FlutterFloatingCursorDragStateStart,
  FlutterFloatingCursorDragStateUpdate,
  FlutterFloatingCursorDragStateEnd,
  // NOLINTEND(readability-identifier-naming)
};

@protocol FlutterTextInputDelegate <NSObject>
- (void)flutterTextInputView:( FlutterTextInputView* _Nonnull)textInputView
         updateEditingClient:(int)client
                   withState:(NSDictionary* _Nonnull)state;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
         updateEditingClient:(int)client
                   withState:(NSDictionary* _Nonnull)state
                     withTag:(NSString* _Nonnull)tag;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
         updateEditingClient:(int)client
                   withDelta:(NSDictionary* _Nonnull)state;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
               performAction:(FlutterTextInputAction)action
                  withClient:(int)client;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
        updateFloatingCursor:(FlutterFloatingCursorDragState)state
                  withClient:(int)client
                withPosition:(NSDictionary* _Nonnull)point;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
    showAutocorrectionPromptRectForStart:(NSUInteger)start
                                     end:(NSUInteger)end
                              withClient:(int)client;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView showToolbar:(int)client;
- (void)flutterTextInputViewScribbleInteractionBegan:(FlutterTextInputView* _Nonnull)textInputView;
- (void)flutterTextInputViewScribbleInteractionFinished:(FlutterTextInputView* _Nonnull)textInputView;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
    insertTextPlaceholderWithSize:(CGSize)size
                       withClient:(int)client;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView removeTextPlaceholder:(int)client;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
    didResignFirstResponderWithTextInputClient:(int)client;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
    willDismissEditMenuWithTextInputClient:(int)client;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
           shareSelectedText:(NSString*  _Nonnull)selectedText;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
    searchWebWithSelectedText:(NSString*  _Nonnull)selectedText;
- (void)flutterTextInputView:(FlutterTextInputView* _Nonnull)textInputView
          lookUpSelectedText:(NSString* _Nonnull)selectedText;
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERTEXTINPUTDELEGATE_H_

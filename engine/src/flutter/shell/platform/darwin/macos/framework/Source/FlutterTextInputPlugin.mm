// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"

#import <objc/message.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputModel.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

static NSString* const kTextInputChannel = @"flutter/textinput";

// See https://docs.flutter.io/flutter/services/SystemChannels/textInput-constant.html
static NSString* const kSetClientMethod = @"TextInput.setClient";
static NSString* const kShowMethod = @"TextInput.show";
static NSString* const kHideMethod = @"TextInput.hide";
static NSString* const kClearClientMethod = @"TextInput.clearClient";
static NSString* const kSetEditingStateMethod = @"TextInput.setEditingState";
static NSString* const kUpdateEditStateResponseMethod = @"TextInputClient.updateEditingState";
static NSString* const kPerformAction = @"TextInputClient.performAction";
static NSString* const kMultilineInputType = @"TextInputType.multiline";

/**
 * Private properties of FlutterTextInputPlugin.
 */
@interface FlutterTextInputPlugin () <NSTextInputClient>

/**
 * A text input context, representing a connection to the Cocoa text input system.
 */
@property(nonatomic) NSTextInputContext* textInputContext;

/**
 * A dictionary of text input models, one per client connection, keyed
 * by the client connection ID.
 */
@property(nonatomic) NSMutableDictionary<NSNumber*, FlutterTextInputModel*>* textInputModels;

/**
 * The currently active client connection ID.
 */
@property(nonatomic, nullable) NSNumber* activeClientID;

/**
 * The currently active text input model.
 */
@property(nonatomic, readonly, nullable) FlutterTextInputModel* activeModel;

/**
 * The channel used to communicate with Flutter.
 */
@property(nonatomic) FlutterMethodChannel* channel;

/**
 * The FlutterViewController to manage input for.
 */
@property(nonatomic, weak) FlutterViewController* flutterViewController;

/**
 * Handles a Flutter system message on the text input channel.
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

@implementation FlutterTextInputPlugin

- (instancetype)initWithViewController:(FlutterViewController*)viewController {
  self = [super init];
  if (self != nil) {
    _flutterViewController = viewController;
    _channel = [FlutterMethodChannel methodChannelWithName:kTextInputChannel
                                           binaryMessenger:viewController.engine.binaryMessenger
                                                     codec:[FlutterJSONMethodCodec sharedInstance]];
    __weak FlutterTextInputPlugin* weakSelf = self;
    [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      [weakSelf handleMethodCall:call result:result];
    }];
    _textInputModels = [[NSMutableDictionary alloc] init];
    _textInputContext = [[NSTextInputContext alloc] initWithClient:self];
  }
  return self;
}

#pragma mark - Private

- (FlutterTextInputModel*)activeModel {
  return (_activeClientID == nil) ? nil : _textInputModels[_activeClientID];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  BOOL handled = YES;
  NSString* method = call.method;
  if ([method isEqualToString:kSetClientMethod]) {
    if (!call.arguments[0] || !call.arguments[1]) {
      result([FlutterError
          errorWithCode:@"error"
                message:@"Missing arguments"
                details:@"Missing arguments while trying to set a text input client"]);
      return;
    }
    NSNumber* clientID = call.arguments[0];
    if (clientID != nil &&
        (_activeClientID == nil || ![_activeClientID isEqualToNumber:clientID])) {
      _activeClientID = clientID;
      // TODO: Do we need to preserve state across setClient calls?
      FlutterTextInputModel* inputModel =
          [[FlutterTextInputModel alloc] initWithClientID:clientID configuration:call.arguments[1]];
      if (!inputModel) {
        result([FlutterError errorWithCode:@"error"
                                   message:@"Failed to create an input model"
                                   details:@"Configuration arguments might be missing"]);
        return;
      }
      _textInputModels[_activeClientID] = inputModel;
    }
  } else if ([method isEqualToString:kShowMethod]) {
    [self.flutterViewController addKeyResponder:self];
    [_textInputContext activate];
  } else if ([method isEqualToString:kHideMethod]) {
    [self.flutterViewController removeKeyResponder:self];
    [_textInputContext deactivate];
  } else if ([method isEqualToString:kClearClientMethod]) {
    _activeClientID = nil;
  } else if ([method isEqualToString:kSetEditingStateMethod]) {
    NSDictionary* state = call.arguments;
    self.activeModel.state = state;
  } else {
    handled = NO;
    NSLog(@"Unhandled text input method '%@'", method);
  }
  result(handled ? nil : FlutterMethodNotImplemented);
}

/**
 * Informs the Flutter framework of changes to the text input model's state.
 */
- (void)updateEditState {
  if (self.activeModel == nil) {
    return;
  }

  [_channel invokeMethod:kUpdateEditStateResponseMethod
               arguments:@[ _activeClientID, _textInputModels[_activeClientID].state ]];
}

#pragma mark -
#pragma mark NSResponder

/**
 * Note, the Apple docs suggest that clients should override essentially all the
 * mouse and keyboard event-handling methods of NSResponder. However, experimentation
 * indicates that only key events are processed by the native layer; Flutter processes
 * mouse events. Additionally, processing both keyUp and keyDown results in duplicate
 * processing of the same keys. So for now, limit processing to just keyDown.
 */
- (void)keyDown:(NSEvent*)event {
  [_textInputContext handleEvent:event];
}

#pragma mark -
#pragma mark NSStandardKeyBindingMethods

/**
 * Note, experimentation indicates that moveRight and moveLeft are called rather
 * than the supposedly more RTL-friendly moveForward and moveBackward.
 */
- (void)moveLeft:(nullable id)sender {
  NSRange selection = self.activeModel.selectedRange;
  if (selection.length == 0) {
    if (selection.location > 0) {
      // Move to previous location
      self.activeModel.selectedRange = NSMakeRange(selection.location - 1, 0);
      [self updateEditState];
    }
  } else {
    // Collapse current selection
    self.activeModel.selectedRange = NSMakeRange(selection.location, 0);
    [self updateEditState];
  }
}

- (void)moveRight:(nullable id)sender {
  NSRange selection = self.activeModel.selectedRange;
  if (selection.length == 0) {
    if (selection.location < self.activeModel.text.length) {
      // Move to next location
      self.activeModel.selectedRange = NSMakeRange(selection.location + 1, 0);
      [self updateEditState];
    }
  } else {
    // Collapse current selection
    self.activeModel.selectedRange = NSMakeRange(selection.location + selection.length, 0);
    [self updateEditState];
  }
}

- (void)deleteBackward:(id)sender {
  NSRange selection = self.activeModel.selectedRange;
  if (selection.location == 0)
    return;
  NSRange range = selection;
  if (selection.length == 0) {
    NSUInteger location = (selection.location == NSNotFound) ? self.activeModel.text.length - 1
                                                             : selection.location - 1;
    range = NSMakeRange(location, 1);
  }
  self.activeModel.selectedRange = NSMakeRange(range.location, 0);
  [self insertText:@"" replacementRange:range];  // Updates edit state
}

#pragma mark -
#pragma mark NSTextInputClient

- (void)insertText:(id)string replacementRange:(NSRange)range {
  if (self.activeModel != nil) {
    if (range.location == NSNotFound && range.length == 0) {
      // Use selection
      range = self.activeModel.selectedRange;
    }
    if (range.location > self.activeModel.text.length)
      range.location = self.activeModel.text.length;
    if (range.length > (self.activeModel.text.length - range.location))
      range.length = self.activeModel.text.length - range.location;
    [self.activeModel.text replaceCharactersInRange:range withString:string];
    self.activeModel.selectedRange = NSMakeRange(range.location + ((NSString*)string).length, 0);
    [self updateEditState];
  }
}

- (void)doCommandBySelector:(SEL)selector {
  if ([self respondsToSelector:selector]) {
    // Note: The more obvious [self performSelector...] doesn't give ARC enough information to
    // handle retain semantics properly. See https://stackoverflow.com/questions/7017281/ for more
    // information.
    IMP imp = [self methodForSelector:selector];
    void (*func)(id, SEL, id) = reinterpret_cast<void (*)(id, SEL, id)>(imp);
    func(self, selector, nil);
  }
}

- (void)insertNewline:(id)sender {
  if (self.activeModel != nil) {
    if ([self.activeModel.inputType isEqualToString:kMultilineInputType]) {
      [self insertText:@"\n" replacementRange:self.activeModel.selectedRange];
    }
    [_channel invokeMethod:kPerformAction
                 arguments:@[ _activeClientID, self.activeModel.inputAction ]];
  }
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange {
  if (self.activeModel != nil) {
    [self.activeModel.text replaceCharactersInRange:replacementRange withString:string];
    self.activeModel.selectedRange = selectedRange;
    [self updateEditState];
  }
}

- (void)unmarkText {
  if (self.activeModel != nil) {
    self.activeModel.markedRange = NSMakeRange(NSNotFound, 0);
    [self updateEditState];
  }
}

- (NSRange)selectedRange {
  return (self.activeModel == nil) ? NSMakeRange(NSNotFound, 0) : self.activeModel.selectedRange;
}

- (NSRange)markedRange {
  return (self.activeModel == nil) ? NSMakeRange(NSNotFound, 0) : self.activeModel.markedRange;
}

- (BOOL)hasMarkedText {
  return (self.activeModel == nil) ? NO : self.activeModel.markedRange.location != NSNotFound;
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)range
                                               actualRange:(NSRangePointer)actualRange {
  if (self.activeModel) {
    if (actualRange != nil)
      *actualRange = range;
    NSString* substring = [self.activeModel.text substringWithRange:range];
    return [[NSAttributedString alloc] initWithString:substring attributes:nil];
  } else {
    return nil;
  }
}

- (NSArray<NSString*>*)validAttributesForMarkedText {
  return @[];
}

- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
  // TODO: Implement.
  // Note: This function can't easily be implemented under the system-message architecture.
  return CGRectZero;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point {
  // TODO: Implement.
  // Note: This function can't easily be implemented under the system-message architecture.
  return 0;
}

@end

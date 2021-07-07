// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"

#import <objc/message.h>

#include <algorithm>
#include <memory>

#include "flutter/shell/platform/common/text_input_model.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputSemanticsObject.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

static NSString* const kTextInputChannel = @"flutter/textinput";

// See https://api.flutter.dev/flutter/services/SystemChannels/textInput-constant.html
static NSString* const kSetClientMethod = @"TextInput.setClient";
static NSString* const kShowMethod = @"TextInput.show";
static NSString* const kHideMethod = @"TextInput.hide";
static NSString* const kClearClientMethod = @"TextInput.clearClient";
static NSString* const kSetEditingStateMethod = @"TextInput.setEditingState";
static NSString* const kSetEditableSizeAndTransform = @"TextInput.setEditableSizeAndTransform";
static NSString* const kSetCaretRect = @"TextInput.setCaretRect";
static NSString* const kUpdateEditStateResponseMethod = @"TextInputClient.updateEditingState";
static NSString* const kPerformAction = @"TextInputClient.performAction";
static NSString* const kMultilineInputType = @"TextInputType.multiline";

static NSString* const kTextAffinityDownstream = @"TextAffinity.downstream";
static NSString* const kTextAffinityUpstream = @"TextAffinity.upstream";

static NSString* const kTextInputAction = @"inputAction";
static NSString* const kTextInputType = @"inputType";
static NSString* const kTextInputTypeName = @"name";

static NSString* const kSelectionBaseKey = @"selectionBase";
static NSString* const kSelectionExtentKey = @"selectionExtent";
static NSString* const kSelectionAffinityKey = @"selectionAffinity";
static NSString* const kSelectionIsDirectionalKey = @"selectionIsDirectional";
static NSString* const kComposingBaseKey = @"composingBase";
static NSString* const kComposingExtentKey = @"composingExtent";
static NSString* const kTextKey = @"text";
static NSString* const kTransformKey = @"transform";

/**
 * The affinity of the current cursor position. If the cursor is at a position representing
 * a line break, the cursor may be drawn either at the end of the current line (upstream)
 * or at the beginning of the next (downstream).
 */
typedef NS_ENUM(NSUInteger, FlutterTextAffinity) {
  FlutterTextAffinityUpstream,
  FlutterTextAffinityDownstream
};

/*
 * Updates a range given base and extent fields.
 */
static flutter::TextRange RangeFromBaseExtent(NSNumber* base,
                                              NSNumber* extent,
                                              const flutter::TextRange& range) {
  if (base == nil || extent == nil) {
    return range;
  }
  if (base.intValue == -1 && extent.intValue == -1) {
    return flutter::TextRange(0, 0);
  }
  return flutter::TextRange([base unsignedLongValue], [extent unsignedLongValue]);
}

/**
 * Private properties of FlutterTextInputPlugin.
 */
@interface FlutterTextInputPlugin ()

/**
 * A text input context, representing a connection to the Cocoa text input system.
 */
@property(nonatomic) NSTextInputContext* textInputContext;

/**
 * The channel used to communicate with Flutter.
 */
@property(nonatomic) FlutterMethodChannel* channel;

/**
 * The FlutterViewController to manage input for.
 */
@property(nonatomic, weak) FlutterViewController* flutterViewController;

/**
 * Whether the text input is shown in the view.
 *
 * Defaults to TRUE on startup.
 */
@property(nonatomic) BOOL shown;

/**
 * The current state of the keyboard and pressed keys.
 */
@property(nonatomic) uint64_t previouslyPressedFlags;

/**
 * The affinity for the current cursor position.
 */
@property FlutterTextAffinity textAffinity;

/**
 * ID of the text input client.
 */
@property(nonatomic, nonnull) NSNumber* clientID;

/**
 * Keyboard type of the client. See available options:
 * https://api.flutter.dev/flutter/services/TextInputType-class.html
 */
@property(nonatomic, nonnull) NSString* inputType;

/**
 * An action requested by the user on the input client. See available options:
 * https://api.flutter.dev/flutter/services/TextInputAction-class.html
 */
@property(nonatomic, nonnull) NSString* inputAction;

/**
 * Handles a Flutter system message on the text input channel.
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

/**
 * Updates the text input model with state received from the framework via the
 * TextInput.setEditingState message.
 */
- (void)setEditingState:(NSDictionary*)state;

/**
 * Informs the Flutter framework of changes to the text input model's state.
 */
- (void)updateEditState;

/**
 * Updates the stringValue and selectedRange that stored in the NSTextView interface
 * that this plugin inherits from.
 *
 * If there is a FlutterTextField uses this plugin as its field editor, this method
 * will update the stringValue and selectedRange through the API of the FlutterTextField.
 */
- (void)updateTextAndSelection;

@end

@implementation FlutterTextInputPlugin {
  /**
   * The currently active text input model.
   */
  std::unique_ptr<flutter::TextInputModel> _activeModel;

  /**
   * Transform for current the editable. Used to determine position of accent selection menu.
   */
  CATransform3D _editableTransform;

  /**
   * Current position of caret in local (editable) coordinates.
   */
  CGRect _caretRect;
}

- (instancetype)initWithViewController:(FlutterViewController*)viewController {
  // The view needs a non-zero frame.
  self = [super initWithFrame:NSMakeRect(0, 0, 1, 1)];
  if (self != nil) {
    _flutterViewController = viewController;
    _channel = [FlutterMethodChannel methodChannelWithName:kTextInputChannel
                                           binaryMessenger:viewController.engine.binaryMessenger
                                                     codec:[FlutterJSONMethodCodec sharedInstance]];
    _shown = FALSE;
    // NSTextView does not support _weak reference, so this class has to
    // use __unsafe_unretained and manage the reference by itself.
    //
    // Since the dealloc removes the handler, the pointer should
    // be valid if the handler is ever called.
    __unsafe_unretained FlutterTextInputPlugin* unsafeSelf = self;
    [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      [unsafeSelf handleMethodCall:call result:result];
    }];
    _textInputContext = [[NSTextInputContext alloc] initWithClient:self];
    _previouslyPressedFlags = 0;

    _flutterViewController = viewController;

    // Initialize with the zero matrix which is not
    // an affine transform.
    _editableTransform = CATransform3D();
    _caretRect = CGRectNull;
  }
  return self;
}

- (BOOL)isFirstResponder {
  if (!self.flutterViewController.viewLoaded) {
    return false;
  }
  return [self.flutterViewController.view.window firstResponder] == self;
}

- (void)dealloc {
  [_channel setMethodCallHandler:nil];
}

#pragma mark - Private

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
    if (clientID != nil) {
      NSDictionary* config = call.arguments[1];

      _clientID = clientID;
      _inputAction = config[kTextInputAction];
      NSDictionary* inputTypeInfo = config[kTextInputType];
      _inputType = inputTypeInfo[kTextInputTypeName];
      self.textAffinity = FlutterTextAffinityUpstream;

      _activeModel = std::make_unique<flutter::TextInputModel>();
    }
  } else if ([method isEqualToString:kShowMethod]) {
    _shown = TRUE;
    [_textInputContext activate];
  } else if ([method isEqualToString:kHideMethod]) {
    _shown = FALSE;
    [_textInputContext deactivate];
  } else if ([method isEqualToString:kClearClientMethod]) {
    _clientID = nil;
    _inputAction = nil;
    _inputType = nil;
    _activeModel = nullptr;
  } else if ([method isEqualToString:kSetEditingStateMethod]) {
    NSDictionary* state = call.arguments;
    [self setEditingState:state];

    // Close the loop, since the framework state could have been updated by the
    // engine since it sent this update, and needs to now be made to match the
    // engine's version of the state.
    [self updateEditState];
  } else if ([method isEqualToString:kSetEditableSizeAndTransform]) {
    NSDictionary* state = call.arguments;
    [self setEditableTransform:state[kTransformKey]];
  } else if ([method isEqualToString:kSetCaretRect]) {
    NSDictionary* rect = call.arguments;
    [self updateCaretRect:rect];
  } else {
    handled = NO;
  }
  result(handled ? nil : FlutterMethodNotImplemented);
}

- (void)setEditableTransform:(NSArray*)matrix {
  CATransform3D* transform = &_editableTransform;

  transform->m11 = [matrix[0] doubleValue];
  transform->m12 = [matrix[1] doubleValue];
  transform->m13 = [matrix[2] doubleValue];
  transform->m14 = [matrix[3] doubleValue];

  transform->m21 = [matrix[4] doubleValue];
  transform->m22 = [matrix[5] doubleValue];
  transform->m23 = [matrix[6] doubleValue];
  transform->m24 = [matrix[7] doubleValue];

  transform->m31 = [matrix[8] doubleValue];
  transform->m32 = [matrix[9] doubleValue];
  transform->m33 = [matrix[10] doubleValue];
  transform->m34 = [matrix[11] doubleValue];

  transform->m41 = [matrix[12] doubleValue];
  transform->m42 = [matrix[13] doubleValue];
  transform->m43 = [matrix[14] doubleValue];
  transform->m44 = [matrix[15] doubleValue];
}

- (void)updateCaretRect:(NSDictionary*)dictionary {
  NSAssert(dictionary[@"x"] != nil && dictionary[@"y"] != nil && dictionary[@"width"] != nil &&
               dictionary[@"height"] != nil,
           @"Expected a dictionary representing a CGRect, got %@", dictionary);
  _caretRect = CGRectMake([dictionary[@"x"] doubleValue], [dictionary[@"y"] doubleValue],
                          [dictionary[@"width"] doubleValue], [dictionary[@"height"] doubleValue]);
}

- (void)setEditingState:(NSDictionary*)state {
  NSString* selectionAffinity = state[kSelectionAffinityKey];
  if (selectionAffinity != nil) {
    _textAffinity = [selectionAffinity isEqualToString:kTextAffinityUpstream]
                        ? FlutterTextAffinityUpstream
                        : FlutterTextAffinityDownstream;
  }

  NSString* text = state[kTextKey];
  if (text != nil) {
    _activeModel->SetText([text UTF8String]);
  }

  flutter::TextRange selected_range = RangeFromBaseExtent(
      state[kSelectionBaseKey], state[kSelectionExtentKey], _activeModel->selection());
  _activeModel->SetSelection(selected_range);

  flutter::TextRange composing_range = RangeFromBaseExtent(
      state[kComposingBaseKey], state[kComposingExtentKey], _activeModel->composing_range());
  size_t cursor_offset = selected_range.base() - composing_range.start();
  _activeModel->SetComposingRange(composing_range, cursor_offset);
  [_client becomeFirstResponder];
  [self updateTextAndSelection];
}

- (void)updateEditState {
  if (_activeModel == nullptr) {
    return;
  }

  NSString* const textAffinity = (self.textAffinity == FlutterTextAffinityUpstream)
                                     ? kTextAffinityUpstream
                                     : kTextAffinityDownstream;

  int composingBase = _activeModel->composing() ? _activeModel->composing_range().base() : -1;
  int composingExtent = _activeModel->composing() ? _activeModel->composing_range().extent() : -1;

  NSDictionary* state = @{
    kSelectionBaseKey : @(_activeModel->selection().base()),
    kSelectionExtentKey : @(_activeModel->selection().extent()),
    kSelectionAffinityKey : textAffinity,
    kSelectionIsDirectionalKey : @NO,
    kComposingBaseKey : @(composingBase),
    kComposingExtentKey : @(composingExtent),
    kTextKey : [NSString stringWithUTF8String:_activeModel->GetText().c_str()]
  };

  [_channel invokeMethod:kUpdateEditStateResponseMethod arguments:@[ self.clientID, state ]];
  [self updateTextAndSelection];
}

- (void)updateTextAndSelection {
  NSAssert(_activeModel != nullptr, @"Flutter text model must not be null.");
  NSString* text = @(_activeModel->GetText().data());
  int start = _activeModel->selection().base();
  int extend = _activeModel->selection().extent();
  NSRange selection = NSMakeRange(MIN(start, extend), ABS(start - extend));
  // There may be a native text field client if VoiceOver is on.
  // In this case, this plugin has to update text and selection through
  // the client in order for VoiceOver to announce the text editing
  // properly.
  if (_client) {
    [_client updateString:text withSelection:selection];
  } else {
    self.string = text;
    [self setSelectedRange:selection];
  }
}

#pragma mark -
#pragma mark FlutterKeySecondaryResponder

/**
 * Handles key down events received from the view controller, responding YES if
 * the event was handled.
 *
 * Note, the Apple docs suggest that clients should override essentially all the
 * mouse and keyboard event-handling methods of NSResponder. However, experimentation
 * indicates that only key events are processed by the native layer; Flutter processes
 * mouse events. Additionally, processing both keyUp and keyDown results in duplicate
 * processing of the same keys.
 */
- (BOOL)handleKeyEvent:(NSEvent*)event {
  if (event.type == NSEventTypeKeyUp ||
      (event.type == NSEventTypeFlagsChanged && event.modifierFlags < _previouslyPressedFlags)) {
    return NO;
  }
  _previouslyPressedFlags = event.modifierFlags;
  if (!_shown) {
    return NO;
  }
  return [_textInputContext handleEvent:event];
}

#pragma mark -
#pragma mark NSResponder

- (void)keyDown:(NSEvent*)event {
  [self.flutterViewController keyDown:event];
}

- (void)keyUp:(NSEvent*)event {
  [self.flutterViewController keyUp:event];
}

- (BOOL)performKeyEquivalent:(NSEvent*)event {
  return [self.flutterViewController performKeyEquivalent:event];
}

- (void)flagsChanged:(NSEvent*)event {
  [self.flutterViewController flagsChanged:event];
}

- (void)mouseDown:(NSEvent*)event {
  [self.flutterViewController mouseDown:event];
}

- (void)mouseUp:(NSEvent*)event {
  [self.flutterViewController mouseUp:event];
}

- (void)mouseDragged:(NSEvent*)event {
  [self.flutterViewController mouseDragged:event];
}

- (void)rightMouseDown:(NSEvent*)event {
  [self.flutterViewController rightMouseDown:event];
}

- (void)rightMouseUp:(NSEvent*)event {
  [self.flutterViewController rightMouseUp:event];
}

- (void)rightMouseDragged:(NSEvent*)event {
  [self.flutterViewController rightMouseDragged:event];
}

- (void)otherMouseDown:(NSEvent*)event {
  [self.flutterViewController otherMouseDown:event];
}

- (void)otherMouseUp:(NSEvent*)event {
  [self.flutterViewController otherMouseUp:event];
}

- (void)otherMouseDragged:(NSEvent*)event {
  [self.flutterViewController otherMouseDragged:event];
}

- (void)mouseMoved:(NSEvent*)event {
  [self.flutterViewController mouseMoved:event];
}

- (void)scrollWheel:(NSEvent*)event {
  [self.flutterViewController scrollWheel:event];
}

#pragma mark -
#pragma mark NSTextInputClient

- (void)insertText:(id)string replacementRange:(NSRange)range {
  if (_activeModel == nullptr) {
    return;
  }

  if (range.location != NSNotFound) {
    // The selected range can actually have negative numbers, since it can start
    // at the end of the range if the user selected the text going backwards.
    // Cast to a signed type to determine whether or not the selection is reversed.
    long signedLength = static_cast<long>(range.length);
    long location = range.location;
    long textLength = _activeModel->text_range().end();

    size_t base = std::clamp(location, 0L, textLength);
    size_t extent = std::clamp(location + signedLength, 0L, textLength);
    _activeModel->SetSelection(flutter::TextRange(base, extent));
  }

  _activeModel->AddText([string UTF8String]);
  if (_activeModel->composing()) {
    _activeModel->CommitComposing();
    _activeModel->EndComposing();
  }
  [self updateEditState];
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
  if (_activeModel == nullptr) {
    return;
  }
  if (_activeModel->composing()) {
    _activeModel->CommitComposing();
    _activeModel->EndComposing();
  }
  if ([self.inputType isEqualToString:kMultilineInputType]) {
    [self insertText:@"\n" replacementRange:self.selectedRange];
  }
  [_channel invokeMethod:kPerformAction arguments:@[ self.clientID, self.inputAction ]];
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange {
  if (_activeModel == nullptr) {
    return;
  }
  if (!_activeModel->composing()) {
    _activeModel->BeginComposing();
  }

  // Input string may be NSString or NSAttributedString.
  BOOL isAttributedString = [string isKindOfClass:[NSAttributedString class]];
  NSString* marked_text = isAttributedString ? [string string] : string;
  _activeModel->UpdateComposingText([marked_text UTF8String]);

  [self updateEditState];
}

- (void)unmarkText {
  if (_activeModel == nullptr) {
    return;
  }
  _activeModel->CommitComposing();
  _activeModel->EndComposing();
  [self updateEditState];
}

- (NSRange)markedRange {
  if (_activeModel == nullptr) {
    return NSMakeRange(NSNotFound, 0);
  }
  return NSMakeRange(
      _activeModel->composing_range().base(),
      _activeModel->composing_range().extent() - _activeModel->composing_range().base());
}

- (BOOL)hasMarkedText {
  return _activeModel != nullptr && _activeModel->composing_range().length() > 0;
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)range
                                               actualRange:(NSRangePointer)actualRange {
  if (_activeModel == nullptr) {
    return nil;
  }
  if (actualRange != nil) {
    *actualRange = range;
  }
  NSString* text = [NSString stringWithUTF8String:_activeModel->GetText().c_str()];
  NSString* substring = [text substringWithRange:range];
  return [[NSAttributedString alloc] initWithString:substring attributes:nil];
}

- (NSArray<NSString*>*)validAttributesForMarkedText {
  return @[];
}

- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
  if (!self.flutterViewController.viewLoaded) {
    return CGRectZero;
  }
  // This only determines position of caret instead of any arbitrary range, but it's enough
  // to properly position accent selection popup
  if (CATransform3DIsAffine(_editableTransform) && !CGRectEqualToRect(_caretRect, CGRectNull)) {
    CGRect rect =
        CGRectApplyAffineTransform(_caretRect, CATransform3DGetAffineTransform(_editableTransform));

    // convert to window coordinates
    rect = [self.flutterViewController.flutterView convertRect:rect toView:nil];

    // convert to screen coordinates
    return [self.flutterViewController.flutterView.window convertRectToScreen:rect];
  } else {
    return CGRectZero;
  }
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point {
  // TODO: Implement.
  // Note: This function can't easily be implemented under the system-message architecture.
  return 0;
}

@end

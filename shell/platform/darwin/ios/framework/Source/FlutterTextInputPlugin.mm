// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#include "flutter/fml/platform/darwin/string_range_sanitization.h"

#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

static const char _kTextAffinityDownstream[] = "TextAffinity.downstream";
static const char _kTextAffinityUpstream[] = "TextAffinity.upstream";

static UIKeyboardType ToUIKeyboardType(NSDictionary* type) {
  NSString* inputType = type[@"name"];
  if ([inputType isEqualToString:@"TextInputType.text"])
    return UIKeyboardTypeDefault;
  if ([inputType isEqualToString:@"TextInputType.multiline"])
    return UIKeyboardTypeDefault;
  if ([inputType isEqualToString:@"TextInputType.number"]) {
    if ([type[@"signed"] boolValue])
      return UIKeyboardTypeNumbersAndPunctuation;
    if ([type[@"decimal"] boolValue])
      return UIKeyboardTypeDecimalPad;
    return UIKeyboardTypeNumberPad;
  }
  if ([inputType isEqualToString:@"TextInputType.phone"])
    return UIKeyboardTypePhonePad;
  if ([inputType isEqualToString:@"TextInputType.emailAddress"])
    return UIKeyboardTypeEmailAddress;
  if ([inputType isEqualToString:@"TextInputType.url"])
    return UIKeyboardTypeURL;
  return UIKeyboardTypeDefault;
}

static UITextAutocapitalizationType ToUITextAutoCapitalizationType(NSDictionary* type) {
  NSString* textCapitalization = type[@"textCapitalization"];
  if ([textCapitalization isEqualToString:@"TextCapitalization.characters"]) {
    return UITextAutocapitalizationTypeAllCharacters;
  } else if ([textCapitalization isEqualToString:@"TextCapitalization.sentences"]) {
    return UITextAutocapitalizationTypeSentences;
  } else if ([textCapitalization isEqualToString:@"TextCapitalization.words"]) {
    return UITextAutocapitalizationTypeWords;
  }
  return UITextAutocapitalizationTypeNone;
}

static UIReturnKeyType ToUIReturnKeyType(NSString* inputType) {
  // Where did the term "unspecified" come from? iOS has a "default" and Android
  // has "unspecified." These 2 terms seem to mean the same thing but we need
  // to pick just one. "unspecified" was chosen because "default" is often a
  // reserved word in languages with switch statements (dart, java, etc).
  if ([inputType isEqualToString:@"TextInputAction.unspecified"])
    return UIReturnKeyDefault;

  if ([inputType isEqualToString:@"TextInputAction.done"])
    return UIReturnKeyDone;

  if ([inputType isEqualToString:@"TextInputAction.go"])
    return UIReturnKeyGo;

  if ([inputType isEqualToString:@"TextInputAction.send"])
    return UIReturnKeySend;

  if ([inputType isEqualToString:@"TextInputAction.search"])
    return UIReturnKeySearch;

  if ([inputType isEqualToString:@"TextInputAction.next"])
    return UIReturnKeyNext;

  if (@available(iOS 9.0, *))
    if ([inputType isEqualToString:@"TextInputAction.continueAction"])
      return UIReturnKeyContinue;

  if ([inputType isEqualToString:@"TextInputAction.join"])
    return UIReturnKeyJoin;

  if ([inputType isEqualToString:@"TextInputAction.route"])
    return UIReturnKeyRoute;

  if ([inputType isEqualToString:@"TextInputAction.emergencyCall"])
    return UIReturnKeyEmergencyCall;

  if ([inputType isEqualToString:@"TextInputAction.newline"])
    return UIReturnKeyDefault;

  // Present default key if bad input type is given.
  return UIReturnKeyDefault;
}

static UITextContentType ToUITextContentType(NSArray<NSString*>* hints) {
  if (hints == nil || hints.count == 0) {
    return @"";
  }

  NSString* hint = hints[0];
  if (@available(iOS 10.0, *)) {
    if ([hint isEqualToString:@"addressCityAndState"]) {
      return UITextContentTypeAddressCityAndState;
    }

    if ([hint isEqualToString:@"addressState"]) {
      return UITextContentTypeAddressState;
    }

    if ([hint isEqualToString:@"addressCity"]) {
      return UITextContentTypeAddressCity;
    }

    if ([hint isEqualToString:@"sublocality"]) {
      return UITextContentTypeSublocality;
    }

    if ([hint isEqualToString:@"streetAddressLine1"]) {
      return UITextContentTypeStreetAddressLine1;
    }

    if ([hint isEqualToString:@"streetAddressLine2"]) {
      return UITextContentTypeStreetAddressLine2;
    }

    if ([hint isEqualToString:@"countryName"]) {
      return UITextContentTypeCountryName;
    }

    if ([hint isEqualToString:@"fullStreetAddress"]) {
      return UITextContentTypeFullStreetAddress;
    }

    if ([hint isEqualToString:@"postalCode"]) {
      return UITextContentTypePostalCode;
    }

    if ([hint isEqualToString:@"location"]) {
      return UITextContentTypeLocation;
    }

    if ([hint isEqualToString:@"creditCardNumber"]) {
      return UITextContentTypeCreditCardNumber;
    }

    if ([hint isEqualToString:@"email"]) {
      return UITextContentTypeEmailAddress;
    }

    if ([hint isEqualToString:@"jobTitle"]) {
      return UITextContentTypeJobTitle;
    }

    if ([hint isEqualToString:@"givenName"]) {
      return UITextContentTypeGivenName;
    }

    if ([hint isEqualToString:@"middleName"]) {
      return UITextContentTypeMiddleName;
    }

    if ([hint isEqualToString:@"familyName"]) {
      return UITextContentTypeFamilyName;
    }

    if ([hint isEqualToString:@"name"]) {
      return UITextContentTypeName;
    }

    if ([hint isEqualToString:@"namePrefix"]) {
      return UITextContentTypeNamePrefix;
    }

    if ([hint isEqualToString:@"nameSuffix"]) {
      return UITextContentTypeNameSuffix;
    }

    if ([hint isEqualToString:@"nickname"]) {
      return UITextContentTypeNickname;
    }

    if ([hint isEqualToString:@"organizationName"]) {
      return UITextContentTypeOrganizationName;
    }

    if ([hint isEqualToString:@"telephoneNumber"]) {
      return UITextContentTypeTelephoneNumber;
    }
  }

  if (@available(iOS 11.0, *)) {
    if ([hint isEqualToString:@"password"]) {
      return UITextContentTypePassword;
    }
  }

  if (@available(iOS 12.0, *)) {
    if ([hint isEqualToString:@"oneTimeCode"]) {
      return UITextContentTypeOneTimeCode;
    }
  }

  return hints[0];
}

static NSString* uniqueIdFromDictionary(NSDictionary* dictionary) {
  NSDictionary* autofill = dictionary[@"autofill"];
  return autofill == nil ? nil : autofill[@"uniqueIdentifier"];
}

#pragma mark - FlutterTextPosition

@implementation FlutterTextPosition

+ (instancetype)positionWithIndex:(NSUInteger)index {
  return [[[FlutterTextPosition alloc] initWithIndex:index] autorelease];
}

- (instancetype)initWithIndex:(NSUInteger)index {
  self = [super init];
  if (self) {
    _index = index;
  }
  return self;
}

@end

#pragma mark - FlutterTextRange

@implementation FlutterTextRange

+ (instancetype)rangeWithNSRange:(NSRange)range {
  return [[[FlutterTextRange alloc] initWithNSRange:range] autorelease];
}

- (instancetype)initWithNSRange:(NSRange)range {
  self = [super init];
  if (self) {
    _range = range;
  }
  return self;
}

- (UITextPosition*)start {
  return [FlutterTextPosition positionWithIndex:self.range.location];
}

- (UITextPosition*)end {
  return [FlutterTextPosition positionWithIndex:self.range.location + self.range.length];
}

- (BOOL)isEmpty {
  return self.range.length == 0;
}

- (id)copyWithZone:(NSZone*)zone {
  return [[FlutterTextRange allocWithZone:zone] initWithNSRange:self.range];
}

@end

@interface FlutterTextInputView ()
@property(nonatomic, copy) NSString* autofillId;
@end

@implementation FlutterTextInputView {
  int _textInputClient;
  const char* _selectionAffinity;
  FlutterTextRange* _selectedTextRange;
}

@synthesize tokenizer = _tokenizer;

- (instancetype)init {
  self = [super init];

  if (self) {
    _textInputClient = 0;
    _selectionAffinity = _kTextAffinityUpstream;

    // UITextInput
    _text = [[NSMutableString alloc] init];
    _markedText = [[NSMutableString alloc] init];
    _selectedTextRange = [[FlutterTextRange alloc] initWithNSRange:NSMakeRange(0, 0)];

    // UITextInputTraits
    _autocapitalizationType = UITextAutocapitalizationTypeSentences;
    _autocorrectionType = UITextAutocorrectionTypeDefault;
    _spellCheckingType = UITextSpellCheckingTypeDefault;
    _enablesReturnKeyAutomatically = NO;
    _keyboardAppearance = UIKeyboardAppearanceDefault;
    _keyboardType = UIKeyboardTypeDefault;
    _returnKeyType = UIReturnKeyDone;
    _secureTextEntry = NO;
    if (@available(iOS 11.0, *)) {
      _smartQuotesType = UITextSmartQuotesTypeYes;
      _smartDashesType = UITextSmartDashesTypeYes;
    }
  }

  return self;
}

- (void)dealloc {
  [_text release];
  [_markedText release];
  [_markedTextRange release];
  [_selectedTextRange release];
  [_tokenizer release];
  [_autofillId release];
  [super dealloc];
}

- (void)setTextInputClient:(int)client {
  _textInputClient = client;
}

- (void)setTextInputState:(NSDictionary*)state {
  NSString* newText = state[@"text"];
  BOOL textChanged = ![self.text isEqualToString:newText];
  if (textChanged) {
    [self.inputDelegate textWillChange:self];
    [self.text setString:newText];
  }

  NSInteger composingBase = [state[@"composingBase"] intValue];
  NSInteger composingExtent = [state[@"composingExtent"] intValue];
  NSRange composingRange = [self clampSelection:NSMakeRange(MIN(composingBase, composingExtent),
                                                            ABS(composingBase - composingExtent))
                                        forText:self.text];
  self.markedTextRange =
      composingRange.length > 0 ? [FlutterTextRange rangeWithNSRange:composingRange] : nil;

  NSInteger selectionBase = [state[@"selectionBase"] intValue];
  NSInteger selectionExtent = [state[@"selectionExtent"] intValue];
  NSRange selectedRange = [self clampSelection:NSMakeRange(MIN(selectionBase, selectionExtent),
                                                           ABS(selectionBase - selectionExtent))
                                       forText:self.text];
  NSRange oldSelectedRange = [(FlutterTextRange*)self.selectedTextRange range];
  if (selectedRange.location != oldSelectedRange.location ||
      selectedRange.length != oldSelectedRange.length) {
    [self.inputDelegate selectionWillChange:self];
    [self setSelectedTextRange:[FlutterTextRange rangeWithNSRange:selectedRange]
            updateEditingState:NO];
    _selectionAffinity = _kTextAffinityDownstream;
    if ([state[@"selectionAffinity"] isEqualToString:@(_kTextAffinityUpstream)])
      _selectionAffinity = _kTextAffinityUpstream;
    [self.inputDelegate selectionDidChange:self];
  }

  if (textChanged) {
    [self.inputDelegate textDidChange:self];

    // For consistency with Android behavior, send an update to the framework.
    [self updateEditingState];
  }
}

- (NSRange)clampSelection:(NSRange)range forText:(NSString*)text {
  int start = MIN(MAX(range.location, 0), text.length);
  int length = MIN(range.length, text.length - start);
  return NSMakeRange(start, length);
}

#pragma mark - UIResponder Overrides

- (BOOL)canBecomeFirstResponder {
  // Only the currently focused input field can
  // become the first responder. This prevents iOS
  // from changing focus by itself.
  return _textInputClient != 0;
}

#pragma mark - UITextInput Overrides

- (id<UITextInputTokenizer>)tokenizer {
  if (_tokenizer == nil) {
    _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
  }
  return _tokenizer;
}

- (UITextRange*)selectedTextRange {
  return [[_selectedTextRange copy] autorelease];
}

- (void)setSelectedTextRange:(UITextRange*)selectedTextRange {
  [self setSelectedTextRange:selectedTextRange updateEditingState:YES];
}

- (void)setSelectedTextRange:(UITextRange*)selectedTextRange updateEditingState:(BOOL)update {
  if (_selectedTextRange != selectedTextRange) {
    UITextRange* oldSelectedRange = _selectedTextRange;
    if (self.hasText) {
      FlutterTextRange* flutterTextRange = (FlutterTextRange*)selectedTextRange;
      _selectedTextRange = [[FlutterTextRange
          rangeWithNSRange:fml::RangeForCharactersInRange(self.text, flutterTextRange.range)] copy];
    } else {
      _selectedTextRange = [selectedTextRange copy];
    }
    [oldSelectedRange release];

    if (update)
      [self updateEditingState];
  }
}

- (id)insertDictationResultPlaceholder {
  return @"";
}

- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult {
}

- (NSString*)textInRange:(UITextRange*)range {
  if (!range) {
    return nil;
  }
  NSAssert([range isKindOfClass:[FlutterTextRange class]],
           @"Expected a FlutterTextRange for range (got %@).", [range class]);
  NSRange textRange = ((FlutterTextRange*)range).range;
  NSAssert(textRange.location != NSNotFound, @"Expected a valid text range.");
  return [self.text substringWithRange:textRange];
}

- (void)replaceRange:(UITextRange*)range withText:(NSString*)text {
  NSRange replaceRange = ((FlutterTextRange*)range).range;
  NSRange selectedRange = _selectedTextRange.range;
  // Adjust the text selection:
  // * reduce the length by the intersection length
  // * adjust the location by newLength - oldLength + intersectionLength
  NSRange intersectionRange = NSIntersectionRange(replaceRange, selectedRange);
  if (replaceRange.location <= selectedRange.location)
    selectedRange.location += text.length - replaceRange.length;
  if (intersectionRange.location != NSNotFound) {
    selectedRange.location += intersectionRange.length;
    selectedRange.length -= intersectionRange.length;
  }

  [self.text replaceCharactersInRange:[self clampSelection:replaceRange forText:self.text]
                           withString:text];
  [self setSelectedTextRange:[FlutterTextRange rangeWithNSRange:[self clampSelection:selectedRange
                                                                             forText:self.text]]
          updateEditingState:NO];

  [self updateEditingState];
}

- (BOOL)shouldChangeTextInRange:(UITextRange*)range replacementText:(NSString*)text {
  if (self.returnKeyType == UIReturnKeyDefault && [text isEqualToString:@"\n"]) {
    [_textInputDelegate performAction:FlutterTextInputActionNewline withClient:_textInputClient];
    return YES;
  }

  if ([text isEqualToString:@"\n"]) {
    FlutterTextInputAction action;
    switch (self.returnKeyType) {
      case UIReturnKeyDefault:
        action = FlutterTextInputActionUnspecified;
        break;
      case UIReturnKeyDone:
        action = FlutterTextInputActionDone;
        break;
      case UIReturnKeyGo:
        action = FlutterTextInputActionGo;
        break;
      case UIReturnKeySend:
        action = FlutterTextInputActionSend;
        break;
      case UIReturnKeySearch:
      case UIReturnKeyGoogle:
      case UIReturnKeyYahoo:
        action = FlutterTextInputActionSearch;
        break;
      case UIReturnKeyNext:
        action = FlutterTextInputActionNext;
        break;
      case UIReturnKeyContinue:
        action = FlutterTextInputActionContinue;
        break;
      case UIReturnKeyJoin:
        action = FlutterTextInputActionJoin;
        break;
      case UIReturnKeyRoute:
        action = FlutterTextInputActionRoute;
        break;
      case UIReturnKeyEmergencyCall:
        action = FlutterTextInputActionEmergencyCall;
        break;
    }

    [_textInputDelegate performAction:action withClient:_textInputClient];
    return NO;
  }

  return YES;
}

- (void)setMarkedText:(NSString*)markedText selectedRange:(NSRange)markedSelectedRange {
  NSRange selectedRange = _selectedTextRange.range;
  NSRange markedTextRange = ((FlutterTextRange*)self.markedTextRange).range;

  if (markedText == nil)
    markedText = @"";

  if (markedTextRange.length > 0) {
    // Replace text in the marked range with the new text.
    [self replaceRange:self.markedTextRange withText:markedText];
    markedTextRange.length = markedText.length;
  } else {
    // Replace text in the selected range with the new text.
    [self replaceRange:_selectedTextRange withText:markedText];
    markedTextRange = NSMakeRange(selectedRange.location, markedText.length);
  }

  self.markedTextRange =
      markedTextRange.length > 0 ? [FlutterTextRange rangeWithNSRange:markedTextRange] : nil;

  NSUInteger selectionLocation = markedSelectedRange.location + markedTextRange.location;
  selectedRange = NSMakeRange(selectionLocation, markedSelectedRange.length);
  [self setSelectedTextRange:[FlutterTextRange rangeWithNSRange:[self clampSelection:selectedRange
                                                                             forText:self.text]]
          updateEditingState:YES];
}

- (void)unmarkText {
  self.markedTextRange = nil;
  [self updateEditingState];
}

- (UITextRange*)textRangeFromPosition:(UITextPosition*)fromPosition
                           toPosition:(UITextPosition*)toPosition {
  NSUInteger fromIndex = ((FlutterTextPosition*)fromPosition).index;
  NSUInteger toIndex = ((FlutterTextPosition*)toPosition).index;
  return [FlutterTextRange rangeWithNSRange:NSMakeRange(fromIndex, toIndex - fromIndex)];
}

- (NSUInteger)decrementOffsetPosition:(NSUInteger)position {
  return fml::RangeForCharacterAtIndex(self.text, MAX(0, position - 1)).location;
}

- (NSUInteger)incrementOffsetPosition:(NSUInteger)position {
  NSRange charRange = fml::RangeForCharacterAtIndex(self.text, position);
  return MIN(position + charRange.length, self.text.length);
}

- (UITextPosition*)positionFromPosition:(UITextPosition*)position offset:(NSInteger)offset {
  NSUInteger offsetPosition = ((FlutterTextPosition*)position).index;

  NSInteger newLocation = (NSInteger)offsetPosition + offset;
  if (newLocation < 0 || newLocation > (NSInteger)self.text.length) {
    return nil;
  }

  if (offset >= 0) {
    for (NSInteger i = 0; i < offset && offsetPosition < self.text.length; ++i)
      offsetPosition = [self incrementOffsetPosition:offsetPosition];
  } else {
    for (NSInteger i = 0; i < ABS(offset) && offsetPosition > 0; ++i)
      offsetPosition = [self decrementOffsetPosition:offsetPosition];
  }
  return [FlutterTextPosition positionWithIndex:offsetPosition];
}

- (UITextPosition*)positionFromPosition:(UITextPosition*)position
                            inDirection:(UITextLayoutDirection)direction
                                 offset:(NSInteger)offset {
  // TODO(cbracken) Add RTL handling.
  switch (direction) {
    case UITextLayoutDirectionLeft:
    case UITextLayoutDirectionUp:
      return [self positionFromPosition:position offset:offset * -1];
    case UITextLayoutDirectionRight:
    case UITextLayoutDirectionDown:
      return [self positionFromPosition:position offset:1];
  }
}

- (UITextPosition*)beginningOfDocument {
  return [FlutterTextPosition positionWithIndex:0];
}

- (UITextPosition*)endOfDocument {
  return [FlutterTextPosition positionWithIndex:self.text.length];
}

- (NSComparisonResult)comparePosition:(UITextPosition*)position toPosition:(UITextPosition*)other {
  NSUInteger positionIndex = ((FlutterTextPosition*)position).index;
  NSUInteger otherIndex = ((FlutterTextPosition*)other).index;
  if (positionIndex < otherIndex)
    return NSOrderedAscending;
  if (positionIndex > otherIndex)
    return NSOrderedDescending;
  return NSOrderedSame;
}

- (NSInteger)offsetFromPosition:(UITextPosition*)from toPosition:(UITextPosition*)toPosition {
  return ((FlutterTextPosition*)toPosition).index - ((FlutterTextPosition*)from).index;
}

- (UITextPosition*)positionWithinRange:(UITextRange*)range
                   farthestInDirection:(UITextLayoutDirection)direction {
  NSUInteger index;
  switch (direction) {
    case UITextLayoutDirectionLeft:
    case UITextLayoutDirectionUp:
      index = ((FlutterTextPosition*)range.start).index;
      break;
    case UITextLayoutDirectionRight:
    case UITextLayoutDirectionDown:
      index = ((FlutterTextPosition*)range.end).index;
      break;
  }
  return [FlutterTextPosition positionWithIndex:index];
}

- (UITextRange*)characterRangeByExtendingPosition:(UITextPosition*)position
                                      inDirection:(UITextLayoutDirection)direction {
  NSUInteger positionIndex = ((FlutterTextPosition*)position).index;
  NSUInteger startIndex;
  NSUInteger endIndex;
  switch (direction) {
    case UITextLayoutDirectionLeft:
    case UITextLayoutDirectionUp:
      startIndex = [self decrementOffsetPosition:positionIndex];
      endIndex = positionIndex;
      break;
    case UITextLayoutDirectionRight:
    case UITextLayoutDirectionDown:
      startIndex = positionIndex;
      endIndex = [self incrementOffsetPosition:positionIndex];
      break;
  }
  return [FlutterTextRange rangeWithNSRange:NSMakeRange(startIndex, endIndex - startIndex)];
}

#pragma mark - UITextInput text direction handling

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition*)position
                                              inDirection:(UITextStorageDirection)direction {
  // TODO(cbracken) Add RTL handling.
  return UITextWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection
                       forRange:(UITextRange*)range {
  // TODO(cbracken) Add RTL handling.
}

#pragma mark - UITextInput cursor, selection rect handling

// The following methods are required to support force-touch cursor positioning
// and to position the
// candidates view for multi-stage input methods (e.g., Japanese) when using a
// physical keyboard.

- (CGRect)firstRectForRange:(UITextRange*)range {
  // multi-stage text is handled somewhere else.
  if (_markedTextRange != nil) {
    return CGRectZero;
  }

  NSUInteger start = ((FlutterTextPosition*)range.start).index;
  NSUInteger end = ((FlutterTextPosition*)range.end).index;
  [_textInputDelegate showAutocorrectionPromptRectForStart:start
                                                       end:end
                                                withClient:_textInputClient];
  // TODO(cbracken) Implement.
  return CGRectZero;
}

- (CGRect)caretRectForPosition:(UITextPosition*)position {
  // TODO(cbracken) Implement.
  return CGRectZero;
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point {
  // TODO(cbracken) Implement.
  NSUInteger currentIndex = ((FlutterTextPosition*)_selectedTextRange.start).index;
  return [FlutterTextPosition positionWithIndex:currentIndex];
}

- (NSArray*)selectionRectsForRange:(UITextRange*)range {
  // TODO(cbracken) Implement.
  return @[];
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange*)range {
  // TODO(cbracken) Implement.
  return range.start;
}

- (UITextRange*)characterRangeAtPoint:(CGPoint)point {
  // TODO(cbracken) Implement.
  NSUInteger currentIndex = ((FlutterTextPosition*)_selectedTextRange.start).index;
  return [FlutterTextRange rangeWithNSRange:fml::RangeForCharacterAtIndex(self.text, currentIndex)];
}

- (void)beginFloatingCursorAtPoint:(CGPoint)point {
  [_textInputDelegate updateFloatingCursor:FlutterFloatingCursorDragStateStart
                                withClient:_textInputClient
                              withPosition:@{@"X" : @(point.x), @"Y" : @(point.y)}];
}

- (void)updateFloatingCursorAtPoint:(CGPoint)point {
  [_textInputDelegate updateFloatingCursor:FlutterFloatingCursorDragStateUpdate
                                withClient:_textInputClient
                              withPosition:@{@"X" : @(point.x), @"Y" : @(point.y)}];
}

- (void)endFloatingCursor {
  [_textInputDelegate updateFloatingCursor:FlutterFloatingCursorDragStateEnd
                                withClient:_textInputClient
                              withPosition:@{@"X" : @(0), @"Y" : @(0)}];
}

#pragma mark - UIKeyInput Overrides

- (void)updateEditingState {
  NSUInteger selectionBase = ((FlutterTextPosition*)_selectedTextRange.start).index;
  NSUInteger selectionExtent = ((FlutterTextPosition*)_selectedTextRange.end).index;

  // Empty compositing range is represented by the framework's TextRange.empty.
  NSInteger composingBase = -1;
  NSInteger composingExtent = -1;
  if (self.markedTextRange != nil) {
    composingBase = ((FlutterTextPosition*)self.markedTextRange.start).index;
    composingExtent = ((FlutterTextPosition*)self.markedTextRange.end).index;
  }

  NSDictionary* state = @{
    @"selectionBase" : @(selectionBase),
    @"selectionExtent" : @(selectionExtent),
    @"selectionAffinity" : @(_selectionAffinity),
    @"selectionIsDirectional" : @(false),
    @"composingBase" : @(composingBase),
    @"composingExtent" : @(composingExtent),
    @"text" : [NSString stringWithString:self.text],
  };

  if (_textInputClient == 0 && _autofillId != nil) {
    [_textInputDelegate updateEditingClient:_textInputClient withState:state withTag:_autofillId];
  } else {
    [_textInputDelegate updateEditingClient:_textInputClient withState:state];
  }
}

- (BOOL)hasText {
  return self.text.length > 0;
}

- (void)insertText:(NSString*)text {
  _selectionAffinity = _kTextAffinityDownstream;
  [self replaceRange:_selectedTextRange withText:text];
}

- (void)deleteBackward {
  _selectionAffinity = _kTextAffinityDownstream;

  // When deleting Thai vowel, _selectedTextRange has location
  // but does not have length, so we have to manually set it.
  // In addition, we needed to delete only a part of grapheme cluster
  // because it is the expected behavior of Thai input.
  // https://github.com/flutter/flutter/issues/24203
  // https://github.com/flutter/flutter/issues/21745
  // https://github.com/flutter/flutter/issues/39399
  //
  // This is needed for correct handling of the deletion of Thai vowel input.
  // TODO(cbracken): Get a good understanding of expected behavior of Thai
  // input and ensure that this is the correct solution.
  // https://github.com/flutter/flutter/issues/28962
  if (_selectedTextRange.isEmpty && [self hasText]) {
    UITextRange* oldSelectedRange = _selectedTextRange;
    NSRange oldRange = ((FlutterTextRange*)oldSelectedRange).range;
    if (oldRange.location > 0) {
      NSRange newRange = NSMakeRange(oldRange.location - 1, 1);
      _selectedTextRange = [[FlutterTextRange rangeWithNSRange:newRange] copy];
      [oldSelectedRange release];
    }
  }

  if (!_selectedTextRange.isEmpty)
    [self replaceRange:_selectedTextRange withText:@""];
}

- (BOOL)accessibilityElementsHidden {
  // We are hiding this accessibility element.
  // There are 2 accessible elements involved in text entry in 2 different parts of the view
  // hierarchy. This `FlutterTextInputView` is injected at the top of key window. We use this as a
  // `UITextInput` protocol to bridge text edit events between Flutter and iOS.
  //
  // We also create ur own custom `UIAccessibilityElements` tree with our `SemanticsObject` to
  // mimic the semantics tree from Flutter. We want the text field to be represented as a
  // `TextInputSemanticsObject` in that `SemanticsObject` tree rather than in this
  // `FlutterTextInputView` bridge which doesn't appear above a text field from the Flutter side.
  return YES;
}

@end

@interface FlutterTextInputPlugin ()
@property(nonatomic, retain) FlutterTextInputView* nonAutofillInputView;
@property(nonatomic, retain) FlutterTextInputView* nonAutofillSecureInputView;
@property(nonatomic, retain) NSMutableArray<FlutterTextInputView*>* inputViews;
@property(nonatomic, assign) FlutterTextInputView* activeView;
@end

@implementation FlutterTextInputPlugin

@synthesize textInputDelegate = _textInputDelegate;

- (instancetype)init {
  self = [super init];

  if (self) {
    _nonAutofillInputView = [[FlutterTextInputView alloc] init];
    _nonAutofillInputView.secureTextEntry = NO;
    _nonAutofillSecureInputView = [[FlutterTextInputView alloc] init];
    _nonAutofillSecureInputView.secureTextEntry = YES;
    _inputViews = [[NSMutableArray alloc] init];

    _activeView = _nonAutofillInputView;
  }

  return self;
}

- (void)dealloc {
  [self hideTextInput];
  [_nonAutofillInputView release];
  [_nonAutofillSecureInputView release];
  [_inputViews release];

  [super dealloc];
}

- (UIView<UITextInput>*)textInputView {
  return _activeView;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* method = call.method;
  id args = call.arguments;
  if ([method isEqualToString:@"TextInput.show"]) {
    [self showTextInput];
    result(nil);
  } else if ([method isEqualToString:@"TextInput.hide"]) {
    [self hideTextInput];
    result(nil);
  } else if ([method isEqualToString:@"TextInput.setClient"]) {
    [self setTextInputClient:[args[0] intValue] withConfiguration:args[1]];
    result(nil);
  } else if ([method isEqualToString:@"TextInput.setEditingState"]) {
    [self setTextInputEditingState:args];
    result(nil);
  } else if ([method isEqualToString:@"TextInput.clearClient"]) {
    [self clearTextInputClient];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)showTextInput {
  UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
  NSAssert(keyWindow != nullptr,
           @"The application must have a key window since the keyboard client "
           @"must be part of the responder chain to function");
  _activeView.textInputDelegate = _textInputDelegate;

  if (_activeView.window != keyWindow) {
    [keyWindow addSubview:_activeView];
  }
  [_activeView becomeFirstResponder];
}

- (void)hideTextInput {
  [_activeView resignFirstResponder];
}

- (void)setTextInputClient:(int)client withConfiguration:(NSDictionary*)configuration {
  UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
  NSArray* fields = configuration[@"fields"];
  NSString* clientUniqueId = uniqueIdFromDictionary(configuration);
  bool isSecureTextEntry = [configuration[@"obscureText"] boolValue];

  if (fields == nil) {
    _activeView = isSecureTextEntry ? _nonAutofillSecureInputView : _nonAutofillInputView;
    [FlutterTextInputPlugin setupInputView:_activeView withConfiguration:configuration];

    if (_activeView.window != keyWindow) {
      [keyWindow addSubview:_activeView];
    }
  } else {
    NSAssert(clientUniqueId != nil, @"The client's unique id can't be null");
    for (FlutterTextInputView* view in _inputViews) {
      [view removeFromSuperview];
    }

    for (UIView* view in keyWindow.subviews) {
      if ([view isKindOfClass:[FlutterTextInputView class]]) {
        [view removeFromSuperview];
      }
    }

    [_inputViews removeAllObjects];

    for (NSDictionary* field in fields) {
      FlutterTextInputView* newInputView = [[[FlutterTextInputView alloc] init] autorelease];
      newInputView.textInputDelegate = _textInputDelegate;
      [_inputViews addObject:newInputView];

      NSString* autofillId = uniqueIdFromDictionary(field);
      newInputView.autofillId = autofillId;

      if ([clientUniqueId isEqualToString:autofillId]) {
        _activeView = newInputView;
      }

      [FlutterTextInputPlugin setupInputView:newInputView withConfiguration:field];
      [keyWindow addSubview:newInputView];
    }
  }

  [_activeView setTextInputClient:client];
  [_activeView reloadInputViews];
}

+ (void)setupInputView:(FlutterTextInputView*)inputView
     withConfiguration:(NSDictionary*)configuration {
  NSDictionary* inputType = configuration[@"inputType"];
  NSString* keyboardAppearance = configuration[@"keyboardAppearance"];
  NSDictionary* autofill = configuration[@"autofill"];

  inputView.secureTextEntry = [configuration[@"obscureText"] boolValue];
  inputView.keyboardType = ToUIKeyboardType(inputType);
  inputView.returnKeyType = ToUIReturnKeyType(configuration[@"inputAction"]);
  inputView.autocapitalizationType = ToUITextAutoCapitalizationType(configuration);

  if (@available(iOS 11.0, *)) {
    NSString* smartDashesType = configuration[@"smartDashesType"];
    // This index comes from the SmartDashesType enum in the framework.
    bool smartDashesIsDisabled = smartDashesType && [smartDashesType isEqualToString:@"0"];
    inputView.smartDashesType =
        smartDashesIsDisabled ? UITextSmartDashesTypeNo : UITextSmartDashesTypeYes;
    NSString* smartQuotesType = configuration[@"smartQuotesType"];
    // This index comes from the SmartQuotesType enum in the framework.
    bool smartQuotesIsDisabled = smartQuotesType && [smartQuotesType isEqualToString:@"0"];
    inputView.smartQuotesType =
        smartQuotesIsDisabled ? UITextSmartQuotesTypeNo : UITextSmartQuotesTypeYes;
  }
  if ([keyboardAppearance isEqualToString:@"Brightness.dark"]) {
    inputView.keyboardAppearance = UIKeyboardAppearanceDark;
  } else if ([keyboardAppearance isEqualToString:@"Brightness.light"]) {
    inputView.keyboardAppearance = UIKeyboardAppearanceLight;
  } else {
    inputView.keyboardAppearance = UIKeyboardAppearanceDefault;
  }
  NSString* autocorrect = configuration[@"autocorrect"];
  inputView.autocorrectionType = autocorrect && ![autocorrect boolValue]
                                     ? UITextAutocorrectionTypeNo
                                     : UITextAutocorrectionTypeDefault;
  if (@available(iOS 10.0, *)) {
    if (autofill == nil) {
      inputView.textContentType = @"";
    } else {
      inputView.textContentType = ToUITextContentType(autofill[@"hints"]);
      [inputView setTextInputState:autofill[@"editingValue"]];
      // An input field needs to be visible in order to get
      // autofilled when it's not the one that triggered
      // autofill.
      inputView.frame = CGRectMake(0, 0, 1, 1);
    }
  }
}

- (void)setTextInputEditingState:(NSDictionary*)state {
  [_activeView setTextInputState:state];
}

- (void)clearTextInputClient {
  [_activeView setTextInputClient:0];
}

@end

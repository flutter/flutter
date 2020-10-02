// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include "flutter/fml/platform/darwin/string_range_sanitization.h"

static const char _kTextAffinityDownstream[] = "TextAffinity.downstream";
static const char _kTextAffinityUpstream[] = "TextAffinity.upstream";

// The "canonical" invalid CGRect, similar to CGRectNull, used to
// indicate a CGRect involved in firstRectForRange calculation is
// invalid. The specific value is chosen so that if firstRectForRange
// returns kInvalidFirstRect, iOS will not show the IME candidates view.
const CGRect kInvalidFirstRect = {{-1, -1}, {9999, 9999}};

#pragma mark - TextInputConfiguration Field Names
static NSString* const kSecureTextEntry = @"obscureText";
static NSString* const kKeyboardType = @"inputType";
static NSString* const kKeyboardAppearance = @"keyboardAppearance";
static NSString* const kInputAction = @"inputAction";

static NSString* const kSmartDashesType = @"smartDashesType";
static NSString* const kSmartQuotesType = @"smartQuotesType";

static NSString* const kAssociatedAutofillFields = @"fields";

// TextInputConfiguration.autofill and sub-field names
static NSString* const kAutofillProperties = @"autofill";
static NSString* const kAutofillId = @"uniqueIdentifier";
static NSString* const kAutofillEditingValue = @"editingValue";
static NSString* const kAutofillHints = @"hints";

static NSString* const kAutocorrectionType = @"autocorrect";

#pragma mark - Static Functions

static UIKeyboardType ToUIKeyboardType(NSDictionary* type) {
  NSString* inputType = type[@"name"];
  if ([inputType isEqualToString:@"TextInputType.address"])
    return UIKeyboardTypeDefault;
  if ([inputType isEqualToString:@"TextInputType.datetime"])
    return UIKeyboardTypeNumbersAndPunctuation;
  if ([inputType isEqualToString:@"TextInputType.emailAddress"])
    return UIKeyboardTypeEmailAddress;
  if ([inputType isEqualToString:@"TextInputType.multiline"])
    return UIKeyboardTypeDefault;
  if ([inputType isEqualToString:@"TextInputType.name"])
    return UIKeyboardTypeNamePhonePad;
  if ([inputType isEqualToString:@"TextInputType.number"]) {
    if ([type[@"signed"] boolValue])
      return UIKeyboardTypeNumbersAndPunctuation;
    if ([type[@"decimal"] boolValue])
      return UIKeyboardTypeDecimalPad;
    return UIKeyboardTypeNumberPad;
  }
  if ([inputType isEqualToString:@"TextInputType.phone"])
    return UIKeyboardTypePhonePad;
  if ([inputType isEqualToString:@"TextInputType.text"])
    return UIKeyboardTypeDefault;
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

    if ([hint isEqualToString:@"newPassword"]) {
      return UITextContentTypeNewPassword;
    }
  }

  return hints[0];
}

// Retrieves the autofillId from an input field's configuration. Returns
// nil if the field is nil and the input field is not a password field.
static NSString* autofillIdFromDictionary(NSDictionary* dictionary) {
  NSDictionary* autofill = dictionary[kAutofillProperties];
  if (autofill) {
    return autofill[kAutofillId];
  }

  // When autofill is nil, the field may still need an autofill id
  // if the field is for password.
  return [dictionary[kSecureTextEntry] boolValue] ? @"password" : nil;
}

// There're 2 types of autofills on native iOS:
// - Regular autofill, includes contact information autofill and
//   one-time-code autofill, takes place in the form of predictive
//   text in the quick type bar. This type of autofill does not save
//   user input.
// - Password autofill, includes automatic strong password and regular
//   password autofill. The former happens automatically when a
//   "new password" field is detected, and only that password field
//   will be populated. The latter appears in the quick type bar when
//   an eligible input field becomes the first responder, and may
//   fill both the username and the password fields. iOS will attempt
//   to save user input for both kinds of password fields.
typedef NS_ENUM(NSInteger, FlutterAutofillType) {
  // The field does not have autofillable content. Additionally if
  // the field is currently in the autofill context, it will be
  // removed from the context without triggering autofill save.
  FlutterAutofillTypeNone,
  FlutterAutofillTypeRegular,
  FlutterAutofillTypePassword,
};

static BOOL isFieldPasswordRelated(NSDictionary* configuration) {
  if (@available(iOS 10.0, *)) {
    BOOL isSecureTextEntry = [configuration[kSecureTextEntry] boolValue];
    if (isSecureTextEntry)
      return YES;

    if (!autofillIdFromDictionary(configuration)) {
      return NO;
    }
    NSDictionary* autofill = configuration[kAutofillProperties];
    UITextContentType contentType = ToUITextContentType(autofill[kAutofillHints]);

    if (@available(iOS 11.0, *)) {
      if ([contentType isEqualToString:UITextContentTypePassword] ||
          [contentType isEqualToString:UITextContentTypeUsername]) {
        return YES;
      }
    }

    if (@available(iOS 12.0, *)) {
      if ([contentType isEqualToString:UITextContentTypeNewPassword]) {
        return YES;
      }
    }
  }
  return NO;
}

static FlutterAutofillType autofillTypeOf(NSDictionary* configuration) {
  for (NSDictionary* field in configuration[kAssociatedAutofillFields]) {
    if (isFieldPasswordRelated(field)) {
      return FlutterAutofillTypePassword;
    }
  }

  if (isFieldPasswordRelated(configuration)) {
    return FlutterAutofillTypePassword;
  }

  if (@available(iOS 10.0, *)) {
    NSDictionary* autofill = configuration[kAutofillProperties];
    UITextContentType contentType = ToUITextContentType(autofill[kAutofillHints]);
    return [contentType isEqualToString:@""] ? FlutterAutofillTypeNone : FlutterAutofillTypeRegular;
  }

  return FlutterAutofillTypeNone;
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

- (BOOL)isEqualTo:(FlutterTextRange*)other {
  return NSEqualRanges(self.range, other.range);
}
@end

// A FlutterTextInputView that masquerades as a UITextField, and forwards
// selectors it can't respond to to a shared UITextField instance.
//
// Relevant API docs claim that password autofill supports any custom view
// that adopts the UITextInput protocol, automatic strong password seems to
// currently only support UITextFields, and password saving only supports
// UITextFields and UITextViews, as of iOS 13.5.
@interface FlutterSecureTextInputView : FlutterTextInputView
@property(nonatomic, strong, readonly) UITextField* textField;
@end

@implementation FlutterSecureTextInputView {
  UITextField* _textField;
}

- (void)dealloc {
  [_textField release];
  [super dealloc];
}

- (UITextField*)textField {
  if (!_textField) {
    _textField = [[UITextField alloc] init];
  }
  return _textField;
}

- (BOOL)isKindOfClass:(Class)aClass {
  return [super isKindOfClass:aClass] || (aClass == [UITextField class]);
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
  NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
  if (!signature) {
    signature = [self.textField methodSignatureForSelector:aSelector];
  }
  return signature;
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
  [anInvocation invokeWithTarget:self.textField];
}

@end

@interface FlutterTextInputView ()
@property(nonatomic, copy) NSString* autofillId;
@property(nonatomic, readonly) CATransform3D editableTransform;
@property(nonatomic, assign) CGRect markedRect;
@property(nonatomic) BOOL isVisibleToAutofill;

- (void)setEditableTransform:(NSArray*)matrix;
@end

@implementation FlutterTextInputView {
  int _textInputClient;
  const char* _selectionAffinity;
  FlutterTextRange* _selectedTextRange;
  CGRect _cachedFirstRect;
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
    _markedRect = kInvalidFirstRect;
    _cachedFirstRect = kInvalidFirstRect;
    // Initialize with the zero matrix which is not
    // an affine transform.
    _editableTransform = CATransform3D();

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

- (void)configureWithDictionary:(NSDictionary*)configuration {
  NSDictionary* inputType = configuration[kKeyboardType];
  NSString* keyboardAppearance = configuration[kKeyboardAppearance];
  NSDictionary* autofill = configuration[kAutofillProperties];

  self.secureTextEntry = [configuration[kSecureTextEntry] boolValue];
  self.keyboardType = ToUIKeyboardType(inputType);
  self.returnKeyType = ToUIReturnKeyType(configuration[kInputAction]);
  self.autocapitalizationType = ToUITextAutoCapitalizationType(configuration);

  if (@available(iOS 11.0, *)) {
    NSString* smartDashesType = configuration[kSmartDashesType];
    // This index comes from the SmartDashesType enum in the framework.
    bool smartDashesIsDisabled = smartDashesType && [smartDashesType isEqualToString:@"0"];
    self.smartDashesType =
        smartDashesIsDisabled ? UITextSmartDashesTypeNo : UITextSmartDashesTypeYes;
    NSString* smartQuotesType = configuration[kSmartQuotesType];
    // This index comes from the SmartQuotesType enum in the framework.
    bool smartQuotesIsDisabled = smartQuotesType && [smartQuotesType isEqualToString:@"0"];
    self.smartQuotesType =
        smartQuotesIsDisabled ? UITextSmartQuotesTypeNo : UITextSmartQuotesTypeYes;
  }
  if ([keyboardAppearance isEqualToString:@"Brightness.dark"]) {
    self.keyboardAppearance = UIKeyboardAppearanceDark;
  } else if ([keyboardAppearance isEqualToString:@"Brightness.light"]) {
    self.keyboardAppearance = UIKeyboardAppearanceLight;
  } else {
    self.keyboardAppearance = UIKeyboardAppearanceDefault;
  }
  NSString* autocorrect = configuration[kAutocorrectionType];
  self.autocorrectionType = autocorrect && ![autocorrect boolValue]
                                ? UITextAutocorrectionTypeNo
                                : UITextAutocorrectionTypeDefault;
  if (@available(iOS 10.0, *)) {
    self.autofillId = autofillIdFromDictionary(configuration);
    if (autofill == nil) {
      self.textContentType = @"";
    } else {
      self.textContentType = ToUITextContentType(autofill[kAutofillHints]);
      [self setTextInputState:autofill[kAutofillEditingValue]];
      NSAssert(_autofillId, @"The autofill configuration must contain an autofill id");
    }
    // The input field needs to be visible for the system autofill
    // to find it.
    self.isVisibleToAutofill = autofill || _secureTextEntry;
  }
}

- (UITextContentType)textContentType {
  return _textContentType;
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

  NSRange selectedRange = [self clampSelectionFromBase:[state[@"selectionBase"] intValue]
                                                extent:[state[@"selectionExtent"] intValue]
                                               forText:self.text];

  NSRange oldSelectedRange = [(FlutterTextRange*)self.selectedTextRange range];
  if (!NSEqualRanges(selectedRange, oldSelectedRange)) {
    [self.inputDelegate selectionWillChange:self];

    [self setSelectedTextRangeLocal:[FlutterTextRange rangeWithNSRange:selectedRange]];

    _selectionAffinity = _kTextAffinityDownstream;
    if ([state[@"selectionAffinity"] isEqualToString:@(_kTextAffinityUpstream)])
      _selectionAffinity = _kTextAffinityUpstream;
    [self.inputDelegate selectionDidChange:self];
  }

  if (textChanged) {
    [self.inputDelegate textDidChange:self];
  }
}

// Extracts the selection information from the editing state dictionary.
//
// The state may contain an invalid selection, such as when no selection was
// explicitly set in the framework. This is handled here by setting the
// selection to (0,0). In contrast, Android handles this situation by
// clearing the selection, but the result in both cases is that the cursor
// is placed at the beginning of the field.
- (NSRange)clampSelectionFromBase:(int)selectionBase
                           extent:(int)selectionExtent
                          forText:(NSString*)text {
  int loc = MIN(selectionBase, selectionExtent);
  int len = ABS(selectionExtent - selectionBase);
  return loc < 0 ? NSMakeRange(0, 0)
                 : [self clampSelection:NSMakeRange(loc, len) forText:self.text];
}

- (NSRange)clampSelection:(NSRange)range forText:(NSString*)text {
  int start = MIN(MAX(range.location, 0), text.length);
  int length = MIN(range.length, text.length - start);
  return NSMakeRange(start, length);
}

- (BOOL)isVisibleToAutofill {
  return self.frame.size.width > 0 && self.frame.size.height > 0;
}

// An input view is generally ignored by password autofill attempts, if it's
// not the first responder and is zero-sized. For input fields that are in the
// autofill context but do not belong to the current autofill group, setting
// their frames to CGRectZero prevents ios autofill from taking them into
// account.
- (void)setIsVisibleToAutofill:(BOOL)isVisibleToAutofill {
  self.frame = isVisibleToAutofill ? CGRectMake(0, 0, 1, 1) : CGRectZero;
}

#pragma mark - UIResponder Overrides

- (BOOL)canBecomeFirstResponder {
  // Only the currently focused input field can
  // become the first responder. This prevents iOS
  // from changing focus by itself (the framework
  // focus will be out of sync if that happens).
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

// Change the range of selected text, without notifying the framework.
- (void)setSelectedTextRangeLocal:(UITextRange*)selectedTextRange {
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
  }
}

- (void)setSelectedTextRange:(UITextRange*)selectedTextRange {
  [self setSelectedTextRangeLocal:selectedTextRange];
  [self updateEditingState];
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

// Replace the text within the specified range with the given text,
// without notifying the framework.
- (void)replaceRangeLocal:(NSRange)range withText:(NSString*)text {
  NSRange selectedRange = _selectedTextRange.range;

  // Adjust the text selection:
  // * reduce the length by the intersection length
  // * adjust the location by newLength - oldLength + intersectionLength
  NSRange intersectionRange = NSIntersectionRange(range, selectedRange);
  if (range.location <= selectedRange.location)
    selectedRange.location += text.length - range.length;
  if (intersectionRange.location != NSNotFound) {
    selectedRange.location += intersectionRange.length;
    selectedRange.length -= intersectionRange.length;
  }

  [self.text replaceCharactersInRange:[self clampSelection:range forText:self.text]
                           withString:text];
  [self setSelectedTextRangeLocal:[FlutterTextRange
                                      rangeWithNSRange:[self clampSelection:selectedRange
                                                                    forText:self.text]]];
}

- (void)replaceRange:(UITextRange*)range withText:(NSString*)text {
  NSRange replaceRange = ((FlutterTextRange*)range).range;
  [self replaceRangeLocal:replaceRange withText:text];
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
    [self replaceRangeLocal:markedTextRange withText:markedText];
    markedTextRange.length = markedText.length;
  } else {
    // Replace text in the selected range with the new text.
    [self replaceRangeLocal:selectedRange withText:markedText];
    markedTextRange = NSMakeRange(selectedRange.location, markedText.length);
  }

  self.markedTextRange =
      markedTextRange.length > 0 ? [FlutterTextRange rangeWithNSRange:markedTextRange] : nil;

  NSUInteger selectionLocation = markedSelectedRange.location + markedTextRange.location;
  selectedRange = NSMakeRange(selectionLocation, markedSelectedRange.length);
  [self setSelectedTextRangeLocal:[FlutterTextRange
                                      rangeWithNSRange:[self clampSelection:selectedRange
                                                                    forText:self.text]]];
  [self updateEditingState];
}

- (void)unmarkText {
  if (!self.markedTextRange)
    return;
  self.markedTextRange = nil;
  [self updateEditingState];
}

- (UITextRange*)textRangeFromPosition:(UITextPosition*)fromPosition
                           toPosition:(UITextPosition*)toPosition {
  NSUInteger fromIndex = ((FlutterTextPosition*)fromPosition).index;
  NSUInteger toIndex = ((FlutterTextPosition*)toPosition).index;
  if (toIndex >= fromIndex) {
    return [FlutterTextRange rangeWithNSRange:NSMakeRange(fromIndex, toIndex - fromIndex)];
  } else {
    // toIndex may be less than fromIndex, because
    // UITextInputStringTokenizer does not handle CJK characters
    // well in some cases. See:
    // https://github.com/flutter/flutter/issues/58750#issuecomment-644469521
    // Swap fromPosition and toPosition to match the behavior of native
    // UITextViews.
    return [FlutterTextRange rangeWithNSRange:NSMakeRange(toIndex, fromIndex - toIndex)];
  }
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

- (void)setMarkedRect:(CGRect)markedRect {
  _markedRect = markedRect;
  // Invalidate the cache.
  _cachedFirstRect = kInvalidFirstRect;
}

// This method expects a 4x4 perspective matrix
// stored in a NSArray in column-major order.
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

  // Invalidate the cache.
  _cachedFirstRect = kInvalidFirstRect;
}

// The following methods are required to support force-touch cursor positioning
// and to position the
// candidates view for multi-stage input methods (e.g., Japanese) when using a
// physical keyboard.

- (CGRect)firstRectForRange:(UITextRange*)range {
  NSAssert([range.start isKindOfClass:[FlutterTextPosition class]],
           @"Expected a FlutterTextPosition for range.start (got %@).", [range.start class]);
  NSAssert([range.end isKindOfClass:[FlutterTextPosition class]],
           @"Expected a FlutterTextPosition for range.end (got %@).", [range.end class]);

  NSUInteger start = ((FlutterTextPosition*)range.start).index;
  NSUInteger end = ((FlutterTextPosition*)range.end).index;
  if (_markedTextRange != nil) {
    // The candidates view can't be shown if _editableTransform is not affine,
    // or markedRect is invalid.
    if (CGRectEqualToRect(kInvalidFirstRect, _markedRect) ||
        !CATransform3DIsAffine(_editableTransform)) {
      return kInvalidFirstRect;
    }

    if (CGRectEqualToRect(_cachedFirstRect, kInvalidFirstRect)) {
      // If the width returned is too small, that means the framework sent us
      // the caret rect instead of the marked text rect. Expand it to 0.1 so
      // the IME candidates view show up.
      double nonZeroWidth = MAX(_markedRect.size.width, 0.1);
      CGRect rect = _markedRect;
      rect.size = CGSizeMake(nonZeroWidth, rect.size.height);
      _cachedFirstRect =
          CGRectApplyAffineTransform(rect, CATransform3DGetAffineTransform(_editableTransform));
    }

    return _cachedFirstRect;
  }

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
@property(nonatomic, strong) FlutterTextInputView* reusableInputView;

// The current password-autofillable input fields that have yet to be saved.
@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, FlutterTextInputView*>* autofillContext;
@property(nonatomic, assign) FlutterTextInputView* activeView;
@end

@implementation FlutterTextInputPlugin

@synthesize textInputDelegate = _textInputDelegate;

- (instancetype)init {
  self = [super init];

  if (self) {
    _reusableInputView = [[FlutterTextInputView alloc] init];
    _reusableInputView.secureTextEntry = NO;
    _autofillContext = [[NSMutableDictionary alloc] init];
    _activeView = _reusableInputView;
  }

  return self;
}

- (void)dealloc {
  [self hideTextInput];
  [_reusableInputView release];
  [_autofillContext release];

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
  } else if ([method isEqualToString:@"TextInput.setEditableSizeAndTransform"]) {
    [self setEditableSizeAndTransform:args];
    result(nil);
  } else if ([method isEqualToString:@"TextInput.setMarkedTextRect"]) {
    [self updateMarkedRect:args];
    result(nil);
  } else if ([method isEqualToString:@"TextInput.finishAutofillContext"]) {
    [self triggerAutofillSave:[args boolValue]];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)setEditableSizeAndTransform:(NSDictionary*)dictionary {
  [_activeView setEditableTransform:dictionary[@"transform"]];
}

- (void)updateMarkedRect:(NSDictionary*)dictionary {
  NSAssert(dictionary[@"x"] != nil && dictionary[@"y"] != nil && dictionary[@"width"] != nil &&
               dictionary[@"height"] != nil,
           @"Expected a dictionary representing a CGRect, got %@", dictionary);
  CGRect rect = CGRectMake([dictionary[@"x"] doubleValue], [dictionary[@"y"] doubleValue],
                           [dictionary[@"width"] doubleValue], [dictionary[@"height"] doubleValue]);
  _activeView.markedRect = rect.size.width < 0 && rect.size.height < 0 ? kInvalidFirstRect : rect;
}

- (void)showTextInput {
  _activeView.textInputDelegate = _textInputDelegate;
  [self addToInputParentViewIfNeeded:_activeView];
  [_activeView becomeFirstResponder];
}

- (void)hideTextInput {
  [_activeView resignFirstResponder];
}

- (void)triggerAutofillSave:(BOOL)saveEntries {
  [self hideTextInput];

  if (saveEntries) {
    // Make all the input fields in the autofill context visible,
    // then remove them to trigger autofill save.
    [self cleanUpViewHierarchy:YES clearText:YES];
    [_autofillContext removeAllObjects];
    [self changeInputViewsAutofillVisibility:YES];
  } else {
    [_autofillContext removeAllObjects];
  }

  [self cleanUpViewHierarchy:YES clearText:!saveEntries];
  [self addToInputParentViewIfNeeded:_activeView];
}

- (void)setTextInputClient:(int)client withConfiguration:(NSDictionary*)configuration {
  [self resetAllClientIds];
  // Hide all input views from autofill, only make those in the new configuration visible
  // to autofill.
  [self changeInputViewsAutofillVisibility:NO];
  switch (autofillTypeOf(configuration)) {
    case FlutterAutofillTypeNone:
      _activeView = [self updateAndShowReusableInputView:configuration];
      break;
    case FlutterAutofillTypeRegular:
      // If the group does not involve password autofill, only install the
      // input view that's being focused.
      _activeView = [self updateAndShowAutofillViews:nil
                                        focusedField:configuration
                                   isPasswordRelated:NO];
      break;
    case FlutterAutofillTypePassword:
      _activeView = [self updateAndShowAutofillViews:configuration[kAssociatedAutofillFields]
                                        focusedField:configuration
                                   isPasswordRelated:YES];
      break;
  }

  [_activeView setTextInputClient:client];
  [_activeView reloadInputViews];

  // Clean up views that no longer need to be in the view hierarchy, according to
  // the current autofill context. The "garbage" input views are already made
  // invisible to autofill and they can't `becomeFirstResponder`, we only remove
  // them to free up resources and reduce the number of input views in the view
  // hierarchy.
  //
  // This is scheduled on the runloop and delayed by 0.1s so we don't remove the
  // text fields immediately (which seems to make the keyboard flicker).
  // See: https://github.com/flutter/flutter/issues/64628.
  [self performSelector:@selector(collectGarbageInputViews) withObject:nil afterDelay:0.1];
}

// Updates and shows an input field that is not password related and has no autofill
// hints. This method re-configures and reuses an existing instance of input field
// instead of creating a new one.
// Also updates the current autofill context.
- (FlutterTextInputView*)updateAndShowReusableInputView:(NSDictionary*)configuration {
  // It's possible that the configuration of this non-autofillable input view has
  // an autofill configuration without hints. If it does, remove it from the context.
  NSString* autofillId = autofillIdFromDictionary(configuration);
  if (autofillId) {
    [_autofillContext removeObjectForKey:autofillId];
  }

  [_reusableInputView configureWithDictionary:configuration];
  [self addToInputParentViewIfNeeded:_reusableInputView];
  _reusableInputView.textInputDelegate = _textInputDelegate;

  for (NSDictionary* field in configuration[kAssociatedAutofillFields]) {
    NSString* autofillId = autofillIdFromDictionary(field);
    if (autofillId && autofillTypeOf(field) == FlutterAutofillTypeNone) {
      [_autofillContext removeObjectForKey:autofillId];
    }
  }
  return _reusableInputView;
}

- (FlutterTextInputView*)updateAndShowAutofillViews:(NSArray*)fields
                                       focusedField:(NSDictionary*)focusedField
                                  isPasswordRelated:(BOOL)isPassword {
  FlutterTextInputView* focused = nil;
  NSString* focusedId = autofillIdFromDictionary(focusedField);
  NSAssert(focusedId, @"autofillId must not be null for the focused field: %@", focusedField);

  if (!fields) {
    // DO NOT push the current autofillable input fields to the context even
    // if it's password-related, because it is not in an autofill group.
    focused = [self getOrCreateAutofillableView:focusedField isPasswordAutofill:isPassword];
    [_autofillContext removeObjectForKey:focusedId];
  }

  for (NSDictionary* field in fields) {
    NSString* autofillId = autofillIdFromDictionary(field);
    NSAssert(autofillId, @"autofillId must not be null for field: %@", field);

    BOOL hasHints = autofillTypeOf(field) != FlutterAutofillTypeNone;
    BOOL isFocused = [focusedId isEqualToString:autofillId];

    if (isFocused) {
      focused = [self getOrCreateAutofillableView:field isPasswordAutofill:isPassword];
    }

    if (hasHints) {
      // Push the current input field to the context if it has hints.
      _autofillContext[autofillId] = isFocused ? focused
                                               : [self getOrCreateAutofillableView:field
                                                                isPasswordAutofill:isPassword];
    } else {
      // Mark for deletion;
      [_autofillContext removeObjectForKey:autofillId];
    }
  }

  NSAssert(focused, @"The current focused input view must not be nil.");
  return focused;
}

// Returns a new non-reusable input view (and put it into the view hierarchy), or get the
// view from the current autofill context, if an input view with the same autofill id
// already exists in the context.
// This is generally used for input fields that are autofillable (UIKit tracks these veiws
// for autofill purposes so they should not be reused for a different type of views).
- (FlutterTextInputView*)getOrCreateAutofillableView:(NSDictionary*)field
                                  isPasswordAutofill:(BOOL)needsPasswordAutofill {
  NSString* autofillId = autofillIdFromDictionary(field);
  FlutterTextInputView* inputView = _autofillContext[autofillId];
  if (!inputView) {
    inputView =
        needsPasswordAutofill ? [FlutterSecureTextInputView alloc] : [FlutterTextInputView alloc];
    inputView = [[inputView init] autorelease];
    [self addToInputParentViewIfNeeded:inputView];
  }

  inputView.textInputDelegate = _textInputDelegate;
  [inputView configureWithDictionary:field];
  return inputView;
}

// The UIView to add FlutterTextInputViews to.
- (UIView*)textInputParentView {
  UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
  NSAssert(keyWindow != nullptr,
           @"The application must have a key window since the keyboard client "
           @"must be part of the responder chain to function");
  return keyWindow;
}

// Removes every installed input field, unless it's in the current autofill
// context. May remove the active view too if includeActiveView is YES.
// When clearText is YES, the text on the input fields will be set to empty before
// they are removed from the view hierarchy, to avoid triggering autofill save.
- (void)cleanUpViewHierarchy:(BOOL)includeActiveView clearText:(BOOL)clearText {
  for (UIView* view in self.textInputParentView.subviews) {
    if ([view isKindOfClass:[FlutterTextInputView class]] &&
        (includeActiveView || view != _activeView)) {
      FlutterTextInputView* inputView = (FlutterTextInputView*)view;
      if (_autofillContext[inputView.autofillId] != view) {
        if (clearText) {
          [inputView replaceRangeLocal:NSMakeRange(0, inputView.text.length) withText:@""];
        }
        [view removeFromSuperview];
      }
    }
  }
}

- (void)collectGarbageInputViews {
  [self cleanUpViewHierarchy:NO clearText:YES];
}

// Changes the visibility of every FlutterTextInputView currently in the
// view hierarchy.
- (void)changeInputViewsAutofillVisibility:(BOOL)newVisibility {
  for (UIView* view in self.textInputParentView.subviews) {
    if ([view isKindOfClass:[FlutterTextInputView class]]) {
      FlutterTextInputView* inputView = (FlutterTextInputView*)view;
      inputView.isVisibleToAutofill = newVisibility;
    }
  }
}

// Resets the client id of every FlutterTextInputView in the view hierarchy
// to 0. Called when a new text input connection will be established.
- (void)resetAllClientIds {
  for (UIView* view in self.textInputParentView.subviews) {
    if ([view isKindOfClass:[FlutterTextInputView class]]) {
      FlutterTextInputView* inputView = (FlutterTextInputView*)view;
      [inputView setTextInputClient:0];
    }
  }
}

- (void)addToInputParentViewIfNeeded:(FlutterTextInputView*)inputView {
  UIView* parentView = self.textInputParentView;
  if (inputView.superview != parentView) {
    [parentView addSubview:inputView];
  }
}

- (void)setTextInputEditingState:(NSDictionary*)state {
  [_activeView setTextInputState:state];
}

- (void)clearTextInputClient {
  [_activeView setTextInputClient:0];
}

@end

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/darwin/string_range_sanitization.h"

static const char _kTextAffinityDownstream[] = "TextAffinity.downstream";
static const char _kTextAffinityUpstream[] = "TextAffinity.upstream";
// A delay before enabling the accessibility of FlutterTextInputView after
// it is activated.
static constexpr double kUITextInputAccessibilityEnablingDelaySeconds = 0.5;

// The "canonical" invalid CGRect, similar to CGRectNull, used to
// indicate a CGRect involved in firstRectForRange calculation is
// invalid. The specific value is chosen so that if firstRectForRange
// returns kInvalidFirstRect, iOS will not show the IME candidates view.
const CGRect kInvalidFirstRect = {{-1, -1}, {9999, 9999}};

// The `bounds` value a FlutterTextInputView returns when the floating cursor
// is activated in that view.
//
// DO NOT use extremely large values (such as CGFloat_MAX) in this rect, for that
// will significantly reduce the precision of the floating cursor's coordinates.
//
// It is recommended for this CGRect to be roughly centered at caretRectForPosition
// (which currently always return CGRectZero), so the initial floating cursor will
// be placed at (0, 0).
// See the comments in beginFloatingCursorAtPoint and caretRectForPosition.
const CGRect kSpacePanBounds = {{-2500, -2500}, {5000, 5000}};

#pragma mark - TextInput channel method names.
// See https://api.flutter.dev/flutter/services/SystemChannels/textInput-constant.html
static NSString* const kShowMethod = @"TextInput.show";
static NSString* const kHideMethod = @"TextInput.hide";
static NSString* const kSetClientMethod = @"TextInput.setClient";
static NSString* const kSetEditingStateMethod = @"TextInput.setEditingState";
static NSString* const kClearClientMethod = @"TextInput.clearClient";
static NSString* const kSetEditableSizeAndTransformMethod =
    @"TextInput.setEditableSizeAndTransform";
static NSString* const kSetMarkedTextRectMethod = @"TextInput.setMarkedTextRect";
static NSString* const kFinishAutofillContextMethod = @"TextInput.finishAutofillContext";

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

// "TextInputType.none" is a made-up input type that's typically
// used when there's an in-app virtual keyboard. If
// "TextInputType.none" is specified, disable the system
// keyboard.
static BOOL shouldShowSystemKeyboard(NSDictionary* type) {
  NSString* inputType = type[@"name"];
  return ![inputType isEqualToString:@"TextInputType.none"];
}
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

#pragma mark - FlutterTokenizer

@interface FlutterTokenizer ()

@property(nonatomic, assign) FlutterTextInputView* textInputView;

@end

@implementation FlutterTokenizer

- (instancetype)initWithTextInput:(UIResponder<UITextInput>*)textInput {
  NSAssert([textInput isKindOfClass:[FlutterTextInputView class]],
           @"The FlutterTokenizer can only be used in a FlutterTextInputView");
  self = [super initWithTextInput:textInput];
  if (self) {
    _textInputView = (FlutterTextInputView*)textInput;
  }
  return self;
}

- (UITextRange*)rangeEnclosingPosition:(UITextPosition*)position
                       withGranularity:(UITextGranularity)granularity
                           inDirection:(UITextDirection)direction {
  UITextRange* result;
  switch (granularity) {
    case UITextGranularityLine:
      // The default UITextInputStringTokenizer does not handle line granularity
      // correctly. We need to implement our own line tokenizer.
      result = [self lineEnclosingPosition:position];
      break;
    case UITextGranularityCharacter:
    case UITextGranularityWord:
    case UITextGranularitySentence:
    case UITextGranularityParagraph:
    case UITextGranularityDocument:
      // The UITextInputStringTokenizer can handle all these cases correctly.
      result = [super rangeEnclosingPosition:position
                             withGranularity:granularity
                                 inDirection:direction];
      break;
  }
  return result;
}

- (UITextRange*)lineEnclosingPosition:(UITextPosition*)position {
  // Gets the first line break position after the input position.
  NSString* textAfter = [_textInputView
      textInRange:[_textInputView textRangeFromPosition:position
                                             toPosition:[_textInputView endOfDocument]]];
  NSArray<NSString*>* linesAfter = [textAfter componentsSeparatedByString:@"\n"];
  NSInteger offSetToLineBreak = [linesAfter firstObject].length;
  UITextPosition* lineBreakAfter = [_textInputView positionFromPosition:position
                                                                 offset:offSetToLineBreak];
  // Gets the first line break position before the input position.
  NSString* textBefore = [_textInputView
      textInRange:[_textInputView textRangeFromPosition:[_textInputView beginningOfDocument]
                                             toPosition:position]];
  NSArray<NSString*>* linesBefore = [textBefore componentsSeparatedByString:@"\n"];
  NSInteger offSetFromLineBreak = [linesBefore lastObject].length;
  UITextPosition* lineBreakBefore = [_textInputView positionFromPosition:position
                                                                  offset:-offSetFromLineBreak];

  return [_textInputView textRangeFromPosition:lineBreakBefore toPosition:lineBreakAfter];
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
@property(nonatomic, assign) BOOL accessibilityEnabled;

- (void)setEditableTransform:(NSArray*)matrix;
@end

@implementation FlutterTextInputView {
  int _textInputClient;
  const char* _selectionAffinity;
  FlutterTextRange* _selectedTextRange;
  UIInputViewController* _inputViewController;
  CGRect _cachedFirstRect;
  // Whether to show the system keyboard when this view
  // becomes the first responder. Typically set to false
  // when the app shows its own in-flutter keyboard.
  bool _isSystemKeyboardEnabled;
  bool _isFloatingCursorActive;
  // The view has reached end of life, and is no longer
  // allowed to access its textInputDelegate.
  BOOL _decommissioned;
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
    _isFloatingCursorActive = false;

    // UITextInputTraits
    _autocapitalizationType = UITextAutocapitalizationTypeSentences;
    _autocorrectionType = UITextAutocorrectionTypeDefault;
    _spellCheckingType = UITextSpellCheckingTypeDefault;
    _enablesReturnKeyAutomatically = NO;
    _keyboardAppearance = UIKeyboardAppearanceDefault;
    _keyboardType = UIKeyboardTypeDefault;
    _returnKeyType = UIReturnKeyDone;
    _secureTextEntry = NO;
    _accessibilityEnabled = NO;
    _decommissioned = NO;
    if (@available(iOS 11.0, *)) {
      _smartQuotesType = UITextSmartQuotesTypeYes;
      _smartDashesType = UITextSmartDashesTypeYes;
    }

    // This makes sure UITextSelectionView.interactionAssistant is not nil so
    // UITextSelectionView has access to this view (and its bounds). Otherwise
    // floating cursor breaks: https://github.com/flutter/flutter/issues/70267.
    if (@available(iOS 13.0, *)) {
      UITextInteraction* interaction =
          [UITextInteraction textInteractionForMode:UITextInteractionModeEditable];
      interaction.textInput = self;
      [self addInteraction:interaction];
    }
  }

  return self;
}

- (void)configureWithDictionary:(NSDictionary*)configuration {
  NSAssert(!_decommissioned, @"Attempt to reuse a decommissioned view, for %@", configuration);
  NSDictionary* inputType = configuration[kKeyboardType];
  NSString* keyboardAppearance = configuration[kKeyboardAppearance];
  NSDictionary* autofill = configuration[kAutofillProperties];

  self.secureTextEntry = [configuration[kSecureTextEntry] boolValue];

  _isSystemKeyboardEnabled = shouldShowSystemKeyboard(inputType);
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

- (UIInputViewController*)inputViewController {
  if (_isSystemKeyboardEnabled) {
    return nil;
  }

  if (!_inputViewController) {
    _inputViewController = [UIInputViewController new];
  }
  return _inputViewController;
}

- (id<FlutterTextInputDelegate>)textInputDelegate {
  return _decommissioned ? nil : _textInputDelegate;
}

// Declares that the view has reached end of life, and
// is no longer allowed to access its textInputDelegate.
//
// UIKit may retain this view (even after it's been removed
// from the view hierarchy) so that it may outlive the plugin/engine,
// in which case _textInputDelegate will become a dangling pointer.

// The text input plugin needs to call decommission when it should
// not have access to its FlutterTextInputDelegate any more.
- (void)decommission {
  _decommissioned = YES;
}

- (void)dealloc {
  [_text release];
  [_markedText release];
  [_markedTextRange release];
  [_selectedTextRange release];
  [_tokenizer release];
  [_autofillId release];
  [_inputViewController release];
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

// The documentation for presses* handlers (implemented below) is entirely
// unclear about how to handle the case where some, but not all, of the presses
// are handled here. I've elected to call super separately for each of the
// presses that aren't handled, but it's not clear if this is correct. It may be
// that iOS intends for us to either handle all or none of the presses, and pass
// the original set to super. I have not yet seen multiple presses in the set in
// the wild, however, so I suspect that the API is built for a tvOS remote or
// something, and perhaps only one ever appears in the set on iOS from a
// keyboard.

// If you substantially change these presses overrides, consider also changing
// the similar ones in FlutterViewController. They need to be overridden in both
// places to capture keys both inside and outside of a text field, but have
// slightly different implmentations.

- (void)pressesBegan:(NSSet<UIPress*>*)presses
           withEvent:(UIPressesEvent*)event API_AVAILABLE(ios(9.0)) {
  if (@available(iOS 13.4, *)) {
    for (UIPress* press in presses) {
      [_textInputDelegate handlePressEvent:[[FlutterUIPressProxy alloc] initWithPress:press
                                                                            withEvent:event]
                                nextAction:^() {
                                  [super pressesBegan:[NSSet setWithObject:press] withEvent:event];
                                }];
    }
  } else {
    [super pressesBegan:presses withEvent:event];
  }
}

- (void)pressesChanged:(NSSet<UIPress*>*)presses
             withEvent:(UIPressesEvent*)event API_AVAILABLE(ios(9.0)) {
  if (@available(iOS 13.4, *)) {
    for (UIPress* press in presses) {
      [_textInputDelegate
          handlePressEvent:[[FlutterUIPressProxy alloc] initWithPress:press withEvent:event]
                nextAction:^() {
                  [super pressesChanged:[NSSet setWithObject:press] withEvent:event];
                }];
    }
  } else {
    [super pressesChanged:presses withEvent:event];
  }
}

- (void)pressesEnded:(NSSet<UIPress*>*)presses
           withEvent:(UIPressesEvent*)event API_AVAILABLE(ios(9.0)) {
  if (@available(iOS 13.4, *)) {
    for (UIPress* press in presses) {
      [_textInputDelegate handlePressEvent:[[FlutterUIPressProxy alloc] initWithPress:press
                                                                            withEvent:event]
                                nextAction:^() {
                                  [super pressesEnded:[NSSet setWithObject:press] withEvent:event];
                                }];
    }
  } else {
    [super pressesEnded:presses withEvent:event];
  }
}

- (void)pressesCancelled:(NSSet<UIPress*>*)presses
               withEvent:(UIPressesEvent*)event API_AVAILABLE(ios(9.0)) {
  if (@available(iOS 13.4, *)) {
    for (UIPress* press in presses) {
      [_textInputDelegate
          handlePressEvent:[[FlutterUIPressProxy alloc] initWithPress:press withEvent:event]
                nextAction:^() {
                  [super pressesCancelled:[NSSet setWithObject:press] withEvent:event];
                }];
    }
  } else {
    [super pressesCancelled:presses withEvent:event];
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
    _tokenizer = [[FlutterTokenizer alloc] initWithTextInput:self];
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
  // Sanitize the range to prevent going out of bounds.
  int location = MIN(textRange.location, self.text.length);
  int length = MIN(self.text.length - location, textRange.length);
  NSRange safeRange = NSMakeRange(location, length);
  return [self.text substringWithRange:safeRange];
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
    [self.textInputDelegate performAction:FlutterTextInputActionNewline
                               withClient:_textInputClient];
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

    [self.textInputDelegate performAction:action withClient:_textInputClient];
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

  [self.textInputDelegate showAutocorrectionPromptRectForStart:start
                                                           end:end
                                                    withClient:_textInputClient];
  // TODO(cbracken) Implement.
  return CGRectZero;
}

- (CGRect)caretRectForPosition:(UITextPosition*)position {
  // TODO(cbracken) Implement.

  // As of iOS 14.4, this call is used by iOS's
  // _UIKeyboardTextSelectionController to determine the position
  // of the floating cursor when the user force touches the space
  // bar to initiate floating cursor.
  //
  // It is recommended to return a value that's roughly the
  // center of kSpacePanBounds to make sure the floating cursor
  // has ample space in all directions and does not hit kSpacePanBounds.
  // See the comments in beginFloatingCursorAtPoint.
  return CGRectZero;
}

- (CGRect)bounds {
  return _isFloatingCursorActive ? kSpacePanBounds : super.bounds;
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
  // For "beginFloatingCursorAtPoint" and "updateFloatingCursorAtPoint", "point" is roughly:
  //
  // CGPoint(
  //   width >= 0 ? point.x.clamp(boundingBox.left, boundingBox.right) : point.x,
  //   height >= 0 ? point.y.clamp(boundingBox.top, boundingBox.bottom) : point.y,
  // )
  //   where
  //     point = keyboardPanGestureRecognizer.translationInView(textInputView) +
  //     caretRectForPosition boundingBox = self.convertRect(bounds, fromView:textInputView) bounds
  //     = self._selectionClipRect ?? self.bounds
  //
  // It's tricky to provide accurate "bounds" and "caretRectForPosition" so it's preferred to bypass
  // the clamping and implement the same clamping logic in the framework where we have easy access
  // to the bounding box of the input field and the caret location.
  //
  // The current implementation returns kSpacePanBounds for "bounds" when "_isFloatingCursorActive"
  // is true. kSpacePanBounds centers "caretRectForPosition" so the floating cursor has enough
  // clearance in all directions to move around.
  //
  // It seems impossible to use a negative "width" or "height", as the "convertRect"
  // call always turns a CGRect's negative dimensions into non-negative values, e.g.,
  // (1, 2, -3, -4) would become (-2, -2, 3, 4).
  NSAssert(!_isFloatingCursorActive, @"Another floating cursor is currently active.");
  _isFloatingCursorActive = true;
  [self.textInputDelegate updateFloatingCursor:FlutterFloatingCursorDragStateStart
                                    withClient:_textInputClient
                                  withPosition:@{@"X" : @(point.x), @"Y" : @(point.y)}];
}

- (void)updateFloatingCursorAtPoint:(CGPoint)point {
  NSAssert(_isFloatingCursorActive,
           @"updateFloatingCursorAtPoint is called without an active floating cursor.");
  [self.textInputDelegate updateFloatingCursor:FlutterFloatingCursorDragStateUpdate
                                    withClient:_textInputClient
                                  withPosition:@{@"X" : @(point.x), @"Y" : @(point.y)}];
}

- (void)endFloatingCursor {
  NSAssert(_isFloatingCursorActive,
           @"endFloatingCursor is called without an active floating cursor.");
  _isFloatingCursorActive = false;
  [self.textInputDelegate updateFloatingCursor:FlutterFloatingCursorDragStateEnd
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
    [self.textInputDelegate updateEditingClient:_textInputClient
                                      withState:state
                                        withTag:_autofillId];
  } else {
    [self.textInputDelegate updateEditingClient:_textInputClient withState:state];
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

- (void)postAccessibilityNotification:(UIAccessibilityNotifications)notification target:(id)target {
  UIAccessibilityPostNotification(notification, target);
}

- (void)accessibilityElementDidBecomeFocused {
  if ([self accessibilityElementIsFocused]) {
    // For most of the cases, this flutter text input view should never
    // receive the focus. If we do receive the focus, we make the best effort
    // to send the focus back to the real text field.
    FML_DCHECK(_backingTextInputAccessibilityObject);
    [self postAccessibilityNotification:UIAccessibilityScreenChangedNotification
                                 target:_backingTextInputAccessibilityObject];
  }
}

- (BOOL)accessibilityElementsHidden {
  return !_accessibilityEnabled;
}

@end

/**
 * Hides `FlutterTextInputView` from iOS accessibility system so it
 * does not show up twice, once where it is in the `UIView` hierarchy,
 * and a second time as part of the `SemanticsObject` hierarchy.
 *
 * This prevents the `FlutterTextInputView` from receiving the focus
 * due to swiping gesture.
 *
 * There are other cases the `FlutterTextInputView` may receive
 * focus. One example is during screen changes, the accessibility
 * tree will undergo a dramatic structural update. The Voiceover may
 * decide to focus the `FlutterTextInputView` that is not involved
 * in the structural update instead. If that happens, the
 * `FlutterTextInputView` will make a best effort to direct the
 * focus back to the `SemanticsObject`.
 */
@interface FlutterTextInputViewAccessibilityHider : UIView {
}

@end

@implementation FlutterTextInputViewAccessibilityHider {
}

- (BOOL)accessibilityElementsHidden {
  return YES;
}

@end

@interface FlutterTextInputPlugin ()
- (void)enableActiveViewAccessibility;
@end

@interface FlutterTimerProxy : NSObject
@property(nonatomic, assign) FlutterTextInputPlugin* target;
@end

@implementation FlutterTimerProxy

+ (instancetype)proxyWithTarget:(FlutterTextInputPlugin*)target {
  FlutterTimerProxy* proxy = [[self new] autorelease];
  if (proxy) {
    proxy.target = target;
  }
  return proxy;
}

- (void)enableActiveViewAccessibility {
  [self.target enableActiveViewAccessibility];
}

@end

@interface FlutterTextInputPlugin ()
// The current password-autofillable input fields that have yet to be saved.
@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, FlutterTextInputView*>* autofillContext;
@property(nonatomic, strong) FlutterTextInputView* activeView;
@property(nonatomic, strong) FlutterTextInputViewAccessibilityHider* inputHider;
@end

@implementation FlutterTextInputPlugin {
  NSTimer* _enableFlutterTextInputViewAccessibilityTimer;
}

@synthesize textInputDelegate = _textInputDelegate;

- (instancetype)init {
  self = [super init];

  if (self) {
    _autofillContext = [[NSMutableDictionary alloc] init];
    _inputHider = [[FlutterTextInputViewAccessibilityHider alloc] init];
    // Initialize activeView with a dummy view to keep tests
    // passing. This dummy view needs to be replace once the
    // framework initializes an input connection, and thus
    // should never have access to the textInputDelegate.
    _activeView = [[FlutterTextInputView alloc] init];
    [_activeView decommission];
  }

  return self;
}

- (void)dealloc {
  [self hideTextInput];
  _activeView.textInputDelegate = nil;
  [_activeView release];
  [_inputHider release];
  for (FlutterTextInputView* autofillView in _autofillContext.allValues) {
    autofillView.textInputDelegate = nil;
  }
  [_autofillContext release];
  [super dealloc];
}

- (void)removeEnableFlutterTextInputViewAccessibilityTimer {
  if (_enableFlutterTextInputViewAccessibilityTimer) {
    [_enableFlutterTextInputViewAccessibilityTimer invalidate];
    [_enableFlutterTextInputViewAccessibilityTimer release];
    _enableFlutterTextInputViewAccessibilityTimer = nil;
  }
}

- (UIView<UITextInput>*)textInputView {
  return _activeView;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* method = call.method;
  id args = call.arguments;
  if ([method isEqualToString:kShowMethod]) {
    [self showTextInput];
    result(nil);
  } else if ([method isEqualToString:kHideMethod]) {
    [self hideTextInput];
    result(nil);
  } else if ([method isEqualToString:kSetClientMethod]) {
    [self setTextInputClient:[args[0] intValue] withConfiguration:args[1]];
    result(nil);
  } else if ([method isEqualToString:kSetEditingStateMethod]) {
    [self setTextInputEditingState:args];
    result(nil);
  } else if ([method isEqualToString:kClearClientMethod]) {
    [self clearTextInputClient];
    result(nil);
  } else if ([method isEqualToString:kSetEditableSizeAndTransformMethod]) {
    [self setEditableSizeAndTransform:args];
    result(nil);
  } else if ([method isEqualToString:kSetMarkedTextRectMethod]) {
    [self updateMarkedRect:args];
    result(nil);
  } else if ([method isEqualToString:kFinishAutofillContextMethod]) {
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
  // Adds a delay to prevent the text view from receiving accessibility
  // focus in case it is activated during semantics updates.
  //
  // One common case is when the app navigates to a page with an auto
  // focused text field. The text field will activate the FlutterTextInputView
  // with a semantics update sent to the engine. The voiceover will focus
  // the newly attached active view while performing accessibility update.
  // This results in accessibility focus stuck at the FlutterTextInputView.
  if (!_enableFlutterTextInputViewAccessibilityTimer) {
    _enableFlutterTextInputViewAccessibilityTimer =
        [[NSTimer scheduledTimerWithTimeInterval:kUITextInputAccessibilityEnablingDelaySeconds
                                          target:[FlutterTimerProxy proxyWithTarget:self]
                                        selector:@selector(enableActiveViewAccessibility)
                                        userInfo:nil
                                         repeats:NO] retain];
  }
  [_activeView becomeFirstResponder];
}

- (void)enableActiveViewAccessibility {
  if (_activeView.isFirstResponder) {
    _activeView.accessibilityEnabled = YES;
  }
  [self removeEnableFlutterTextInputViewAccessibilityTimer];
}

- (void)hideTextInput {
  [self removeEnableFlutterTextInputViewAccessibilityTimer];
  _activeView.accessibilityEnabled = NO;
  [_activeView resignFirstResponder];
  [_activeView removeFromSuperview];
  [_inputHider removeFromSuperview];
}

- (void)triggerAutofillSave:(BOOL)saveEntries {
  [_activeView resignFirstResponder];

  if (saveEntries) {
    // Make all the input fields in the autofill context visible,
    // then remove them to trigger autofill save.
    [self cleanUpViewHierarchy:YES clearText:YES delayRemoval:NO];
    [_autofillContext removeAllObjects];
    [self changeInputViewsAutofillVisibility:YES];
  } else {
    [_autofillContext removeAllObjects];
  }

  [self cleanUpViewHierarchy:YES clearText:!saveEntries delayRemoval:NO];
  [self addToInputParentViewIfNeeded:_activeView];
}

- (void)setTextInputClient:(int)client withConfiguration:(NSDictionary*)configuration {
  [self resetAllClientIds];
  // Hide all input views from autofill, only make those in the new configuration visible
  // to autofill.
  [self changeInputViewsAutofillVisibility:NO];

  // Update the current active view.
  switch (autofillTypeOf(configuration)) {
    case FlutterAutofillTypeNone:
      self.activeView = [self createInputViewWith:configuration];
      break;
    case FlutterAutofillTypeRegular:
      // If the group does not involve password autofill, only install the
      // input view that's being focused.
      self.activeView = [self updateAndShowAutofillViews:nil
                                            focusedField:configuration
                                       isPasswordRelated:NO];
      break;
    case FlutterAutofillTypePassword:
      self.activeView = [self updateAndShowAutofillViews:configuration[kAssociatedAutofillFields]
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
  // The garbage views are decommissioned immediately, but the removeFromSuperview
  // call is scheduled on the runloop and delayed by 0.1s so we don't remove the
  // text fields immediately (which seems to make the keyboard flicker).
  // See: https://github.com/flutter/flutter/issues/64628.
  [self cleanUpViewHierarchy:NO clearText:YES delayRemoval:YES];
}

// Creates and shows an input field that is not password related and has no autofill
// hints. This method returns a new FlutterTextInputView instance when called, since
// UIKit uses the identity of `UITextInput` instances (or the identity of the input
// views) to decide whether the IME's internal states should be reset. See:
// https://github.com/flutter/flutter/issues/79031 .
- (FlutterTextInputView*)createInputViewWith:(NSDictionary*)configuration {
  // It's possible that the configuration of this non-autofillable input view has
  // an autofill configuration without hints. If it does, remove it from the context.
  NSString* autofillId = autofillIdFromDictionary(configuration);
  if (autofillId) {
    [_autofillContext removeObjectForKey:autofillId];
  }
  FlutterTextInputView* newView = [[FlutterTextInputView alloc] init];
  [newView configureWithDictionary:configuration];
  [self addToInputParentViewIfNeeded:newView];
  newView.textInputDelegate = _textInputDelegate;

  for (NSDictionary* field in configuration[kAssociatedAutofillFields]) {
    NSString* autofillId = autofillIdFromDictionary(field);
    if (autofillId && autofillTypeOf(field) == FlutterAutofillTypeNone) {
      [_autofillContext removeObjectForKey:autofillId];
    }
  }
  return [newView autorelease];
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
- (UIView*)keyWindow {
  UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
  NSAssert(keyWindow != nullptr,
           @"The application must have a key window since the keyboard client "
           @"must be part of the responder chain to function");
  return keyWindow;
}

// The UIView to add FlutterTextInputViews to.
- (NSArray<UIView*>*)textInputViews {
  return _inputHider.subviews;
}

// Decommissions (See the "decommission" method on FlutterTextInputView) and removes
// every installed input field, unless it's in the current autofill context.
//
// The active view will be decommissioned and removed from its superview too, if
// includeActiveView is YES.
// When clearText is YES, the text on the input fields will be set to empty before
// they are removed from the view hierarchy, to avoid triggering autofill save.
// If delayRemoval is true, removeFromSuperview will be scheduled on the runloop and
// will be delayed by 0.1s so we don't remove the text fields immediately (which seems
// to make the keyboard flicker).
// See: https://github.com/flutter/flutter/issues/64628.

- (void)cleanUpViewHierarchy:(BOOL)includeActiveView
                   clearText:(BOOL)clearText
                delayRemoval:(BOOL)delayRemoval {
  for (UIView* view in self.textInputViews) {
    if ([view isKindOfClass:[FlutterTextInputView class]] &&
        (includeActiveView || view != _activeView)) {
      FlutterTextInputView* inputView = (FlutterTextInputView*)view;
      if (_autofillContext[inputView.autofillId] != view) {
        if (clearText) {
          [inputView replaceRangeLocal:NSMakeRange(0, inputView.text.length) withText:@""];
        }
        [inputView decommission];
        if (delayRemoval) {
          [inputView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
        } else {
          [inputView removeFromSuperview];
        }
      }
    }
  }
}

// Changes the visibility of every FlutterTextInputView currently in the
// view hierarchy.
- (void)changeInputViewsAutofillVisibility:(BOOL)newVisibility {
  for (UIView* view in self.textInputViews) {
    if ([view isKindOfClass:[FlutterTextInputView class]]) {
      FlutterTextInputView* inputView = (FlutterTextInputView*)view;
      inputView.isVisibleToAutofill = newVisibility;
    }
  }
}

// Resets the client id of every FlutterTextInputView in the view hierarchy
// to 0.
// Called before establishing a new text input connection.
// For views in the current autofill context, they need to
// stay in the view hierachy but should not be allowed to
// send messages (other than autofill related ones) to the
// framework.
- (void)resetAllClientIds {
  for (UIView* view in self.textInputViews) {
    if ([view isKindOfClass:[FlutterTextInputView class]]) {
      FlutterTextInputView* inputView = (FlutterTextInputView*)view;
      [inputView setTextInputClient:0];
    }
  }
}

- (void)addToInputParentViewIfNeeded:(FlutterTextInputView*)inputView {
  if (![inputView isDescendantOfView:_inputHider]) {
    [_inputHider addSubview:inputView];
  }
  UIView* parentView = self.keyWindow;
  if (_inputHider.superview != parentView) {
    [parentView addSubview:_inputHider];
  }
}

- (void)setTextInputEditingState:(NSDictionary*)state {
  [_activeView setTextInputState:state];
}

- (void)clearTextInputClient {
  [_activeView setTextInputClient:0];
}

#pragma mark -
#pragma mark FlutterKeySecondaryResponder

/**
 * Handles key down events received from the view controller, responding YES if
 * the event was handled.
 */
- (BOOL)handlePress:(nonnull FlutterUIPressProxy*)press API_AVAILABLE(ios(13.4)) {
  return NO;
}
@end

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSpellCheckPlugin.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"

// Method Channel name to start spell check.
static NSString* const kInitiateSpellCheck = @"SpellCheck.initiateSpellCheck";

@interface FlutterSpellCheckPlugin ()

@property(nonatomic, retain) UITextChecker* textChecker;

@end

@implementation FlutterSpellCheckPlugin

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if (!_textChecker) {
    // UITextChecker is an expensive object to initiate, see:
    // https://github.com/flutter/flutter/issues/104454. Lazily initialate the UITextChecker object
    // until at first method channel call. We avoid using lazy getter for testing.
    _textChecker = [[UITextChecker alloc] init];
  }
  NSString* method = call.method;
  NSArray* args = call.arguments;
  if ([method isEqualToString:kInitiateSpellCheck]) {
    FML_DCHECK(args.count == 2);
    id language = args[0];
    id text = args[1];
    if (language == [NSNull null] || text == [NSNull null]) {
      // Bail if null arguments are passed from dart.
      result(nil);
      return;
    }

    NSArray<NSDictionary<NSString*, id>*>* spellCheckResult =
        [self findAllSpellCheckSuggestionsForText:text inLanguage:language];
    result(spellCheckResult);
  }
}

// Get all the misspelled words and suggestions in the entire String.
//
// The result will be formatted as an NSArray.
// Each item of the array is a dictionary representing a misspelled word and suggestions.
// The format looks like:
// {
//  startIndex: 0,
//  endIndex: 5,
//  suggestions: [hello, ...]
// }
//
// Returns nil if the language is invalid.
// Returns an empty array if no spell check suggestions.
- (NSArray<NSDictionary<NSString*, id>*>*)findAllSpellCheckSuggestionsForText:(NSString*)text
                                                                   inLanguage:(NSString*)language {
  // Transform Dart Locale format to iOS language format if necessary.
  if ([language containsString:@"-"]) {
    NSArray<NSString*>* languageCodes = [language componentsSeparatedByString:@"-"];
    FML_DCHECK(languageCodes.count == 2);
    NSString* lastCode = [[languageCodes lastObject] uppercaseString];
    language = [NSString stringWithFormat:@"%@_%@", [languageCodes firstObject], lastCode];
  }

  if (![UITextChecker.availableLanguages containsObject:language]) {
    return nil;
  }

  NSMutableArray<FlutterSpellCheckResult*>* allSpellSuggestions = [[NSMutableArray alloc] init];

  FlutterSpellCheckResult* nextSpellSuggestion;
  NSUInteger nextOffset = 0;
  do {
    nextSpellSuggestion = [self findSpellCheckSuggestionsForText:text
                                                      inLanguage:language
                                                  startingOffset:nextOffset];
    if (nextSpellSuggestion != nil) {
      [allSpellSuggestions addObject:nextSpellSuggestion];
      nextOffset =
          nextSpellSuggestion.misspelledRange.location + nextSpellSuggestion.misspelledRange.length;
    }
  } while (nextSpellSuggestion != nil && nextOffset < text.length);

  NSMutableArray* methodChannelResult = [[[NSMutableArray alloc] init] autorelease];

  for (FlutterSpellCheckResult* result in allSpellSuggestions) {
    [methodChannelResult addObject:[result toDictionary]];
  }

  [allSpellSuggestions release];
  return methodChannelResult;
}

// Get the misspelled word and suggestions.
//
// Returns nil if no spell check suggestions.
- (FlutterSpellCheckResult*)findSpellCheckSuggestionsForText:(NSString*)text
                                                  inLanguage:(NSString*)language
                                              startingOffset:(NSInteger)startingOffset {
  FML_DCHECK([UITextChecker.availableLanguages containsObject:language]);
  NSRange misspelledRange =
      [self.textChecker rangeOfMisspelledWordInString:text
                                                range:NSMakeRange(0, text.length)
                                           startingAt:startingOffset
                                                 wrap:NO
                                             language:language];
  if (misspelledRange.location == NSNotFound) {
    // No misspelled word found
    return nil;
  }

  // If no possible guesses, the API returns an empty array:
  // https://developer.apple.com/documentation/uikit/uitextchecker/1621037-guessesforwordrange?language=objc
  NSArray<NSString*>* suggestions = [self.textChecker guessesForWordRange:misspelledRange
                                                                 inString:text
                                                                 language:language];
  FlutterSpellCheckResult* result =
      [[[FlutterSpellCheckResult alloc] initWithMisspelledRange:misspelledRange
                                                    suggestions:suggestions] autorelease];
  return result;
}

- (UITextChecker*)textChecker {
  return _textChecker;
}

- (void)dealloc {
  [_textChecker release];
  [super dealloc];
}

@end

@implementation FlutterSpellCheckResult

- (instancetype)initWithMisspelledRange:(NSRange)range
                            suggestions:(NSArray<NSString*>*)suggestions {
  self = [super init];
  if (self) {
    _suggestions = [suggestions copy];
    _misspelledRange = range;
  }
  return self;
}

- (NSDictionary<NSString*, NSObject*>*)toDictionary {
  NSMutableDictionary* result = [[[NSMutableDictionary alloc] initWithCapacity:3] autorelease];
  result[@"startIndex"] = @(_misspelledRange.location);
  // The end index represents the next index after the last character of a misspelled word to match
  // the behavior of Dart's TextRange: https://api.flutter.dev/flutter/dart-ui/TextRange/end.html
  result[@"endIndex"] = @(_misspelledRange.location + _misspelledRange.length);
  result[@"suggestions"] = _suggestions;
  return result;
}

- (void)dealloc {
  [_suggestions release];
  [super dealloc];
}

@end

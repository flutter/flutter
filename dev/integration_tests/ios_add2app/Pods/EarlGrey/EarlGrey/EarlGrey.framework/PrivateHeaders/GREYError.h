//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

#import <EarlGrey/GREYDefines.h>

@class GREYError;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Creates a @c GREYError object with given @c domain, @c code, @c description
 *  The description is accessible by querying error's @c userInfo with
 *  @c NSLocalizedDescriptionKey.
 *
 *  @param domain      The error domain.
 *  @param code        The error code.
 *  @param description The error's localized description.
 *
 *  @return A @c GREYError object with the given input.
 */
#define GREYErrorMake(domain, code, description) \
I_GREYErrorMake((domain), \
                (code), \
                @{ NSLocalizedDescriptionKey : (description) }, \
                [NSString stringWithUTF8String:__FILE__], \
                __LINE__, \
                [NSString stringWithUTF8String:__PRETTY_FUNCTION__], \
                nil, \
                [NSThread callStackSymbols])

/**
 *  Creates a @c GREYError object with given @c domain, @c code, @c description
 *  and @c nestedError.
 *  The description is accessible by querying error's @c userInfo with
 *  @c NSLocalizedDescriptionKey. The @c nestedError is accessible by error's
 *  @c userInfo with @c NSUnderlyingErrorKey.
 *
 *  @param domain      The error domain.
 *  @param code        The error code.
 *  @param description The error's localized description.
 *  @param nestedError An error to be nested in current error.
 *
 *  @return A @c GREYError object with the given input.
 */
#define GREYNestedErrorMake(domain, code, description, nestedError) \
I_GREYErrorMake((domain), \
                (code), \
                @{ NSLocalizedDescriptionKey : (description), \
                   NSUnderlyingErrorKey : (nestedError) }, \
                [NSString stringWithUTF8String:__FILE__], \
                __LINE__, \
                [NSString stringWithUTF8String:__PRETTY_FUNCTION__], \
                nil, \
                [NSThread callStackSymbols])

/**
 *  If @c errorRef is not @c NULL, it is set to a @c GREYError object that is created with
 *  the given @c domain, @c code and @c description.
 *  The description is accessible by querying error's @c userInfo with @c NSLocalizedDescriptionKey.
 *  If @c errorRef is @c NULL, the error information is logged using NSLog.
 *
 *  @param[out] errorRef    A @c GREYError reference for retrieving the created
 *                          error object.
 *  @param      domain      The error domain.
 *  @param      code        The error code.
 *  @param      description The error's localized description.
 *
 */
#define GREYPopulateErrorOrLog(errorRef, domain, code, description) \
({ \
  GREYError *e = GREYErrorMake((domain), (code), (description)); \
  if(errorRef) { \
    *errorRef = e; \
  } else { \
    NSLog(@"%@", e); \
  } \
})

/**
 *  If @c errorRef is not @c NULL, it is set to a @c GREYError object that is created with
 *  the given @c domain, @c code, @c description and @c glossary.
 *  The description is accessible by querying error's @c userInfo with @c NSLocalizedDescriptionKey.
 *  If @c errorRef is @c NULL, the error information is logged using NSLog.
 *
 *  @param[out] errorRef    A @c GREYError reference for retrieving the created
 *                          error object.
 *  @param      domain      The error domain.
 *  @param      code        The error code.
 *  @param      description The error's localized description.
 *  @param      glossary    A glossary dictionary that is going to be populated with the error.
 *
 */
#define GREYPopulateErrorNotedOrLog(errorRef, domain, code, description, glossary) \
({ \
  GREYError *e = GREYErrorMake((domain), (code), (description)); \
  e.descriptionGlossary = (glossary); \
  if(errorRef) { \
    *errorRef = e; \
  } else { \
    NSLog(@"%@", e); \
  } \
})

/**
 *  If @c errorRef is not @c NULL, it is set to a @c GREYError object that is created
 *  with the given @c domain, @c code, @c description and @c nestedError.
 *  The description is accessible by querying error's @c userInfo with
 *  @c NSLocalizedDescriptionKey. The @c nestedError is accessible by error's
 *  @c userInfo with @c NSUnderlyingErrorKey.
 *  If @c errorRef is @c NULL, the error information is logged using NSLog.
 *
 *  @param[out] errorRef    A @c GREYError reference for retrieving the created
 *                          error object.
 *  @param      domain      The error domain.
 *  @param      code        The error code.
 *  @param      description The error's localized description.
 *  @param      nestedError An error to be nested in current error.
 *
 */
#define GREYPopulateNestedErrorOrLog(errorRef, domain, code, description, nestedError) \
({ \
  GREYError *e = GREYNestedErrorMake((domain), (code), (description), (nestedError)); \
  if(errorRef) { \
    *errorRef = e; \
  } else { \
    NSLog(@"%@", e); \
  } \
})

/**
 *  Creates a @c GREYError object with given @c domain, @c code, @c userInfo,
 *  @c filePath, @c line, @c functionName, @c errorInfo and @c stackTrace.
 *
 *  @param domain       The error domain.
 *  @param code         The error code.
 *  @param userInfo     The user information that should be included
 *                      in the @c GREYError object.
 *  @param filePath     The file path where the error is generated.
 *  @param line         The file line where the error is generated.
 *  @param functionName The function name where the error is generated.
 *  @param errorInfo    A dictionary containing details about the error.
 *  @param stackTrace   The stack trace for the app when the error is generated.
 *
 *  @return A @c GREYError object with the given input.
 */
GREY_EXTERN GREYError *I_GREYErrorMake(NSString *domain,
                                       NSInteger code,
                                       NSDictionary *_Nullable userInfo,
                                       NSString *filePath,
                                       NSUInteger line,
                                       NSString *functionName,
                                       NSDictionary *_Nullable errorInfo,
                                       NSArray *stackTrace);

/**
 *  The string for a generic error in EarlGrey.
 */
GREY_EXTERN NSString *const kGREYGenericErrorDomain;

/**
 *  The code for a generic error in EarlGrey.
 */
GREY_EXTERN NSInteger const kGREYGenericErrorCode;

/**
 *  Key used to retrieve the failure name from an error object for a failed action.
 */
GREY_EXTERN NSString *const kErrorDetailFailureNameKey;

/**
 *  Key used to retrieve the action name from an error object for a failed action.
 */
GREY_EXTERN NSString *const kErrorDetailActionNameKey;

/**
 *  Key used to retrieve the assert criteria from an error object for a failed assertion.
 */
GREY_EXTERN NSString *const kErrorDetailAssertCriteriaKey;

/**
 *  Key used to retrieve the detailed recovery suggestion from an error object.
 */
GREY_EXTERN NSString *const kErrorDetailRecoverySuggestionKey;

/**
 *  Key used to retrieve the error domain from an error object.
 */
GREY_EXTERN NSString *const kErrorDomainKey;

/**
 *  Key used to retrieve the error code from an error object.
 */
GREY_EXTERN NSString *const kErrorCodeKey;

/**
 *  Key used to retrieve the error description from an error object.
 */
GREY_EXTERN NSString *const kErrorDescriptionKey;

/**
 *  Key used to retrieve the failure reason from an error object.
 */
GREY_EXTERN NSString *const kErrorFailureReasonKey;

/**
 *  Key used to retrieve the screenshot at failure from an error object's app screenshots.
 */
GREY_EXTERN NSString *const kScreenshotAtFailure;

/**
 *  Key used to retrieve the visibility checker's most recent screenshot before failure
 *  from an error object's app screenshots.
 */
GREY_EXTERN NSString *const kScreenshotBeforeImage;

/**
 *  Key used to retrieve the expected visibility checker's most recent screenshot after failure
 *  from an error object's app screenshots.
 */
GREY_EXTERN NSString *const kScreenshotExpectedAfterImage;

/**
 *  Key used to retrieve the actual visibility checker's most recent screenshot after failure
 *  from an error object's app screenshots.
 */
GREY_EXTERN NSString *const kScreenshotActualAfterImage;

/**
 *  The error class for the error objects generated by EarlGrey.
 */
@interface GREYError : NSError

/**
 *  The name of the test case class where the error is generated.
 */
@property(nonatomic, readonly) NSString *testCaseClassName;

/**
 *  The name of the test case method where the error is generated.
 */
@property(nonatomic, readonly) NSString *testCaseMethodName;

/**
 *  The source code file path where the error is generated.
 */
@property(nonatomic, readonly) NSString *filePath;

/**
 *  The source code line number where the error is generated.
 */
@property(nonatomic, readonly) NSUInteger line;

/**
 *  The source code function name where the error is generated.
 */
@property(nonatomic, readonly) NSString *functionName;

/**
 *  The error information dictionary that is associated with the error.
 */
@property(nonatomic, readonly) NSDictionary *errorInfo;

/**
 *  The bundle identifier where the error is generated in.
 */
@property(nonatomic, readonly) NSString *bundleID;

/**
 *  The stack trace when the error is generated.
 */
@property(nonatomic, readonly) NSArray *stackTrace;

/**
 *  The window hierarchy when the error is generated.
 */
@property(nonatomic, readonly) NSString *appUIHierarchy;

/**
 *  The screenshots for tha app when the error is generated;
 */
@property(nonatomic, readonly) NSDictionary *appScreenshots;

/**
 *  Nested error within current error.
 */
@property(nonatomic, readonly) NSError *nestedError;

/**
 *  The description glossary dictionary that is associated with the error.
 */
@property(nonatomic) NSDictionary *descriptionGlossary;

/**
 *  @remark init is not an available initializer.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  For a given @c error, creates an array of error dictionaries with its nested error.
 *
 *  @return An array of error dictionaries for the given @c error.
 *          If the given error does not contain nested error, an empty array will be returned.
 */
+ (NSArray *)grey_nestedErrorDictionariesForError:(NSError *)error;

/**
 *  For a given @c error, creates a JSON-formatted description of the error and its nested error.
 *
 *  @return The description of the error including its nested errors,
 *          if error object was created and set. Otherwise, return @c NULL.
 */
+ (NSString *)grey_nestedDescriptionForError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

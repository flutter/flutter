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

/**
 *  @file
 *  @brief Helper macros for performing assertions and throwing assertion failure exceptions.
 *  On failure, these macros take screenshots and log full view hierarchy. They wait for app to idle
 *  before performing the assertion.
 */

#ifndef GREY_ASSERTION_DEFINES_H
#define GREY_ASSERTION_DEFINES_H

#import <EarlGrey/GREYConfiguration.h>
#import <EarlGrey/GREYDefines.h>
#import <EarlGrey/GREYFailureHandler.h>
#import <EarlGrey/GREYFrameworkException.h>
#import <EarlGrey/GREYUIThreadExecutor.h>

/**
 *  Exposes internal method to get the failure handler registered with EarlGrey.
 *  It must be called from main thread otherwise the behavior is undefined.
 */
GREY_EXPORT id<GREYFailureHandler> grey_getFailureHandler(void);

/**
 *  These Macros are safe to call from anywhere within a testcase.
 */
#pragma mark - Public Macros

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 evaluates to
 *  @c NO.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssert(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is true."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertTrue((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 evaluates to
 *  @c NO.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertTrue(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is true."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertTrue((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 evaluates to
 *  @c YES.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertFalse(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is false."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertFalse((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 is @c nil.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 is @c nil. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotNil(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is not nil."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertNotNil((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 is not @c nil.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 is not @c nil. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNil(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is nil."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertNil((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are not equal.
 *  @c __a1 and @c __a2 must be scalar types.
 *
 *  @param __a1          The left hand scalar value on the equality operation.
 *  @param __a2          The right hand scalar value on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are not equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertEqual(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are equal."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertEqual((__a1), (__a2), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are equal.
 *  @c __a1 and @c __a2 must be scalar types.
 *
 *  @param __a1          The left hand scalar value on the equality operation.
 *  @param __a2          The right hand scalar value on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotEqual(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = \
      @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are not equal."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertNotEqual((__a1), (__a2), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are not equal.
 *  @c __a1 and @c __a2 must be descendants of NSObject and will be compared with method isEqual.
 *
 *  @param __a1          The left hand object on the equality operation.
 *  @param __a2          The right hand object on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are not equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertEqualObjects(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = \
      @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are equal objects."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertEqualObjects((__a1), (__a2), __description, ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are equal.
 *  @c __a1 and @c __a2 must be descendants of NSObject and will be compared with method isEqual.
 *
 *  @param __a1          The left hand object on the equality operation.
 *  @param __a2          The right hand object on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotEqualObjects(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  NSString *timeoutString__ = \
      @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are not equal objects."; \
  I_GREYWaitForIdle(timeoutString__); \
  I_GREYAssertNotEqualObjects((__a1), (__a2), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure unconditionally, with the provided @c __description.
 *
 *  @param __description Description to print. May be a format string, in which case the variable
 *                       args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYFail(__description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYFail((__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure unconditionally, with the provided @c __description and @c __details.
 *
 *  @param __description  Description to print.
 *  @param __details      The failure details. May be a format string, in which case the variable
 *                        args will be required.
 *  @param ...            Variable args for @c __description if it is a format string.
 */
#define GREYFailWithDetails(__description, __details, ...)  \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYFailWithDetails((__description), (__details), ##__VA_ARGS__); \
})

/**
 *  Generates a failure unconditionally for when the constraints for performing an action fail,
 *  with the provided @c __description and @c __details.
 *
 *  @param __description  Description to print.
 *  @param __details      The failure details. May be a format string, in which case the variable
 *                        args will be required.
 *  @param ...            Variable args for @c __description if it is a format string.
 */
#define GREYConstraintsFailedWithDetails(__description, __details, ...)  \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYConstraintsFailedWithDetails((__description), (__details), ##__VA_ARGS__); \
})

#pragma mark - Private Macros

/**
 *  THESE ARE METHODS TO BE CALLED BY THE FRAMEWORK ONLY.
 *  DO NOT CALL OUTSIDE FRAMEWORK
 */

/// @cond INTERNAL

// No private macro should call this.
#define I_GREYSetCurrentAsFailable() \
({ \
  id<GREYFailureHandler> failureHandler__ = grey_getFailureHandler(); \
  if ([failureHandler__ respondsToSelector:@selector(setInvocationFile:andInvocationLine:)]) { \
    [failureHandler__ setInvocationFile:[NSString stringWithUTF8String:__FILE__] \
                      andInvocationLine:__LINE__]; \
  } \
})

// No private macro should call this.
#define I_GREYWaitForIdle(__timeoutDescription) \
({ \
  CFTimeInterval interactionTimeout__ = \
      GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration); \
  NSError *error__; \
  BOOL success__ = \
      [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:interactionTimeout__ \
                                                              block:nil \
                                                            error:&error__]; \
  if (!success__) { \
    I_GREYTimeout(__timeoutDescription, @"Timed out waiting for app to idle. %@", error__); \
  } \
})

#define I_GREYFormattedString(__var, __format, ...) \
({ \
  /* clang warns us about a leak in formatting but we don't care as we are about to fail. */ \
  _Pragma("clang diagnostic push") \
  _Pragma("clang diagnostic ignored \"-Wformat-nonliteral\"") \
  _Pragma("clang diagnostic ignored \"-Wformat-security\"") \
  (__var) = [NSString stringWithFormat:(__format), ##__VA_ARGS__]; \
  _Pragma("clang diagnostic pop") \
})

#define I_GREYRegisterFailure(__exceptionName, __description, __details, ...) \
({ \
  NSString *details__; \
  I_GREYFormattedString(details__, __details, ##__VA_ARGS__); \
  id<GREYFailureHandler> failureHandler__ = grey_getFailureHandler(); \
  [failureHandler__ handleException:[GREYFrameworkException exceptionWithName:__exceptionName \
                                                                       reason:(__description)] \
                            details:(details__)]; \
})

#define I_GREYAssertTrue(__a1, __description, ...) \
({ \
  if (!(__a1)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"(" #__a1 " is true) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertFalse(__a1, __description, ...) \
({ \
  if ((__a1)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"(" #__a1 " is false) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNotNil(__a1, __description, ...) \
({ \
  if ((__a1) == nil) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYNotNilException, \
                          @"(" #__a1 " != nil) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNil(__a1, __description, ...) \
({ \
  if ((__a1) != nil) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYNilException, \
                          @"(" #__a1 " == nil) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertEqual(__a1, __a2, __description, ...) \
({ \
  if ((__a1) != (__a2)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"(" #__a1 " == (" #__a2 ")) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNotEqual(__a1, __a2, __description, ...) \
({ \
  if ((__a1) == (__a2)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"(" #__a1 " != (" #__a2 ")) failed", \
                          formattedDescription__); \
    } \
})

#define I_GREYAssertEqualObjects(__a1, __a2, __description, ...) \
({ \
  if (![(__a1) isEqual:(__a2)]) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"[" #__a1 " isEqual:(" #__a2 ")] failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNotEqualObjects(__a1, __a2, __description, ...) \
({ \
  if ([(__a1) isEqual:(__a2)]) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"![" #__a1 " isEqual:(" #__a2 ")] failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYFail(__description, ...) \
({ \
  NSString *formattedDescription__; \
  I_GREYFormattedString(formattedDescription__, __description, ##__VA_ARGS__); \
  I_GREYRegisterFailure(kGREYGenericFailureException, formattedDescription__, @""); \
})

#define I_GREYFailWithDetails(__description, __details, ...)  \
  I_GREYRegisterFailure(kGREYGenericFailureException, __description, __details, ##__VA_ARGS__)

#define I_GREYConstraintsFailedWithDetails(__description, __details, ...)  \
  I_GREYRegisterFailure(kGREYConstraintFailedException, __description, __details, ##__VA_ARGS__)

#define I_GREYTimeout(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYTimeoutException, __description, __details, ##__VA_ARGS__)

#define I_GREYActionFail(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYActionFailedException, __description, __details, ##__VA_ARGS__)

#define I_GREYAssertionFail(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYAssertionFailedException, __description, __details, ##__VA_ARGS__)

#define I_GREYElementNotFound(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYNoMatchingElementException, __description, __details, ##__VA_ARGS__)

#define I_GREYMultipleElementsFound(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYMultipleElementsFoundException, \
                        __description, \
                        __details, \
                        ##__VA_ARGS__)

/// @endcond

#endif  // GREY_ASSERTION_DEFINES_H

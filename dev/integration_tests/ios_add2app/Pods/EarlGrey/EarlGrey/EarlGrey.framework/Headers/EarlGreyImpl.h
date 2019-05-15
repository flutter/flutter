//
// Copyright 2018 Google Inc.
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
#import <UIKit/UIKit.h>

#import <EarlGrey/GREYDefines.h>

@class GREYElementInteraction, GREYFrameworkException;
@protocol GREYMatcher, GREYFailureHandler;

/**
 *  Convenience replacement for every EarlGrey method call with
 *  EarlGreyImpl::invokedFromFile:lineNumber: so it can get the invocation file and line to
 *  report to XCTest on failure.
 */
#define EarlGrey                                                                            \
  [EarlGreyImpl invokedFromFile:[NSString stringWithUTF8String:__FILE__] ?: @"UNKNOWN FILE" \
                     lineNumber:__LINE__]

NS_ASSUME_NONNULL_BEGIN

/**
 *  Key for currently set failure handler for EarlGrey in thread's local storage dictionary.
 */
GREY_EXTERN NSString *const kGREYFailureHandlerKey;

/**
 *  Error domain for keyboard dismissal.
 */
GREY_EXTERN NSString *const kGREYKeyboardDismissalErrorDomain;

/**
 *  Error code for keyboard dismissal actions.
 */
typedef NS_ENUM(NSInteger, GREYKeyboardDismissalErrorCode) {
  /**
   *  The keyboard dismissal failed.
   */
  GREYKeyboardDismissalFailedErrorCode = 0,  // Keyboard Dismissal failed.
};

/**
 *  Entrypoint to the EarlGrey framework.
 *  Use methods of this class to initiate interaction with any UI element on the screen.
 */
@interface EarlGreyImpl : NSObject

/**
 *  Provides the file name and line number of the code that is calling into EarlGrey.
 *  In case of a failure, the information is used to tell XCTest the exact line which caused
 *  the failure so it can be highlighted in the IDE.
 *
 *  @param fileName   The name of the file where the failing code exists.
 *  @param lineNumber The line number of the failing code.
 *
 *  @return An EarlGreyImpl instance, with details of the code invoking EarlGrey.
 */
+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber;

/**
 *  @remark init is not an available initializer. Use the <b>EarlGrey</b> macro to start an
 *  interaction.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates a pending interaction with a single UI element on the screen.
 *
 *  In this step, a matcher is supplied to EarlGrey which is later used to sift through the elements
 *  in the UI Hierarchy. This method only denotes that you have an intent to perform an action and
 *  packages a GREYElementInteraction object to do so.
 *  The interaction is *actually* started when it's performed with a @c GREYAction or
 *  @c GREYAssertion.
 *
 *  An interaction will fail when multiple elements are matched. In that case, you will have to
 *  refine the @c elementMatcher to match a single element or use GREYInteraction::atIndex: to
 *  specify the index of the element in the list of elements matched.
 *
 *  By default, EarlGrey looks at all the windows from front to back and
 *  searches for the UI element. To focus on a specific window or container, use
 *  GREYElementInteraction::inRoot: method.
 *
 *  For example, this code will match a UI element with accessibility identifier "foo"
 *  inside a custom UIWindow of type MyCustomWindow:
 *      @code
 *      [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
 *          inRoot:grey_kindOfClass([MyCustomWindow class])]
 *      @endcode
 *
 *  @param elementMatcher The matcher specifying the UI element that will be targeted by the
 *                        interaction.
 *
 *  @return A GREYElementInteraction instance, initialized with an appropriate matcher.
 */
- (GREYElementInteraction *)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher;

/**
 *  Sets the global failure handler for all framework related failures.
 *
 *  A default failure handler is provided by the framework and it is @b strongly advised to use
 *  that if you don't need to customize error handling in your test. Passing in @c nil will revert
 *  the failure handler to default framework provided failure handler.
 *
 *  @param handler The failure handler to be used for all test failures.
 */
- (void)setFailureHandler:(_Nullable id<GREYFailureHandler>)handler;

/**
 *  Convenience wrapper to invoke GREYFailureHandler::handleException:details: on the global
 *  failure handler.
 *
 *  @param exception The exception to be handled.
 *  @param details   Any extra details about the failure.
 */
- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details;

/**
 *  Rotate the device to a given @c deviceOrientation. All device orientations except for
 *  @c UIDeviceOrientationUnknown are supported. If a non-nil @c errorOrNil is provided, it will
 *  be populated with the failure reason if the orientation change fails, otherwise a test failure
 *  will be registered.
 *
 *  @param      deviceOrientation The desired orientation of the device.
 *  @param[out] errorOrNil        Error that will be populated on failure. If @c nil, a test
 *                                failure will be reported if the rotation attempt fails.
 *
 *  @return @c YES if the rotation was successful, @c NO otherwise.
 */
- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation
                       errorOrNil:(__strong NSError **)errorOrNil;

/**
 *  Shakes the device. If a non-nil @c errorOrNil is provided, it will
 *  be populated with the failure reason if the orientation change fails, otherwise a test failure
 *  will be registered.
 *
 *  @param[out] errorOrNil Error that will be populated on failure. If @c nil, the a test
 *                         failure will be reported if the shake attempt fails.
 *
 *  @throws GREYFrameworkException if the action fails and @c errorOrNil is @c nil.
 *  @return @c YES if the shake was successful, @c NO otherwise. If @c errorOrNil is @c nil and
 *          the operation fails, it will throw an exception.
 */
- (BOOL)shakeDeviceWithError:(__strong NSError **)errorOrNil;

/**
 *  Dismisses the keyboard by resigning the first responder, if any. Will populate the provided
 *  error if the first responder is not present or if the keyboard is not visible.
 *
 *  @param[out] errorOrNil Error that will be populated on failure. If @c nil, a test
 *                         failure will be reported if the dismissing fails.
 *
 *  @return @c YES if the dismissing of the keyboard was successful, @c NO otherwise.
 */
- (BOOL)dismissKeyboardWithError:(__strong NSError **)errorOrNil;

@end

NS_ASSUME_NONNULL_END

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

NS_ASSUME_NONNULL_BEGIN

/**
 *  Generic framework failure.
 */
GREY_EXTERN NSString *const kGREYGenericFailureException;
/**
 *  Thrown on action failure.
 */
GREY_EXTERN NSString *const kGREYActionFailedException;
/**
 *  Thrown on assertion failure.
 */
GREY_EXTERN NSString *const kGREYAssertionFailedException;
/**
 *  Thrown when assertion failed due to an unexpected @c nil parameter.
 */
GREY_EXTERN NSString *const kGREYNilException;
/**
 *  Thrown when assertion failed due to an unexpected non-nil parameter.
 */
GREY_EXTERN NSString *const kGREYNotNilException;

/**
 *  Thrown by the selection API when no UI element matches the selection matcher.
 */
GREY_EXTERN NSString *const kGREYNoMatchingElementException;

/**
 *  Thrown by the interaction API when either an action or assertion matcher matches multiple
 *  elements in the UI hierarchy.
 */
GREY_EXTERN NSString *const kGREYMultipleElementsFoundException;

/**
 *  Thrown by the interaction API when either an action or assertion times out waiting for the
 *  app to become idle.
 */
GREY_EXTERN NSString *const kGREYTimeoutException;

/**
 *  Thrown by the action API when the constraints required for performing the action are not
 *  satisfied.
 */
GREY_EXTERN NSString *const kGREYConstraintFailedException;

/**
 *  Exception raised by the framework which results in a test failure.
 *  To catch such exceptions, install a custom failure handler
 *  using EarlGrey::setFailureHandler:. A default failure handler is provided by the framework.
 */
@interface GREYFrameworkException : NSException

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates a new exception instance.
 *
 *  @param name   The name of the exception.
 *  @param reason The reason for the exception.
 *
 *  @return A GREYFrameworkException instance, initialized with a @c name and @c reason.
 */
+ (instancetype)exceptionWithName:(NSString *)name reason:(nullable NSString *)reason;

/**
 *  Creates a new exception instance.
 *
 *  @param name     The name of the exception.
 *  @param reason   The reason for the exception.
 *  @param userInfo userInfo as used by @c NSException.
 *                  EarlGrey doesn't use this param so it's safe to pass nil.
 *
 *  @return A GREYFrameworkException instance, initialized with a @c name and @c reason.
 */
+ (instancetype)exceptionWithName:(NSString *)name
                           reason:(nullable NSString *)reason
                         userInfo:(nullable NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END

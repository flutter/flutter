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

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol to which EarlGrey assertion classes must conform.
 */
@protocol GREYAssertion<NSObject>

/**
 *  Checks whether the assertion is valid for the provided @c element, throwing an exception if the
 *  if the assertion fails and the @c errorOrNil parameter is @c nil. If a non-nil @c errorOrNil is
 *  provided, it will be set to error that represents the assertion failure cause.
 *  If the assertion does not accept @c nil elements, the error domain should be
 *  @c kGREYInteractionErrorDomain and the error code @c kGREYInteractionElementNotFoundErrorCode.
 *  GREYAssertionDefines.h defines macros for throwing common exception types.
 *
 *  @param      element    Element on which the assertion should be checked.
 *  @param[out] errorOrNil If non-nil, set to the cause of the assertion failure.
 *
 *  @throws NSException If the assertion fails and the provided @c errorOrNil is @c nil.
 *                      The specific type depends on the implementation.
 *
 *  @return @c YES if the assertion holds for the specified element, @c NO otherwise.
 */
- (BOOL)assert:(_Nullable id)element error:(__strong NSError *_Nullable *_Nullable)errorOrNil;

/**
 *  @return The name of the assertion.
 */
- (NSString *)name;

@end

NS_ASSUME_NONNULL_END

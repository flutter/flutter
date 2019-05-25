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

#import <EarlGrey/GREYAssertion.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A block that accepts an @c element, which will be invoked when an assertion is going to be
 *  performed on the element. If the assertion fails and a non-nil @c errorOrNil is provided,
 *  the block should populate it with the cause of failure.
 *
 *  @param      element    Element that the assertion will be checked against.
 *  @param[out] errorOrNil If non-nil, set to the cause of the assertion failure.
 *
 *  @return @c YES if the assertion is valid for @c element, @c NO otherwise.
 */
typedef BOOL (^GREYCheckBlockWithError)(_Nullable id element,
                                        __strong NSError *_Nullable *_Nullable errorOrNil);

/**
 *  An interface to create GREYAssertions from blocks.
 */
@interface GREYAssertionBlock : NSObject<GREYAssertion>

/**
 *  Creates an assertion with the given @c name and @c block that is executed when
 *  GREYAssertion::assert:error: selector is performed on the assertion.
 *
 *  @param name  The assertion name.
 *  @param block The block that will be invoked to perform the assertion.
 *
 *  @return A new block-based assertion object.
 */
+ (instancetype)assertionWithName:(NSString *)name
          assertionBlockWithError:(GREYCheckBlockWithError)block;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes an assertion with the given @c name and @c block that is executed when
 *  GREYAssertion::assert:error: selector is performed on the assertion.
 *
 *  @param name  The assertion name.
 *  @param block The block that will be invoked to perform the assertion.
 *
 *  @return The initialized assertion object.
 */
- (instancetype)initWithName:(NSString *)name
     assertionBlockWithError:(GREYCheckBlockWithError)block NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

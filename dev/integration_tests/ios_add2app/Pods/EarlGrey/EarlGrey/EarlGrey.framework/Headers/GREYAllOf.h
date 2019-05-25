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
#import <EarlGrey/GREYBaseMatcher.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A matcher for combining multiple matchers with a logical @c AND operator, so that a match
 *  only occurs when all combined matchers match the element. The invocation of the matchers
 *  is in the same order in which they are passed. As soon as one matcher fails, the
 *  rest of the matchers are not invoked.
 */
@interface GREYAllOf : GREYBaseMatcher

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Designated initializer that adds the different matchers to be combined.
 *
 *  @param matchers Matchers that conform to GREYMatcher and will be combined together with
 *                  a logical AND in the order they are passed in.
 *
 *  @return An instance of GREYAllOf, initialized with the provided @c matchers.
 */
- (instancetype)initWithMatchers:(NSArray<__kindof id<GREYMatcher>> *)matchers
    NS_DESIGNATED_INITIALIZER;

#if !(GREY_DISABLE_SHORTHAND)

/**
 *  A shorthand matcher that is a logical AND of all the matchers passed in as variable arguments.
 *
 *  @param first      The first matcher in the list of matchers.
 *  @param second     The second matcher in the list of matchers.
 *  @param thirdOrNil The third matcher in the list of matchers, optionally the nil terminator.
 *  @param ...        Any more matchers to be added. Matchers are invoked in the order they are
 *                    specified and only if the preceding matcher passes. This va-arg must be
 *                    terminated with a @c nil value.
 *
 *  @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_allOf(id<GREYMatcher> first,
                                       id<GREYMatcher> second,
                                       id<GREYMatcher> _Nullable thirdOrNil,
                                       ...)
    NS_SWIFT_UNAVAILABLE("Use grey_allOf(_:) instead") NS_REQUIRES_NIL_TERMINATION;

/**
 *  A shorthand matcher that is a logical AND of all the matchers passed in within an NSArray.
 *
 *  @param matchers An NSArray of one or more matchers to be added. Matchers are invoked in the
 *                  order they are specified and only if the preceding matcher passes.
 *
 *  @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher>
    grey_allOfMatchers(NSArray<__kindof id<GREYMatcher>> *matchers)
    NS_SWIFT_NAME(grey_allOf(_:));

#endif // GREY_DISABLE_SHORTHAND

@end

NS_ASSUME_NONNULL_END

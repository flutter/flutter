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

#import <EarlGrey/GREYDescription.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Matchers are another way of expressing simple or complex logical expressions. This protocol
 *  defines a set of methods that must be implemented by every matcher object.
 */
@protocol GREYMatcher<NSObject>

/**
 *  A method to evaluate the matcher for the provided @c item.
 *
 *  @param item The object which is to be evaluated against the matcher.
 *
 *  @return @c YES if the object matched the matcher, @c NO otherwise.
 */
- (BOOL)matches:(_Nullable id)item;

/**
 *  A method to evaluate the matcher for the provided @c item with a description for the issue
 *  in case of a mismatch.
 *
 *  @param item                The object which is to be evaluated against the matcher.
 *
 *  @param mismatchDescription The description that is built or appended if the provided @c item
 *                             does not match the matcher.
 *
 *  @return @c YES if the object matched the matcher, @c NO otherwise. In case of a mismatch, the
 *             reason for mismatch is added to @c mismatchDescription.
 */
- (BOOL)matches:(_Nullable id)item describingMismatchTo:(id<GREYDescription>)mismatchDescription;

/**
 *  A method to generate the description containing the reason for why a matcher did not match an
 *  item.
 *
 *  @param item                The object which is to be evaluated against the matcher.
 *
 *  @param mismatchDescription The description that is built or appended if the provided @c item
 *                             does not match the matcher.
 *
 *  @remark This method assumes that GREYMatcher::matches: is false, but will not check this.
 */
- (void)describeMismatchOf:(_Nullable id)item to:(id<GREYDescription>)mismatchDescription;

/**
 *  A method to generate a description of an object.
 *
 *  @param description The description that is built or appended.
 */
- (void)describeTo:(id<GREYDescription>)description;

@end

NS_ASSUME_NONNULL_END

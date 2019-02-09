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

@protocol GREYMatcher, GREYProvider;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Finds UI elements in GREYProvider that are accepted by a matcher.
 */
@interface GREYElementFinder : NSObject

/**
 *  The matcher the element finder is initialized with. Objects returned from this class
 *  must match this matcher.
 */
@property(nonatomic, readonly) id<GREYMatcher> matcher;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes the finder with a given @c matcher.
 *
 *  @param matcher Matcher that defines what elements the finder should search for.
 *
 *  @return An instance of GREYElementFinder, initialized with a matcher.
 */
- (instancetype)initWithMatcher:(id<GREYMatcher>)matcher NS_DESIGNATED_INITIALIZER;

/**
 *  Performs a search on elements provided by @c elementProvider and returns all the elements
 *  that are accepted by the matcher this object is initialized with.
 *
 *  @param elementProvider Provides elements to run through the matcher.
 *
 *  @return An array of matched elements. If no matching element is found, then it is empty.
 *          The relative order of the elements is preserved when returned.
 */
- (NSArray *)elementsMatchedInProvider:(id<GREYProvider>)elementProvider;

@end

NS_ASSUME_NONNULL_END

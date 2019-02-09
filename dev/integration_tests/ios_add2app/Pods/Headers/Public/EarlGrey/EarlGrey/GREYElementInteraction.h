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

#import <EarlGrey/GREYInteraction.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Interface for creating an interaction with a UI element. If no datasource is set,
 *  a default datasource is used. The default datasource provides access to the entire UI element
 *  hierarchy of all the windows in the application.
 */
@interface GREYElementInteraction : NSObject<GREYInteraction>

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes the interaction with a single UI element matching @c elementMatcher.
 *
 *  @param elementMatcher Matcher for selecting UI element to interact with.
 *
 *  @return An instance of GREYElementInteraction, initialized with a specified matcher.
 */
- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher;

@end

NS_ASSUME_NONNULL_END

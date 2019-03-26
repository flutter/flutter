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
 *  @file GREYElementInteraction+Internal.h
 *  @brief Exposes GREYElementInteraction's interfaces and methods that are otherwise private for
 *  testing purposes.
 */

#import <EarlGrey/GREYElementInteraction.h>

NS_ASSUME_NONNULL_BEGIN

@interface GREYElementInteraction (Internal)

/**
 *  Searches for UI elements within the root views and returns all matched UI elements. The given
 *  search action is performed until an element is found.
 *
 *  @param timeout The amount of time during which search actions must be performed to find an
 *                 element.
 *  @param error   The error populated on failure. If an element was found and returned when using
 *                 the search actions then any action or timeout errors that happened in the
 *                 previous search are ignored. However, if an element is not found, the error
 *                 will be propagated.
 *
 *  @return An array of matched UI elements in the data source. If no UI element is found in
 *          @c timeout seconds, a timeout error will be produced and no UI element will be returned.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (NSArray *)matchedElementsWithTimeout:(NSTimeInterval)timeout error:(__strong NSError **)error;

@end

NS_ASSUME_NONNULL_END

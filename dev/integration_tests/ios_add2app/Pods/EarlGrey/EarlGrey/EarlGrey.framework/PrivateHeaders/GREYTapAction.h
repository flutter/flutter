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

#import <EarlGrey/GREYBaseAction.h>
#import <EarlGrey/GREYConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A GREYAction that taps on a given element.
 */
@interface GREYTapAction : GREYBaseAction

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  @remark initWithName::constraints: is overridden from its superclass.
 */
- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints NS_UNAVAILABLE;

/**
 *  A GREYAction that taps the given element.
 *
 *  @param tapType The type of tap to be performed.
 *
 *  @return An instance of GREYTapAction, initialized with the tap type to be performed.
 */
- (instancetype)initWithType:(GREYTapType)tapType;

/**
 *  A GREYAction that taps the given element for a given number of times.
 *
 *  @param tapType      The type of tap to be performed.
 *  @param numberOfTaps Number of times the element should be tapped.
 *
 *  @return An instance of GREYTapAction, initialized with the tap type and
            the number of times it should be performed.
 */
- (instancetype)initWithType:(GREYTapType)tapType numberOfTaps:(NSUInteger)numberOfTaps;

/**
 *  A GREYAction that taps the given element for a given number of times at the given location.
 *
 *  @param tapType      The type of tap to be performed.
 *  @param numberOfTaps Number of times the element should be tapped.
 *  @param tapLocation  The location to be tapped, relative to the view being tapped.
 *
 *  @return An instance of GREYTapAction, initialized with the tap type and
            the number of times it should be performed and the location to be tapped.
 */
- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    location:(CGPoint)tapLocation;

/**
 *  A GREYAction that performs a long press with a given duration.
 *
 *  @param duration The duration of the long press.
 *
 *  @return An instance of GREYTapAction, initialized with the duration of the long press.
 */
- (instancetype)initLongPressWithDuration:(CFTimeInterval)duration;

/**
 *  A GREYAction that performs a long press with a given @c duration at the given @c location.
 *
 *  @param duration The duration of the long press.
 *  @param location The location of the long press relative to the element recieving the touch
 *                  event.
 *
 *  @return An instance of GREYTapAction, initialized with the @c duration and @c location of
 *          the long press.
 */
- (instancetype)initLongPressWithDuration:(CFTimeInterval)duration location:(CGPoint)location;

/**
 *  A GREYAction that performs a tap of the specified @c type for the speficied @c numberOfTaps at
 *  the @c location, with each tap in case of time based touch events like long press lasting for
 *  the given @c duration.
 *
 *  @param tapType      The type of the tap.
 *  @param numberOfTaps Number of times the element should be tapped.
 *  @param duration     The duration of the tap event if applicable.
 *  @param tapLocation  The location of the tap relative to the element recieving the touch
 *                      event.
 *
 *  @return An initialized (to the given parameters) instance of GREYTapAction.
 */
- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    duration:(CFTimeInterval)duration
                    location:(CGPoint)tapLocation NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

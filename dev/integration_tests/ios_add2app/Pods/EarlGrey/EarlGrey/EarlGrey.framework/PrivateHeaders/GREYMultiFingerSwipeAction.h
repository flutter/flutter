//
// Copyright 2017 Google Inc.
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
 *  A GREYAction that swipes/flicks with multiple touches
 */
@interface GREYMultiFingerSwipeAction : GREYBaseAction

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
 *  Performs a swipe with multiple parallel fingers in the given @c direction in the given
 *  @c duration, the start of swipe is chosen to achieve maximum swipe, such as a point close to
 *  bottom edge of the element is chosen in case of a swipe in up direction. Using this method will
 *  infer a start percentage of x: 0.5, y: 0.5.
 *
 *  @param direction       The direction of the swipe.
 *  @param duration        The time interval for which the swipe takes place.
 *  @param numberOfFingers The number of parallel fingers to use. Max value: 4.
 *
 *  @return An instance of GREYMultiFingerSwipeAction, initialized with the provided direction,
 *          duration and number of fingers to swipe with.
 */
- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                  numberOfFingers:(NSUInteger)numberOfFingers;

/**
 *  Performs a swipe with multiple parallel fingers in the given @c direction in the given
 *  @c duration, the start of swipe is chosen based on @c startPercents. Since swipes must begin
 *  inside the element and not on the edge of it x/y, startPercents must be in the range (0,1)
 *  exclusive.
 *
 *  @param direction       The direction of the swipe.
 *  @param duration        The time interval for which the swipe takes place.
 *  @param numberOfFingers The number of parallel fingers to use. Max Value: 4.
 *  @param startPercents   @c startPercents.x sets the value of the x-coordinate of the start point
 *                         by interpolating between left(for 0.0) and right(for 1.0) edge similarly
 *                         @c startPercents.y determines the y coordinate.
 *
 *  @return An instance of GREYMultiFingerSwipeAction, initialized with the provided direction,
 *          duration, information for the start point and number of fingers to swipe with.
 */
- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                  numberOfFingers:(NSUInteger)numberOfFingers
                    startPercents:(CGPoint)startPercents NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END


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

#import <UIKit/UIKit.h>

#import <EarlGrey/GREYConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A utility class for creating and injecting gestures that involve touch paths, for example:
 *  swipe, scroll etc.
 */
@interface GREYPathGestureUtils : NSObject

/**
 *  Generates a touch path in the @c window from the start point, in the given direction to the
 *  max possible extent.
 *
 *  @param startPointInWindowCoordinates The start point within the given @c window
 *  @param direction                     The direction of the touch path.
 *  @param duration                      How long the gesture should last (in seconds).
 *  @param window                        The window in which the touch path is generated.
 *
 *  @return NSArray of CGPoints that denote the points in the touch path.
 */
+ (NSArray *)touchPathForGestureWithStartPoint:(CGPoint)startPointInWindowCoordinates
                                  andDirection:(GREYDirection)direction
                                   andDuration:(CFTimeInterval)duration
                                      inWindow:(UIWindow *)window;

/**
 *  Generates a touch path in the @c window starting from a given @c view in a particular direction
 *  for a certain amount in the window coordinates of the @c view. The start point of the path is
 *  controlled by @c startPointPercents, which if specified as @c NAN, the start point will be
 *  chosen to provide longest possible touch path, otherwise start point will be set to the percents
 *  specified in the visible area of the given @c view. Note that the percent values must lie within
 *  (0, 1) exclusive and the x and y axis are always the bottom and the left edge respectively of
 *  the visible rect.
 *
 *  @param      view                     The view from which the touch path originates.
 *  @param      direction                The direction of the touch.
 *  @param      length                   The length of the touch path. The length of the touch path
 *                                       is restricted by the screen dimensions, position of the
 *                                       view and the minimum scroll detection length (10 points as
 *                                       of iOS 8.0).
 *  @param      startPointPercents       The start point of the touch path specified as percents in
 *                                       the visible area of the @c view. Must be (0, 1) exclusive.
 *  @param[out] outRemainingAmountOrNull The difference of the length and the amount,
 *                                       if the length falls short.
 *
 *  @return Array of CGPoints that denote the points in the touch path. The touch path's length
 *          will be at least the minimum scroll detection length, when that is not possible
 *          (due to @c view position and/or size) @c nil is returned.
 */
+ (NSArray *)touchPathForGestureInView:(UIView *)view
                         withDirection:(GREYDirection)direction
                                length:(CGFloat)length
                    startPointPercents:(CGPoint)startPointPercents
                    outRemainingAmount:(CGFloat *_Nullable)outRemainingAmountOrNull;

/**
 *  Generates a touch path in the @c window from the given @c startPoint and the given @c
 *  endPoint.
 *
 *  @param startPoint    The starting point for touch path.
 *  @param endPoint      The end point for touch path.
 *  @param cancelInertia A boolean value indicating whether intertial movement should be cancelled.
 *
 *  @return NSArray of CGPoints that denote the points in the touch path.
 */
+ (NSArray *)touchPathForDragGestureWithStartPoint:(CGPoint)startPoint
                                          endPoint:(CGPoint)endPoint
                                     cancelInertia:(BOOL)cancelInertia;

@end

NS_ASSUME_NONNULL_END

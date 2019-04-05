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

#import <QuartzCore/QuartzCore.h>

/**
 *  An enumeration of all states that EarlGrey identifies a CAAnimation to be in.
 */
typedef NS_ENUM(NSUInteger, GREYCAAnimationState) {
  /**
   *  Default state every animation is in.
   */
  kGREYAnimationPendingStart = 0,
  /**
   *  State the animation is in when it begins.
   */
  kGREYAnimationStarted,
  /**
   *  State the animation is in when it ends.
   */
  kGREYAnimationStopped,
};

NS_ASSUME_NONNULL_BEGIN

/**
 *  EarlGrey specific addition for CAAnimation to track currently running animations.
 */
@interface CAAnimation (GREYAdditions)

/**
 *  Sets the animation state to @c state.
 *
 *  @param state The target state.
 */
- (void)grey_setAnimationState:(GREYCAAnimationState)state;

/**
 *  Returns the current state of the animation. If CAAnimation::grey_setAnimationState was never
 *  called on this animation, @c kGREYANIMATION_PENDING_START is returned.
 *
 *  @return The current state.
 */
- (GREYCAAnimationState)grey_animationState;

/**
 *  Tracks the animation with GREYAppStateTracker until the expected animation runtime has elapsed,
 *  after which it untracks itself.
 */
- (void)grey_trackForDurationOfAnimation;

/**
 *  Force untrack itself from GREYAppStateTracker, regardless of completion status.
 */
- (void)grey_untrack;

@end

NS_ASSUME_NONNULL_END

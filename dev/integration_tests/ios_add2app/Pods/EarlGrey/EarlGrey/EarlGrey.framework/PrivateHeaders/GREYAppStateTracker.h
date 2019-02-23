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

#import <EarlGrey/GREYIdlingResource.h>

@class GREYAppStateTrackerObject;

NS_ASSUME_NONNULL_BEGIN

/**
 * @file
 * @brief App state tracker header file.
 */

/**
 *  Non-idle states that the App can be at any given point in time.
 *  These states are not mutually exclusive and can be combined together using Bitwise-OR to
 *  represent multiple states.
 */
typedef NS_OPTIONS(NSUInteger, GREYAppState) {
  /**
   *  Idle state implies App is not undergoing any state changes and it is OK to interact with it.
   */
  kGREYIdle = 0,
  /**
   *  View is pending draw or layout pass.
   */
  kGREYPendingDrawLayoutPass = (1UL << 0),
  /**
   *  Waiting for viewDidAppear: method invocation.
   */
  kGREYPendingViewsToAppear = (1UL << 1),
  /**
   *  Waiting for viewDidDisappear: method invocation.
   */
  kGREYPendingViewsToDisappear = (1UL << 2),
  /**
   *  Pending keyboard transition.
   */
  kGREYPendingKeyboardTransition = (1UL << 3),
  /**
   *  Waiting for CA animation to complete.
   */
  kGREYPendingCAAnimation = (1UL << 4),
  /**
   *  Waiting for a UIAnimation to be marked as stopped.
   */
  kGREYPendingUIAnimation = (1UL << 5),
  /**
   *  Pending root view controller to be set.
   */
  kGREYPendingRootViewControllerToAppear = (1UL << 6),
  /**
   *  Pending a UIWebView async load request
   */
  kGREYPendingUIWebViewAsyncRequest = (1UL << 7),
  /**
   *  Pending a network request completion.
   */
  kGREYPendingNetworkRequest = (1UL << 8),
  /**
   *  Pending gesture recognition.
   */
  kGREYPendingGestureRecognition = (1UL << 9),
  /**
   *  Waiting for UIScrollView to finish scrolling.
   */
  kGREYPendingUIScrollViewScrolling = (1UL << 10),
  /**
   *  [UIApplication beginIgnoringInteractionEvents] was called and all interaction events are
   *  being ignored.
   */
  kGREYIgnoringSystemWideUserInteraction = (1UL << 11),
};

/**
 *  Idling resource that tracks the application state.
 */
@interface GREYAppStateTracker : NSObject<GREYIdlingResource>

/**
 *  @return The unique shared instance of the GREYAppStateTracker.
 */
+ (instancetype)sharedInstance;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  @return The state that the App is in currently.
 */
- (GREYAppState)currentState;

/**
 *  Updates the state of the object, including the provided @c state and updating the overall state
 *  of the application. If @c object is already being tracked with for a different state, the
 *  object's state will be updated to a XOR of the current state and @c state.
 *
 *  @param state  The state that should be tracked for the object.
 *  @param object The object that should have its tracked state updated.
 *
 *  @return The GREYAppStateTracker that was assigned to the object by the state tracker, or @c nil
 *          if @c object is @c nil. Future calls for the same object will return the same
 *          identifier until the object is untracked.
 */
- (GREYAppStateTrackerObject * _Nullable)trackState:(GREYAppState)state forObject:(id)object;

/**
 *  Untracks the state for the object with the specified id. For untracking, it does not matter
 *  if the state has been added to being ignored.
 *
 *  @param state  The state that should be untracked.
 *  @param object The GREYAppStateTrackerObject associated with the object whose state should be
 *                untracked.
 */
- (void)untrackState:(GREYAppState)state forObject:(GREYAppStateTrackerObject *)object;

/**
 *  Ignore any state changes made to the state(s) provided. To stop ignoring a state, set this
 *  to a @c GREYAppState value that does not contain that particular state or use
 *  @c GREYAppStateTracker::clearIgnoredStates.
 *
 *  @remark This will not retroactively affect any currently tracked objects with the ignored app
 *          state(s). This only ensures that any further tracking of an object with an app state
 *          that is being ignored will be ignored. Untracking is not affected by this method.
 *
 *  @param state The app state that should be ignored. This can be a bitwise-OR of multiple
 *               app states.
 */
- (void)ignoreChangesToState:(GREYAppState)state;

/**
 *  Removes any states that were being ignored.
 */
- (void)clearIgnoredStates;

/**
 *  Clears all states that are tracked by the GREYAppStateTracker singleton.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (void)grey_clearState;

@end

/**
 *  Utility macro for tracking the state of an object.
 *
 *  @param state  The state that should be tracked for the object.
 *  @param object The object that should have its tracked state updated.
 *
 *  @return The GREYAppStateTracker that was assigned to the object by the state tracker, or @c nil
 *          if @c object is @c nil. Future calls for the same object will return the same
 *          identifier until the object is untracked.
 */
#define TRACK_STATE_FOR_OBJECT(state_, object_) \
  [[GREYAppStateTracker sharedInstance] trackState:(state_) forObject:(object_)]

/**
 *  Utility macro for untracking the state of an object.
 *
 *  @param state  The state that should be untracked.
 *  @param object The GREYAppStateTrackerObject associated with the object whose state should be
 *                untracked.
 */
#define UNTRACK_STATE_FOR_OBJECT(state_, object_) \
  [[GREYAppStateTracker sharedInstance] untrackState:(state_) forObject:(object_)]

NS_ASSUME_NONNULL_END

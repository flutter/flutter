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
#import "Event/GREYTouchInfo.h"

/**
 *  The frequency at which touches will be injected per second. Currently set to 60Hz.
 */
GREY_EXTERN const NSTimeInterval kGREYTouchInjectionFrequency;

/**
 *  State for touch injector.
 */
typedef NS_ENUM(NSInteger, GREYTouchInjectorState) {
  /**
   *  Touch injection hasn't started yet.
   */
  kGREYTouchInjectorPendingStart,
  /**
   *  Injection has started injecting touches.
   */
  kGREYTouchInjectorStarted,
  /**
   *  Touch injection has stopped. This state is reached when injector has
   *  finished injecting all the queued touches.
   */
  kGREYTouchInjectorStopped,
};

NS_ASSUME_NONNULL_BEGIN

/**
 *  A touch injector that delivers a complete touch sequence for single finger interactions.
 *  Buffers all touch events until @c startInjecting: is called.
 *  Once injection is complete, this injector should be discarded.
 */
@interface GREYTouchInjector : NSObject
/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes with the @c window to which touches will be delivered.
 *
 *  @param window The window that receives the touches.
 *
 *  @return An instance of GREYSingleSequenceTouchInjector, initialized with the window to be
 *          touched.
 */
- (instancetype)initWithWindow:(UIWindow *)window NS_DESIGNATED_INITIALIZER;

/**
 *  Enqueues @c touchInfo that will be materialized into a UITouch and delivered to application.
 *
 *  @param touchInfo The info that is used to create the UITouch. If it represents a last touch
 *                   in a sequence, the specified @c point value is ignored and injector
 *                   automatically picks the previous point where touch occured to deliver
 *                   the last touch.
 */
- (void)enqueueTouchInfoForDelivery:(GREYTouchInfo *)touchInfo;

/**
 *  @return The state of this injector.
 */
- (GREYTouchInjectorState)state;

/**
 *  Starts delivering touches to current application.
 */
- (void)startInjecting;

/**
 *  Wait until the touch injection has stopped.
 */
- (void)waitUntilAllTouchesAreDeliveredUsingInjector;

@end

NS_ASSUME_NONNULL_END

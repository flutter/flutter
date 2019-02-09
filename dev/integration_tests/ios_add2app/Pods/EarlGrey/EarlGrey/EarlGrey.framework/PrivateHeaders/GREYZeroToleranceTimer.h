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

@class GREYZeroToleranceTimer;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol expected to be implemented by @c GREYZeroToleranceTimer's targets, the timer fire
 *  event is indicated by sending the appropriate messages of this protocol to the target.
 */
@protocol GREYZeroToleranceTimerTarget <NSObject>

/**
 *  Invoked by @c GREYZeroToleranceTimer object when timeout fires.
 *
 *  @param timer The timer whose timeout fired.
 */
- (void)timerFiredWithZeroToleranceTimer:(GREYZeroToleranceTimer *)timer;

@end

/**
 *  A high fidelity timer implementation (for example, to be used for delivering touches with
 *  accurate timing). For example, the following code sets up the timer to fire every one second:
 *  @code
 *  self.timerForFoo = [[GREYZeroToleranceTimer alloc] initWithInterval:1.0 target:foo];
 *  @endcode
 *  Note that @c GREYZeroToleranceTimer objects create strong references to the provided targets
 *  therefore the following is perfectly legal as well:
 *  @code
 *  [[GREYZeroToleranceTimer alloc] initWithInterval:1.0 target:[[FooClass alloc] init]];
 *  @endcode
 *  The the timer and the created FooClass object acting as a target will remain in memory until it
 *  invalidates the timer (this can be done from the code that is invoked on the timer fire event).
 *  Once invalidated both the timer and the object will deallocate.
 */
@interface GREYZeroToleranceTimer : NSObject

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes and schedules a new zero tolerance timer.
 *
 *  @param interval The timeout interval in seconds.
 *  @param target   The target that should handle the timeouts. Targets must implement
 *                  @c GREYZeroToleranceTimerTarget protocol as every time timer fires
 *                  appropriate methods from the protocol will be invoked.
 *
 *  @return An initialized and scheduled timer.
 */
- (instancetype)initWithInterval:(CFTimeInterval)interval
                          target:(id<GREYZeroToleranceTimerTarget>)target;

/**
 *  Invalidates the timer and cancels all future timeouts.
 */
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END

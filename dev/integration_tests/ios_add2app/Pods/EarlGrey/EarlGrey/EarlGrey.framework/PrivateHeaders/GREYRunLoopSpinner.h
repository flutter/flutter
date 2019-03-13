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

NS_ASSUME_NONNULL_BEGIN

/**
 *  @brief Handles spinning the current run loop in the active mode with various configurations.
 *  Similar to dispatch_sync calls on a thread, you cannot make nested spin calls to the same
 *  spinner object, but it is OK to create and spin a separate spinner object within a
 *  source/timer/block invoked by another spinner.
 *
 *  The current run loop mode is the mode that a run loop is currently executing in. The active run
 *  loop mode is (more or less) the mode that the run loop would be executing if we weren't
 *  controlling the run loop's execution. Some events, like scrolling, will switch the current mode
 *  under normal conditions but not while we are spinning the run loop. To make the app behave
 *  closer to normal app conditions, the run loop spinner spins the run loop in the active mode not
 *  the current mode.
 *
 *  Draining (or doing a pass over) the run loop in a particular mode is running the run loop so
 *  that it service all pending blocks, sources, or timers. Spinning the run loop means repeatedly
 *  draining the run loop, possibly allowing the run loop to sleep between drains.
 *
 *  While the run loop spinner is running the run loop in a particular mode, any source/timer/block
 *  serviced by the run loop may itself start running the run loop in any mode of its choosing.
 *  In that case, we consider run loop as not running in the mode that we started spinning, even
 *  if the source/timer/block started running the run loop in the same mode (nesting the run loop
 *  mode).
 */
@interface GREYRunLoopSpinner : NSObject

/**
 *  The maximum time in seconds that the spinner will spin the run loop. Default is 0.
 *
 *  The spinner will not initiate any run loop drains after @c timeout seconds, but it is possible
 *  that an ongoing run loop drain will be executing after @c timeout. If @c timeout is 0, then the
 *  spinner will only drain the run loop for its configured minimum number of run loop drains.
 */
@property(nonatomic) CFTimeInterval timeout;

/**
 *  The maximum time in seconds that the current thread will be allowed to sleep while running in
 *  the active mode that we started spinning. Default is 0.
 *
 *  If set to 0, then the run loop will not be allowed to sleep in the active mode that it started
 *  spinning.
 *
 *  @remark Not allowing the run loop to sleep can be useful for some test scenarios but causes the
 *          thread to use significantly more CPU.
 */
@property(nonatomic) CFTimeInterval maxSleepInterval;

/**
 *  The minimum number of times that the run loop should be drained in the active mode before
 *  checking the stop condition. Default is 2.
 *
 *  @remark The default value is 2 because, as per the CFRunLoop implementation, some ports
 *          (specifically the dispatch port) will only be serviced every other run loop drain.
 */
@property(nonatomic) NSUInteger minRunLoopDrains;

/**
 *  This block is invoked in the active run loop mode if the stop condition evaluates to YES.
 *  Default is a noop.
 */
@property(copy, nonatomic) void (^conditionMetHandler)(void);

/**
 *  Spins the current thread's run loop in the active mode using the given stop condition.
 *
 *  Will always spin the run loop for at least the minimum number of run loop drains. Will always
 *  evaluate @c stopConditionBlock at least once after draining for minimum number of drains. After
 *  draining for the minimum number of drains, the spinner will evaluate @c stopConditionBlock at
 *  least once per run loop drain. The spinner will stop initiating drains and return if
 *  @c stopConditionBlock evaluates to @c YES or if the timeout has elapsed.
 *
 *  @remark This method should not be invoked on the same spinner object in nested calls (e.g.
 *          sources that are serviced while it's spinning) or concurrently.
 *
 *  @param stopConditionBlock The condition block used by the spinner to determine if it should
 *                            keep spinning the active run loop.
 *
 *  @return @c YES if the spinner evaluated the @c stopConditionBlock to @c YES; @c NO otherwise.
 */
- (BOOL)spinWithStopConditionBlock:(BOOL (^)(void))stopConditionBlock;

@end

NS_ASSUME_NONNULL_END

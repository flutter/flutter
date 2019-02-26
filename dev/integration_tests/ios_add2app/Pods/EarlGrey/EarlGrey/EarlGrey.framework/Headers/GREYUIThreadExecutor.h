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

/**
 *  @file
 *  @brief Header file for GREYUIThreadExecutor.
 */

NS_ASSUME_NONNULL_BEGIN

@protocol GREYIdlingResource;

/**
 *  Error domain for thread executor failures.
 */
GREY_EXTERN NSString *const kGREYUIThreadExecutorErrorDomain;

/**
 *  Error codes for thread executor failures.
 */
typedef NS_ENUM(NSInteger, GREYUIThreadExecutorErrorCode) {
  /**
   *  Timeout reached before block could be executed.
   */
  kGREYUIThreadExecutorTimeoutErrorCode,
};

/**
 *  Typedef for blocks that can be executed by the GREYUIThreadExecutor.
 */
typedef void(^GREYExecBlock)(void);

/**
 *  Executor that syncs execution with the UI events on the main thread.
 *  Before executing a block or operation, it waits for any pending UI events to complete.
 */
@interface GREYUIThreadExecutor : NSObject

/**
 *  @return The unique shared instance of the GREYUIThreadExecutor.
 */
+ (instancetype)sharedInstance;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Blocking call that drains the main runloop enough times to make each source gets a fair chance
 *  of service. No guarantee is made on whether the app is in kGREYIdle state after this method
 *  returns.
 */
- (void)drainOnce;

/**
 *  Blocking call that drains the UI thread for the specified number of @c seconds.
 *  This method can block for longer than the specified time if any of the signalled sources take
 *  longer than that to execute.
 *
 *  @param seconds Amount of time that the UI thread should be drained for, in seconds.
 */
- (void)drainForTime:(CFTimeInterval)seconds;

/**
 *  Blocking call that drains the UI thread until both the UI and registered GREYIdlingResources
 *  are in idle.
 *
 *  @remark Be very careful while calling this as you could end up in state where the caller expects
 *          the callee to mark the thread as idle and callee inadvertantly calls
 *          GREYUIThreadExecutor::drainUntilIdle:, in which case it will go into an infinite loop
 *          and the test will have to be force-killed by the test-runner.
 */
- (void)drainUntilIdle;

/**
 *  Drains the UI thread and waits for both the UI and idling resources to idle until the given
 *  amount of @c seconds have passed, at which point, a timeout occurs and the method returns @c NO.
 *  Returns @c YES if idled within @c seconds, @c NO otherwise.
 *
 *  @param seconds Amount of time to wait for the UI and idling resources to idle.
 *
 *  @return @c YES if idled within @c seconds, @c NO otherwise.
 */
- (BOOL)drainUntilIdleWithTimeout:(CFTimeInterval)seconds;

/**
 *  Invokes GREYUIThreadExecutor::executeSyncWithTimeout:block:error: with @c kGREYInfiniteTimeout,
 *  @c execBlock and @c error as the respective parameters.
 *
 *  @param execBlock      The block to be executed.
 *  @param errorOrNil     Reference to the error that will store the failure cause, if any.
 *
 *  @return @c YES if the block was executed, @c NO otherwise, in which case @c error will be set to
 *          the failure cause.
 */
- (BOOL)executeSync:(GREYExecBlock)execBlock
              error:(__strong NSError *_Nullable *_Nullable)errorOrNil;

/**
 *  Executes @c execBlock on the main thread, synchronizing with all registered GREYIdlingResources
 *  and UI events. If the UI thread or idling resources are not idle until @c seconds have elapsed,
 *  @c execBlock is not executed and error (if provided) is populated.
 *
 *  @param seconds        The timeout for waiting for the resources to idle, in seconds.
 *                        A value of @c kGREYInfiniteTimeout indicates an infinite timeout.
 *  @param execBlock      The block to be executed.
 *  @param errorOrNil     Reference to the error that will store the failure cause, if any.
 *
 *  @return @c YES if the block was executed, @c NO otherwise, in which case @c error will be set to
 *          the failure cause.
 *
 *  @remark Blocks are executed in the order in which they were submitted.
 *  @remark This selector must be invoked on the main thread.
 */
- (BOOL)executeSyncWithTimeout:(CFTimeInterval)seconds
                         block:(_Nullable GREYExecBlock)execBlock
                         error:(__strong NSError *_Nullable *_Nullable)errorOrNil;

@end

NS_ASSUME_NONNULL_END

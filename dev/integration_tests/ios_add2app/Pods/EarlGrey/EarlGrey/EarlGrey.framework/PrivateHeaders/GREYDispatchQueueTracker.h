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
 *  A dispatch queue tracker for tracking dispatch queues.
 *
 *  At most one tracker exists for each dispatch queue. The tracker will continue tracking the
 *  dispatch queue until the tracker or the tracker's underlying queue has been deallocated.
 */
@interface GREYDispatchQueueTracker : NSObject

/**
 *  Returns a tracker tracking @c queue. Creates a tracker only if one does not already exist.
 *
 *  The tracked queue is held weakly so that it can be deallocated normally. The tracker will track
 *  the busy state of "zombie" queues that have been released by all external references but still
 *  have enqueued tasks that hold references to the queue.
 *
 *  @param queue The queue that the returned tracker should be tracking.
 *
 *  @return A tracker tracking @c queue.
 */
+ (instancetype)trackerForDispatchQueue:(dispatch_queue_t)queue;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Check for the idle state of the tracked dispatch queue.
 *
 *  The tracked dispatch queue is considered busy if a tracked operation has not yet completed.
 *  @c dispatch_sync blocks and dispatch_sync_f tasks sent to @c queue are tracked.
 *  @c dispatch_async blocks and @c dispatch_async_f tasks sent to @c queue are tracked.
 *  @c dispatch_after blocks and @c dispatch_after_f tasks sent to @c queue are tracked if they are
 *  delayed no more than the delay amount set for the
 *  @c kGREYConfigKeyTrackableDispatchAfterDuration configuration.
 *
 *  @return @c YES if the dispatch queue being tracked is idle, @c NO otherwise.
 */
- (BOOL)isIdleNow;

/**
 *  Check if the tracked queue still has external references.
 *
 *  After all external references to a queue have been dropped, asynchronous tasks on the dispatch
 *  queue will still complete and the tracker will still report that it is busy until those tasks
 *  have completed. When the queue is only kept active by enqueued blocks, it is considered to be a
 *  zombie queue and not a live queue.
 *
 *  @return @c YES if the dispatch queue being tracked no longer has external references, @c NO
 *          otherwise.
 */
- (BOOL)isTrackingALiveQueue;

@end

NS_ASSUME_NONNULL_END

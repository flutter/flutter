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

#import <EarlGrey/GREYIdlingResource.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Idling resource that tracks blocks sent to a dispatch queue.
 */
@interface GREYDispatchQueueIdlingResource : NSObject<GREYIdlingResource>

/**
 *  Creates an idling resource backed by the specified @c queue.
 *
 *  @c dispatch_sync blocks and dispatch_sync_f tasks sent to @c queue are tracked.
 *  @c dispatch_async blocks and @c dispatch_async_f tasks sent to @c queue are tracked.
 *  @c dispatch_after blocks and @c dispatch_after_f tasks sent to @c queue are tracked if they are
 *  delayed no more than the delay amount set for the
 *  @c kGREYConfigKeyTrackableDispatchAfterDuration configuration. A weak reference is held to
 *  @c queue. If @c queue is deallocated, then the idling resource will deregister itself from the
 *  UI thread executor.
 *
 *  @param queue The dispatch queue that will be tracked by the resource.
 *  @param name  A descriptive name for the idling resource.
 *
 *  @return An idling resource backed by the specified dispatch queue.
 */
+ (instancetype)resourceWithDispatchQueue:(dispatch_queue_t)queue name:(NSString *)name;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

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
 *  Idling resource that monitors operation queues.
 */
@interface GREYOperationQueueIdlingResource : NSObject<GREYIdlingResource>

/**
 *  Creates an idling resource for monitoring @c queue for idleness.
 *  A queue is considered idle when it has no pending operations.
 *  A weak reference is held to @c queue. If @c queue is deallocated, then the idling resource will
 *  deregister itself from the UI thread executor.
 *
 *  @param queue The queue that will be tracked by the resource.
 *  @param name  A descriptive name for the idling resource.
 *
 *  @return Returns an idling resource for the specified NSOperationQueue.
 */
+ (instancetype)resourceWithNSOperationQueue:(NSOperationQueue *)queue name:(NSString *)name;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

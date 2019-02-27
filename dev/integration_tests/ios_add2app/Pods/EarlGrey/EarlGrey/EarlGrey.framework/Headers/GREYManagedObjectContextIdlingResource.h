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

@class NSManagedObjectContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * Idling resource that tracks core data managed object context operations.
 *
 * Tracks the managed object context's internal operation queue and optionally any pending changes
 * yet to be committed.
 */
@interface GREYManagedObjectContextIdlingResource : NSObject<GREYIdlingResource>

/**
 *  Creates an idling resource tracking @c managedObjectContext.
 *
 *  A weak reference is held to @c managedObjectContext. If @c managedObjectContext is deallocated,
 *  then the idling resource will deregister itself from the thread executor.
 *
 *  @param managedObjectContext The managed object context to be tracked by the resource.
 *  @param trackPendingChanges  If @c YES, then the idling resource will report that it is busy
 *                              when the managed object context has pending changes.
 *  @param name                 A descriptive name for the idling resource.
 *
 *  @return An idling resource tracking @c managedObjectContext.
 */
+ (instancetype)resourceWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                             trackPendingChanges:(BOOL)trackPendingChanges
                                            name:(NSString *)name;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

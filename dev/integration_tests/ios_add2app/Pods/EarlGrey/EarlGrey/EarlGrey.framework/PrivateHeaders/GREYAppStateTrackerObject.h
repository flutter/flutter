//
// Copyright 2017 Google Inc.
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

#import "Synchronization/GREYAppStateTracker.h"

NS_ASSUME_NONNULL_BEGIN

@class GREYObjectDeallocationTracker;

/**
 *  Class used by the GREYAppStateTracker for synchronization purposes.
 */
@interface GREYAppStateTrackerObject : NSObject

/**
 *  Initializing the GREYAppStateTrackerObject.
 *
 *  @param deallocationTracker The object that will be pointed to using a weak reference.
 *
 *  @return An instance of GREYAppStateTrackerObject.
 */
- (instancetype)initWithDeallocationTracker:(GREYObjectDeallocationTracker *)deallocationTracker;

/**
 *  @remark init is not an available initializer. Use the other initializer.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  @c object is an instance of GREYObjectDeallocatingTracker aka the internal object. The
 *  GREYAppStateTrackerObject holds weakly to the GREYObjectDeallocatingTracker object.
 */
@property(nonatomic, readonly, weak) GREYObjectDeallocationTracker *object;

/**
 *  The state that this object is tracking.
 */
@property(nonatomic, assign) GREYAppState state;

/**
 *  The description of the object that is being represented by GREYAppStateTrackerObject.
 */
@property(nonatomic, strong) NSString *objectDescription;

/**
 *  @return The callstack that was set when a new state @c state was set.
 */
- (NSArray<NSString *> *)stateAssignmentCallStack;

@end

NS_ASSUME_NONNULL_END

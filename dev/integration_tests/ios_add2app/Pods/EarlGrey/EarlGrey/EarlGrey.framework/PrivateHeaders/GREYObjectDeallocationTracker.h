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

@class GREYObjectDeallocationTracker;

NS_ASSUME_NONNULL_BEGIN

@protocol GREYObjectDeallocationTrackerDelegate <NSObject>

/**
 *  Delegate method that is called when the GREYObjectDeallocationTracker is deallocated.
 *
 *  @param objectDeallocationTracker The GREYObjectDeallocationTracker instance that is being
 *                                   deallocated.
 */
-(void)objectTrackerDidDeallocate:(GREYObjectDeallocationTracker *)objectDeallocationTracker;

@end

@interface GREYObjectDeallocationTracker : NSObject

/**
 *  Initialize the GREYObjectDeallocationTracker with a delegate object.
 *
 *  @param object   The object that should be tracked by the GREYObjectDeallocationTracker.
 *  @param delegate The object that conforms to the GREYObjectDeallocationTrackerDelegate protocol
 *                  and wants to receive the delegate callback.
 */
- (instancetype)initWithObject:(id)object
                      delegate:(id<GREYObjectDeallocationTrackerDelegate> _Nullable)delegate;

/**
 *  @remark init is not an available initializer. Use the other initializer.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Finds the GREYObjectDeallocationTracker associated with the @c object if one exists. Call this
 *  method if the @c object is already being tracked by an instance of
 *  GREYObjectDeallocationTracker.
 *
 *  @param object The object that the GREYObjectDeallocationTracker is tracking.
 *
 *  @return An instance of GREYObjectDeallocationTracker or nil if object's deallocation isn't
 *          being tracked.
 */
+ (GREYObjectDeallocationTracker * _Nullable)deallocationTrackerRegisteredWithObject:(id)object;

@end

NS_ASSUME_NONNULL_END

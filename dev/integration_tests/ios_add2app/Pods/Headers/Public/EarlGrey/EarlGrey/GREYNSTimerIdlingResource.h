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
 *  An idling resource to track NSTimer firing events so that the framework can synchronize
 *  with them.
 */
@interface GREYNSTimerIdlingResource : NSObject<GREYIdlingResource>

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates an idling resource that tracks the specified @c timer, causing actions to wait until
 *  the timer is fired or invalidated. If @c removeOnIdle is @c YES, the idling resource will
 *  automatically remove itself from the list of registered idling resources when it becomes idle.
 *
 *  @param timer        The timer that will be tracked by the idling resource.
 *  @param name         A descriptive name for the idling resource.
 *  @param removeOnIdle Defines whether the resource should unregister itself when it becomes idle.
 *
 *  @return A new and initialized GREYNSTimerIdlingResource instance.
 */
+ (instancetype)trackTimer:(NSTimer *)timer name:(NSString *)name removeOnIdle:(BOOL)removeOnIdle;

@end

NS_ASSUME_NONNULL_END

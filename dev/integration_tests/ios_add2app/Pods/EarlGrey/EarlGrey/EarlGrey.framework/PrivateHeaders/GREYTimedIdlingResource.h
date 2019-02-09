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
 *  An idling resource that changes to busy state for a specified amount of time.
 */
@interface GREYTimedIdlingResource : NSObject<GREYIdlingResource>

/**
 *  An idling resouce for any @c object whose idleness is time-dependent. The resource reports
 *  busy until @c seconds has elapsed.
 *
 *  This idling resource self-registers with GREYUIThreadExecutor on creation and deregisters when
 *  it idles or is forcefully stopped using GREYTimedIdlingResource::stopMonitoring.
 *
 *  @param object  The object to monitor.
 *  @param seconds The amount of time after which object will be in idle state.
 *  @param name    A descriptive name for the idling resource.
 *
 *  @return A new idling resource instance for @c object.
 */
+ (instancetype)resourceForObject:(NSObject *)object
            thatIsBusyForDuration:(CFTimeInterval)seconds
                             name:(NSString *)name;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Forcefully stops monitoring.
 *  Subsequent invocations to GREYIdlingResource::isIdleNow return @c YES.
 */
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END

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

@protocol GREYAnalyticsDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Provides methods for tracking EarlGrey usage using Google Analytics.
 *
 *  @remark To opt out of Analytics use GREYConfiguration and set config value for
 *          @c kGREYConfigKeyAnalyticsEnabled to @c NO before the instance tear down method
 *          XCTestCase::tearDown method returns. Sample code to opt out of analytics:
 *          @code
 *          [[GREYConfiguration sharedInstance] setValue:@(NO)
 *                                          forConfigKey:kGREYConfigKeyAnalyticsEnabled];
 *          @endcode
 */
@interface GREYAnalytics : NSObject

/**
 *  @return The singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 *  @return The current delegate.
 */
- (id<GREYAnalyticsDelegate>)delegate;

/**
 *  Sets a delegate for custom handling of analytics payload data. To reset GREYAnalytics to its
 *  default behavior pass @c nil.
 */
- (void)setDelegate:(id<GREYAnalyticsDelegate>)delegate;

/**
 *  Called when an EarlGrey invocation occurs using any @code [EarlGrey XXX] @endcode statements.
 */
- (void)didInvokeEarlGrey;

/**
 *  Sends an Analytics Event hit based on protocol specified in:
 *  @see https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#event
 *
 *  @param trackingID The tracking ID under which to track this event.
 *  @param clientID   The ID for the user sending this event.
 *  @param category   The Event Category for the event hit.
 *  @param action     The Event Action for the event hit.
 *  @param value      The event value for the event hit.
 */
+ (void)sendEventHitWithTrackingID:(NSString *)trackingID
                          clientID:(NSString *)clientID
                          category:(NSString *)category
                            action:(NSString *)action
                             value:(NSString *)value;

@end

NS_ASSUME_NONNULL_END

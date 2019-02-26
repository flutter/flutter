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
 *  A protocol for resources that can potentially modify the UI and should be synchronized with
 *  before performing any interaction or verification with UI element.
 */
@protocol GREYIdlingResource<NSObject>

/**
 *  A method to query idleness of this resource.
 *
 *  Note: This method is called on the main thread and polled continuously until this resource goes
 *  into idle state or a test timeout occurs. It is discouraged to perform any heavy tasks in this
 *  method.
 *
 *  @return @c YES if the resource is currently idle; @c NO otherwise.
 */
- (BOOL)isIdleNow;

/**
 *  @return A user friendly name that will be printed if this resource fails to idle leading to a
 *          test timeout.
 */
- (NSString *)idlingResourceName;

/**
 *  @return Information that will be printed alongside the name if this resource fails to idle in
 *          the given timeout.
 */
- (NSString *)idlingResourceDescription;

@end

NS_ASSUME_NONNULL_END

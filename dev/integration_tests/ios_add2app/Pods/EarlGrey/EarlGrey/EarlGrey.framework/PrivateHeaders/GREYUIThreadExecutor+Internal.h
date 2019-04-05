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

/**
 *  @file  GREYUIThreadExecutor+Internal.h
 *  @brief Exposes GREYUIThreadExecutor interfaces and methods that are otherwise private for
 *         testing purposes.
 */

#import <EarlGrey/GREYUIThreadExecutor.h>

@protocol GREYIdlingResource;

NS_ASSUME_NONNULL_BEGIN

@interface GREYUIThreadExecutor (Internal)

/**
 *  Register the specified @c resource to be checked for idling before executing test actions.
 *  A strong reference is held to @c resource until it is deregistered using
 *  @c deregisterIdlingResource. It is safe to call this from any thread.
 *
 *  @param resource The idling resource to register.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (void)registerIdlingResource:(id<GREYIdlingResource>)resource;

/**
 *  Unregisters a previously registered @c resource. It is safe to call this from any thread.
 *
 *  @param resource The resource to unregistered.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (void)deregisterIdlingResource:(id<GREYIdlingResource>)resource;

@end

NS_ASSUME_NONNULL_END

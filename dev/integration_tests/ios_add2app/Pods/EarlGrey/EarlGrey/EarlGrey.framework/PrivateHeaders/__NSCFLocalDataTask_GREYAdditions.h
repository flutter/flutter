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
 *  Additions to NSURLSessionTask to allow EarlGrey to track status for every network request. By
 *  default EarlGrey tracks all URLs. To change this behavior, add blacklisted URL regex's to
 *  @c GREYConfiguration with key @c kGREYConfigKeyURLBlacklistRegex.
 */
@interface __NSCFLocalDataTask_GREYAdditions : NSObject

/**
 *  Tracks the network task so that EarlGrey waits for its completion.
 */
- (void)grey_track;

/**
 *  Un-tracks the network task so that EarlGrey does not wait for it anymore.
 */
- (void)grey_untrack;

/**
 *  Marks the network task as an ignored request so that EarlGrey does not wait on it.
 */
- (void)grey_neverTrack;

@end

NS_ASSUME_NONNULL_END

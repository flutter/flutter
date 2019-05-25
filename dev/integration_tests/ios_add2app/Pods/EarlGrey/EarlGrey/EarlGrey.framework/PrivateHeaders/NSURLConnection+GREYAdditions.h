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
 *  Additions to NSURLConnection to allow EarlGrey to track status for every connection. By
 *  default, EarlGrey tracks all NSURLConnection's, to change this behavior update GREYConfiguration
 *  setting with @c kGREYConfigKeyURLBlacklistRegex key.
 */
@interface NSURLConnection (GREYAdditions)

/**
 *  Tracks the current connection as pending in GREYAppStateTracker.
 */
- (void)grey_trackPending;

/**
 *  Untracks the current connection from GREYAppStateTracker, marking it as completed.
 */
- (void)grey_untrackPending;

@end

NS_ASSUME_NONNULL_END

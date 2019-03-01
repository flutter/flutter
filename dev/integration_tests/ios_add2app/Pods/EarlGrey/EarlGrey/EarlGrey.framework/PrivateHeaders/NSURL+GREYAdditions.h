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

@interface NSURL (GREYAdditions)

/**
 *  Add @c regEx to the list of framework blacklisted URLs.
 *
 *  @param regEx A regular expression representing a URL to blacklist from the tracking system.
 */
+ (void)grey_addBlacklistRegEx:(NSString *)regEx;

/**
 *  @return @c YES if EarlGrey must synchronize with this url, @c NO otherwise.
 */
- (BOOL)grey_shouldSynchronize;

@end

NS_ASSUME_NONNULL_END

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
 *  EarlGrey specific additions to NSString.
 */
@interface NSString (GREYAdditions)

/**
 *  Returns @c YES if the current string is @b not an empty string (length = 0) after being trimmed
 *  for whitespaces and newline characters.
 *  @remark Since it is valid to send this message to @c nil instances, we use @c isNonEmpty instead
 *          of @c isEmpty to return a valid result (@c NO).
 *
 *  @return @c NO if current string is empty, @c YES otherwise.
 */
- (BOOL)grey_isNonEmptyAfterTrimming;

/**
 *  @return A string with the MD5 hash of the given input @c string.
 */
- (NSString *)grey_md5String;

@end

NS_ASSUME_NONNULL_END

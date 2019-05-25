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
 *  @file GREYScreenshotUtil+Internal.h
 *  @brief Exposes GREYScreenshotUtil' interfaces and methods that are otherwise private
 *  for testing purposes.
 */

#import <EarlGrey/GREYScreenshotUtil.h>

NS_ASSUME_NONNULL_BEGIN

@interface GREYScreenshotUtil (Internal)

/**
 *  Provides a UIImage that is a screenshot, immediately or after the screen updates as specified.
 *
 *  @param afterScreenUpdates A Boolean specifying if the screenshot is to be taken immediately or
 *                            after a screen update.
 *
 *  @return A UIImage containing a screenshot.
 *
 *  @remark This is available only for internal testing purposes.
 */
+ (UIImage *)grey_takeScreenshotAfterScreenUpdates:(BOOL)afterScreenUpdates;

@end

NS_ASSUME_NONNULL_END

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

@interface GREYFailureScreenshotter : NSObject

/**
 *  Generate app screenshot with given prefix and failure name.
 *
 *  @param screenshotPrefix  Prefix for the screenshots.
 *  @param failureName       Failure name associated with the screenshots.
 *
 *  @return A dictionary of the screenshot names and their corresponding paths.
 */

+ (NSDictionary *)generateAppScreenshotsWithPrefix:(NSString *_Nullable)screenshotPrefix
                                           failure:(NSString *)failureName;

/**
 *  Generate app screenshot with given prefix and failure name.
 *
 *  @param screenshotPrefix  Prefix for the screenshots.
 *  @param failureName       Failure name associated with the screenshots.
 *  @param screenshotDir     The screenshot directory where the screenshots are placed.
 *
 *  @return A dictionary of the screenshot names and their corresponding paths.
 */
+ (NSDictionary *)generateAppScreenshotsWithPrefix:(NSString *_Nullable)screenshotPrefix
                                           failure:(NSString *)failureName
                                     screenshotDir:(NSString *)screenshotDir;

@end

NS_ASSUME_NONNULL_END

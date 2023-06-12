// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FLTAdUtil.h"
#import "FLTConstants.h"

@implementation FLTAdUtil

static NSString *_requestAgent;

+ (BOOL)isNull:(id)object {
  return object == nil || [[NSNull null] isEqual:object];
}

+ (BOOL)isNotNull:(id)object {
  return ![FLTAdUtil isNull:object];
}

+ (NSString *)requestAgent {
  NSString *newsTemplateString = @"";
  id newsTemplateVersion = [NSBundle.mainBundle
      objectForInfoDictionaryKey:@"FLTNewsTemplateVersion"];
  if ([newsTemplateVersion isKindOfClass:[NSString class]]) {
    newsTemplateString =
        [NSString stringWithFormat:@"_News-%@", newsTemplateVersion];
  }

  NSString *gameTemplateString = @"";
  id gameTemplateVersion = [NSBundle.mainBundle
      objectForInfoDictionaryKey:@"FLTGameTemplateVersion"];
  if ([gameTemplateVersion isKindOfClass:[NSString class]]) {
    gameTemplateString =
        [NSString stringWithFormat:@"_Game-%@", gameTemplateVersion];
  }
  return [NSString stringWithFormat:@"%@%@%@", FLT_REQUEST_AGENT_VERSIONED,
                                    newsTemplateString, gameTemplateString];
}

@end

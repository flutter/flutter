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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Additions for the UISwitch class.
 */
@interface UISwitch (GREYAdditions)

/**
 *  @param onState The specified switch state.
 *
 *  @return A string representation of the specified switch state.
 */
+ (NSString *)grey_stringFromOnState:(BOOL)onState;

@end

NS_ASSUME_NONNULL_END

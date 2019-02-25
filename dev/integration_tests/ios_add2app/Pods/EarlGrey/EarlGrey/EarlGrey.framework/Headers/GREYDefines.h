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
 *  @file GREYDefines.h
 *  @brief Miscellaneous defines and macros for EarlGrey.
 */

#import <UIKit/UIKit.h>

#ifndef GREY_DEFINES_H
#define GREY_DEFINES_H

#define GREY_EXPORT FOUNDATION_EXPORT __used
#define GREY_EXTERN FOUNDATION_EXTERN
#define GREY_UNUSED_VARIABLE __attribute__((unused))

#define iOS8_0_OR_ABOVE() ([UIDevice currentDevice].systemVersion.doubleValue >= 8.0)
#define iOS8_1_OR_ABOVE() ([UIDevice currentDevice].systemVersion.doubleValue >= 8.1)
#define iOS8_2_OR_ABOVE() ([UIDevice currentDevice].systemVersion.doubleValue >= 8.2)
#define iOS9_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 9)
#define iOS10_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 10)
#define iOS11_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 11)

#pragma mark - Math

/**
 *  @return The smallest @c int following the @c double @c x. This macro is needed to avoid
 *          rounding errors when "modules" project setting is enabled causing math functions to
 *          map from tgmath.h to math.h.
 */
#define grey_ceil(x) ((CGFloat)ceil(x))

/**
 *  @return The largest @c int less than the @c double @c x. This macro is needed to avoid
 *          rounding errors when "modules" project setting is enabled causing math functions to
 *          map from tgmath.h to math.h.
 */
#define grey_floor(x) ((CGFloat)floor(x))

#endif  // GREY_DEFINES_H

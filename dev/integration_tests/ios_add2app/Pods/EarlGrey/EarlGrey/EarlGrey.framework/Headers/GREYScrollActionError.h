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

#import <EarlGrey/GREYDefines.h>

/**
 *  The Error domain for a scroll error.
 */
GREY_EXTERN NSString *const kGREYScrollErrorDomain;

/**
 *  Error codes for scrolling related errors.
 */
typedef NS_ENUM(NSInteger, GREYScrollErrorCode) {
  /**
   *  Reached content edge before the entire scroll action was complete.
   */
  kGREYScrollReachedContentEdge,
  /**
   *  It is not possible to scroll.
   */
  kGREYScrollImpossible,
  /**
   *  Could not scroll to the element we are looking for.
   */
  kGREYScrollToElementFailed,
};

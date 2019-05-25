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
 *  Umbrella public header for the EarlGrey framework.
 *
 *  Instead of importing individual headers, import this header using:
 *  @code
 *    @import EarlGrey;  // if your project uses modules
 *  @endcode
 *    OR if your project doesn't use modules:
 *  @code
 *    #import <EarlGrey/EarlGrey.h>
 *  @endcode
 *
 *  To learn more, check out: http://github.com/google/EarlGrey
 */

#import <Foundation/Foundation.h>

#import <EarlGrey/GREYAction.h>
#import <EarlGrey/GREYActionBlock.h>
#import <EarlGrey/GREYActions.h>
#import <EarlGrey/GREYBaseAction.h>
#import <EarlGrey/GREYScrollActionError.h>
#import <EarlGrey/GREYIdlingResource.h>
#import <EarlGrey/GREYAssertion.h>
#import <EarlGrey/GREYAssertionBlock.h>
#import <EarlGrey/GREYAssertionDefines.h>
#import <EarlGrey/GREYAssertions.h>
#import <EarlGrey/GREYConfiguration.h>
#import <EarlGrey/GREYConstants.h>
#import <EarlGrey/GREYDefines.h>
#import <EarlGrey/GREYElementHierarchy.h>
#import <EarlGrey/GREYScreenshotUtil.h>
#import <EarlGrey/GREYTestHelper.h>
#import <EarlGrey/EarlGreyImpl.h>
#import <EarlGrey/GREYElementFinder.h>
#import <EarlGrey/GREYElementInteraction.h>
#import <EarlGrey/GREYInteraction.h>
#import <EarlGrey/GREYFailureHandler.h>
#import <EarlGrey/GREYFrameworkException.h>
#import <EarlGrey/GREYAllOf.h>
#import <EarlGrey/GREYAnyOf.h>
#import <EarlGrey/GREYBaseMatcher.h>
#import <EarlGrey/GREYDescription.h>
#import <EarlGrey/GREYElementMatcherBlock.h>
#import <EarlGrey/GREYLayoutConstraint.h>
#import <EarlGrey/GREYMatcher.h>
#import <EarlGrey/GREYMatchers.h>
#import <EarlGrey/GREYNot.h>
#import <EarlGrey/GREYDataEnumerator.h>
#import <EarlGrey/GREYProvider.h>
#import <EarlGrey/GREYCondition.h>
#import <EarlGrey/GREYDispatchQueueIdlingResource.h>
#import <EarlGrey/GREYManagedObjectContextIdlingResource.h>
#import <EarlGrey/GREYNSTimerIdlingResource.h>
#import <EarlGrey/GREYOperationQueueIdlingResource.h>
#import <EarlGrey/GREYSyncAPI.h>
#import <EarlGrey/GREYUIThreadExecutor.h>

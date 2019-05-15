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

#import <EarlGrey/GREYAction.h>

@protocol GREYMatcher;

NS_ASSUME_NONNULL_BEGIN

/**
 *  A base class for all actions that incorporates commonalities between initialization
 *  parameters and constraint checking.
 */
@interface GREYBaseAction : NSObject<GREYAction>

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  The designated initializer for a base action with the provided @c constraints.
 *
 *  @param name        The name of the GREYAction being performed.
 *
 *  @param constraints The constraints to be satisified by the element before the
 *                     action is performed.
 *
 *  @return An instance of GREYBaseAction, initialized with the @c constraints for it to check for.
 */
- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints NS_DESIGNATED_INITIALIZER;

/**
 *  A method that checks that @c element satisfies @c constraints this action was initialized with.
 *  Subclasses should call this method if they want to check for constraints in their perform:error:
 *  implementation.
 *
 *  @param      element       A UI element being checked for the @c constraints.
 *  @param[out] errorOrNilPtr Error stored when an element did not satisfy the @c constraints.
 *                            If an error is set but this pointer is @c nil,
 *                            then an action failed exception is thrown.
 *
 *  @throws GREYFrameworkException if constraints fail and @c errorOrNilPtr is not provided.
 *
 *  @return @c YES if the constraints are satisfied on the element. @c NO otherwise.
 */
- (BOOL)satisfiesConstraintsForElement:(id)element error:(__strong NSError **)errorOrNilPtr;

@end

NS_ASSUME_NONNULL_END


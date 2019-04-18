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

#import <EarlGrey/GREYBaseAction.h>

@protocol GREYMatcher;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Block type for defining the action's 'perform' code.
 *
 *  @param      element    The element on which the block is going to be performed.
 *  @param[out] errorOrNil The error set on failure. The error returned can be @c nil, signifying
 *                         that the action succeeded.
 *
 *  @throws NSException when there is a failure and @c errorOrNil is not provided
 *          (i.e. it is @c nil).
 *
 *  @return @c YES if the action performed succeeded, else @c NO.
 */
typedef BOOL (^GREYPerformBlock)(id element, __strong NSError *_Nullable *errorOrNil);

/**
 *  A class for creating block based GREYAction.
 */
@interface GREYActionBlock : GREYBaseAction

/**
 *  Creates a GREYAction that performs the action in the provided @c block.
 *
 *  @param name  The name of the action
 *  @param block A block that contains the action to execute.
 *
 *  @return A GREYActionBlock instance with the given name.
 */
+ (instancetype)actionWithName:(NSString *)name performBlock:(GREYPerformBlock)block;

/**
 *  Creates a GREYAction that performs the action in the provided @c block subject to the
 *  provided @c constraints.
 *
 *  @param name         The name of the action.
 *  @param constraints  Constraints that must be satisfied before the action is performed
 *                      This is optional and can be @c nil.
 *  @param block        A block that contains the action to execute.
 *
 *  @return A GREYActionBlock instance with the given name and constraints.
 */
+ (instancetype)actionWithName:(NSString *)name
                   constraints:(id<GREYMatcher> _Nullable)constraints
                  performBlock:(GREYPerformBlock)block;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  @remark initWithName::constraints: is overridden from its superclass.
 */
- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints NS_UNAVAILABLE;

/**
 *  Designated Initializer.
 *
 *  @param name         The name of the action.
 *  @param constraints  Constraints that must be satisfied before the action is performed
 *                      This is optional and can be @c nil.
 *  @param block        A block that contains the action to execute.
 *
 *  @return A GREYActionBlock instance with the given name and constraints.
 */
- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher> _Nullable)constraints
                performBlock:(GREYPerformBlock)block NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

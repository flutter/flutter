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
 *  A protocol for actions that are performed on accessibility elements.
 */
@protocol GREYAction<NSObject>

/**
 *  Perform the action specified by the GREYAction object on an @c element if and only if the
 *  @c element matches the constraints of the action.
 *
 *  @param      element    The element the action is to be performed on. This must not be @c nil.
 *  @param[out] errorOrNil Error that will be populated on failure. The implementing class should
 *                         handle the behavior when it is @c nil by, for example, logging the error
 *                         or throwing an exception.
 *
 *  @return @c YES if the action succeeded, else @c NO. If an action returns @c NO, it does not
 *          mean that the action was not performed at all but somewhere during the action execution
 *          the error occurred and so the UI may be in an unrecoverable state.
 */
- (BOOL)perform:(id)element error:(__strong NSError *_Nullable *)errorOrNil;

/**
 *  A method to get the name of this action.
 *
 *  @return The name of the action. If the action fails, then the name is printed along with all
 *          other relevant information.
 */
- (NSString *)name;

@end

NS_ASSUME_NONNULL_END

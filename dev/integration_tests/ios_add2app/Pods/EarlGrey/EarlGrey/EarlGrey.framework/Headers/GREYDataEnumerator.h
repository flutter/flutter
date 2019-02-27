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
 *  An block-based enumerator that repeatedly invokes the block to return the next object.
 */
@interface GREYDataEnumerator : NSEnumerator

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Instantiates the enumerator with custom information and a block to return the next object.
 *
 *  @param userInfo        Custom object that is passed into the block. Use this for passing any
 *                         additional information required by the block.
 *  @param nextObjectBlock A block that is invoked to return the next object in the enumerator.
 *
 *  @return An instance of GREYDataEnumerator, initialized with the specified information.
 */
- (instancetype)initWithUserInfo:(id)userInfo
                           block:(id(^)(id))nextObjectBlock NS_DESIGNATED_INITIALIZER;

#pragma mark - NSEnumerator

/**
 *  @return The next object in the enumerator returned by the @c nextObjectBlock.
 */
- (id _Nullable)nextObject;
/**
 *  @return An array of all the objects in the enumerator.
 */
- (NSArray *)allObjects;

@end

NS_ASSUME_NONNULL_END

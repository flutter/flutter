//
// Copyright 2017 Google Inc.
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

#import "Traversal/GREYTraversal.h"

NS_ASSUME_NONNULL_BEGIN

@interface GREYTraversalDFS : GREYTraversal

/**
 *  Instance method that returns the next object from the hierarchy in a Depth First Search fashion.
 *
 *  @return An instance of the UI element that is next in the hierarchy.
 */
- (id _Nullable)nextObject;

/**
 *  Class method to initialize the object. The hierarchy is unrolled in a DFS fashion and
 *  an internal represenation is created.
 *
 *  @param element Single UI element whose UI hierarchy needs to be unrolled.
 *
 *  @return An instance of the GREYTraversalDFS class.
 */
+ (instancetype)hierarchyForElementWithDFSTraversal:(id)element;

/**
 *  Enumerates through the entire hierarchy and calls the @c block on each element in the hierarchy.
 *  This method enumerates through the hierarchy only once.
 *
 *  @param block A completion block that will be invoked on each element.
 */
- (void)enumerateUsingBlock:(void (^)(id view, NSUInteger level))block;

@end

NS_ASSUME_NONNULL_END

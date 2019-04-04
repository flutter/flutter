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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A private wrapper used to store information that is essential for printing the UI hierarchy
 *  appropriately and in correct order.
 */
@interface GREYTraversalObject : NSObject

/**
 *  An NSUInteger representing the number of parent-child relationships from the root element
 *  to the current element.
 */
@property(nonatomic) NSUInteger level;

/**
 *  The UI element that the GREYHierarchyObject is wrapped around.
 */
@property(nonatomic, strong) id element;

@end

/**
 *  Private class to traverse the UI Hierarchy.
 *  Provides helper methods to access the various elements present in the hierarchy.
 */
@interface GREYTraversal : NSObject

/**
 *  Instance method that returns the next object from the hierarchy. Needs to be implemented by
 *  subclasses. This class provides an empty implementation.
 *
 *  @return An instance of the UI element that is next in the hierarchy.
 */
- (id _Nullable)nextObject NS_UNAVAILABLE;

/**
 *  Explores the immediate children of the @c element that is passed in.
 *
 *  @param element The UI element whose children are to be explored.
 *
 *  @return Creates a new array that contains the immediate children of @c element. The children are
 *          ordered from front to back, meaning subviews that were added first are present later
 *          in the array. If no children exist, then an empty array is returned.
 */
- (NSArray *)exploreImmediateChildren:(id)element;

@end

NS_ASSUME_NONNULL_END

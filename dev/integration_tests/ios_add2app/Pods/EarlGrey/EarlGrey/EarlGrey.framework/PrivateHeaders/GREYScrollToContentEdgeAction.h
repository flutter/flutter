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
#import <EarlGrey/GREYConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A GREYAction that implements a scroll action that scrolls the contents of the matched
 *  UIScrollView to the given edge of its contents.
 */
@interface GREYScrollToContentEdgeAction : GREYBaseAction

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
 *  Creates a scroll action that scrolls to the given @c edge of the contents in the selected
 *  scroll view.
 *
 *  @param edge The edge of the UIScrollView to scroll the contents.
 *
 *  @return An instance of GREYScrollToContentEdgeAction, initialized with the provided @c edge.
 */
- (instancetype)initWithEdge:(GREYContentEdge)edge;

/**
 *  Creates a scroll action that scrolls to the given @c edge of the contents in the selected
 *  scroll view with the start point specified by @c startPointPercents.
 *
 *  @param edge               The edge of the UIScrollView to scroll the contents.
 *  @param startPointPercents The start point of the scroll specified as percents (0, 1) exclusive,
 *                            in the visible area of the scroll view or as @c NAN to pick a point
 *                            that provides maximum scroll length.
 *
 *  @return An instance of GREYScrollToContentEdgeAction, initialized with the provided @c edge.
 */
- (instancetype)initWithEdge:(GREYContentEdge)edge
          startPointPercents:(CGPoint)startPointPercents NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

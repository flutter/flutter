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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Additions to NSObject for obtaining details for UI and Accessibility Elements.
 */
@interface NSObject (GREYAdditions)

/**
 *  Traverses up the accessibility tree and returns the immediate ancestor UIView or @c nil if none
 *  exists.
 *  @remark In the case of web accessibility elements the container web view is returned instead.
 *
 *  @return The containing UIView object or @c nil if none was found.
 */
- (UIView *)grey_viewContainingSelf;

/**
 *  @return The direct container of the element or @c nil if the element has no container.
 */
- (id)grey_container;

/**
 *  Traverses up the element hierarchy returning all containers of type @c klass. When called on a
 *  non-UIView accessibility element, the accessibility container tree is traversed until the first
 *  UIView is encountered, at which point it switches to traversing the view hierarchy.
 *
 *  @param klass The class the container being searched for.
 *
 *  @return An array of all container objects.
 */
- (NSArray *)grey_containersAssignableFromClass:(Class)klass;

/**
 *  @return The element's accessibilityActivationPoint converted to window coordinates.
 */
- (CGPoint)grey_accessibilityActivationPointInWindowCoordinates;

/**
 *  @return The element's accessibility point relative to its accessibility frame's origin.
 */
- (CGPoint)grey_accessibilityActivationPointRelativeToFrame;

/**
 *  @return @c YES if @c self is an accessibility element within a UIWebView, @c NO otherwise.
 */
- (BOOL)grey_isWebAccessibilityElement;

/**
 *  @return A detailed description of the element, including accessibility attributes.
 */
- (NSString *)grey_description;

/**
 *  @return A short description of the element, including its class, accessibility ID and label.
 */
- (NSString *)grey_shortDescription;

/**
 *  @return The recursive description of the UI hierarchy for the current element. This should be
 *          used only with objects that are UIViews or UIAccessibilityElements.
 */
- (NSString *)grey_recursiveDescription;

/**
 *  Swizzle a selector with a particular object after a specified delay time interval in a
 *  specific run loop mode.
 *
 *  @param aSelector  The selector to be swizzled.
 *  @param anArgument The object to swizzle the selector with.
 *  @param delay      The NSTimeInterval after which the swizzling is to be done.
 *  @param modes      The run loop mode to perform the swizzling in.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (void)greyswizzled_performSelector:(SEL)aSelector
                          withObject:(id)anArgument
                          afterDelay:(NSTimeInterval)delay
                             inModes:(NSArray *)modes;

@end

NS_ASSUME_NONNULL_END

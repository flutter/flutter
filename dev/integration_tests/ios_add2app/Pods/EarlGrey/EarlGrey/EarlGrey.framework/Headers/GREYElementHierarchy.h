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
 *  A utility to get the string representation of the UI hierarchy.
 */
@interface GREYElementHierarchy : NSObject

/**
 *  Returns UI hierarchy with @c element as the root. @c element can be either a UIView or an
 *  Accessibility element.
 *
 *  @param element The root element for the hierarchy.
 *
 *  @return The UI hierarchy as a string.
 */
+ (NSString *)hierarchyStringForElement:(id)element;

/**
 *  Similar to hierarchyStringForElement: with additional parameters for providing annotations
 *  for printed views. @c annotationDictionary is a dictionary of type
 *  @code @{[NSValue valueWithNonretainedObject:id]:NSString} @endcode with UI elements that
 *  require special formatting i.e. special text to be appended to the description. For example,
 *  @code @{viewA : @"This is a special view"} @endcode or
 *  @code @{elementA : @"This is a special view"} @endcode will have it's description as:
 *  @"<DESCRIPTION> This is a special view".
 *
 *  @param element              The root element for the hierarchy.
 *  @param annotationDictionary A dictionary of annotations.
 *
 *  @return The UI hierarchy as a string.
 */
+ (NSString *)hierarchyStringForElement:(id)element
               withAnnotationDictionary:(NSDictionary *_Nullable)annotationDictionary;

/**
 *  Returns the UI hierarchy for all @c UIWindows provided by the GREYUIWindowProvider.
 */
+ (NSString *)hierarchyStringForAllUIWindows;

@end

NS_ASSUME_NONNULL_END

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

#import <EarlGrey/GREYProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A provider for UI elements.
 */
@interface GREYElementProvider : NSObject<GREYProvider>

/**
 *  Class method to initialize this provider with the specified @c elements.
 *
 *  @param elements An array of elements that the provider is populated with.
 *
 *  @return An instance of GREYElementProvider populated with @c elements.
 */
+ (instancetype)providerWithElements:(NSArray *)elements;

/**
 *  Class method to initialize this provider with the specified @c rootElements.
 *
 *  @param rootElements An array of root elements whose entire hierarchy will populate the provider.
 *
 *  @return An instance of GREYElementProvider with root elements set to @c rootElements.
 */
+ (instancetype)providerWithRootElements:(NSArray *)rootElements;

/**
 *  Class method to initialize this provider with the specified @c rootProvider.
 *
 *  @param rootProvider A provider for root elements. The root elements and their entire hierarchy
 *                      will populate the current provider.
 *
 *  @return An instance of GREYElementProvider with root elements set root elements in the root
 *          provider and their entire hierarchy.
 */
+ (instancetype)providerWithRootProvider:(id<GREYProvider>)rootProvider;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes this provider with the specified @c elements.
 *
 *  @param elements Elements to populate the provider with.
 *
 *  @return An instance of GREYElementProvider populated with @c elements.
 */
- (instancetype)initWithElements:(NSArray *)elements;

/**
 *  Initializes this provider with the specified @c rootElements.
 *
 *  @param rootElements An array of root elements whose entire hierarchy will populate the provider.
 *
 *  @return An instance of GREYElementProvider with root elements set to @c rootElements.
 */
- (instancetype)initWithRootElements:(NSArray *)rootElements;

/**
 *  Initializes this provider with the specified @c rootProvider.
 *
 *  @param rootProvider A provider for root elements. The root elements and their entire hierarchy
 *                      will populate the current provider.
 *
 *  @return An instance of GREYElementProvider with root elements set root elements in the root
 *          provider and their entire hierarchy.
 */
- (instancetype)initWithRootProvider:(id<GREYProvider>)rootProvider;

/**
 *  Designated Initializer. Must provide exactly one @c non-nil parameter out of
 *  all the accepted parameters.
 *
 *  @param rootProvider A provider for root elements. The root elements and their entire hierarchy
 *                      will populate the current provider.
 *  @param rootElements An array of root elements whose entire hierarchy will populate the provider.
 *  @param elements     An array of elements that will populate the provider.
 *
 *  @return A GREYElementProviderInstance, initialized with at least one of the specified
 *          parameters.
 */
- (instancetype)initWithRootProvider:(id<GREYProvider> _Nullable)rootProvider
                      orRootElements:(NSArray *_Nullable)rootElements
                          orElements:(NSArray *_Nullable)elements NS_DESIGNATED_INITIALIZER;

#pragma mark - GREYProvider

/**
 *  @return An enumerator for the elements in the provider.
 */
- (NSEnumerator *)dataEnumerator;

@end

NS_ASSUME_NONNULL_END

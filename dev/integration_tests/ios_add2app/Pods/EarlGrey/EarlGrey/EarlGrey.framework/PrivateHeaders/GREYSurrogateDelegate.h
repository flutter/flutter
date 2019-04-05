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
 *  This class is used as a common base class for proxy delegates.
 *  Primarily used to hold needed message forwarding methods.
 */
@interface GREYSurrogateDelegate : NSObject

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializer that takes the original delegate and provides a surrogate backed by the original.
 *
 *  @param originalDelegate The original delegate being proxied. This can be @c nil.
 *  @param shouldBeWeak     Specifies whether the delegate should be weak or strong.
 *
 *  @return an instance of GREYSurrogateDelegate backed by the provided delegate.
 */
- (instancetype)initWithOriginalDelegate:(id)originalDelegate
                                  isWeak:(BOOL)shouldBeWeak NS_DESIGNATED_INITIALIZER;

/**
 *  @return The original delegate that's being proxied.
 */
- (id)originalDelegate;

@end

NS_ASSUME_NONNULL_END

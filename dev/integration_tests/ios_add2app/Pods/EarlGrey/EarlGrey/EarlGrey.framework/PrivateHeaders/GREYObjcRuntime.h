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

NS_ASSUME_NONNULL_BEGIN

/**
 *  A utility class used for common runtime related operations.
 */
@interface GREYObjcRuntime : NSObject

/**
 *  Adds the given method from the given class into the destination class.
 *
 *  @param destination The destination class.
 *  @param selector    The method selector from source class that needs to be added to destination.
 *  @param source      The source class for the method to be added.
 */
+ (void)addInstanceMethodToClass:(Class)destination
                    withSelector:(SEL)selector
                       fromClass:(Class)source;

@end

NS_ASSUME_NONNULL_END

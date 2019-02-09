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
 *  A protocol that defines the layout of an object that conforms to GREYMatcher.
 */
@protocol GREYDescription<NSObject>

/**
 *  Appends the provided text to the GREYDescription.
 *
 *  @param text The text to be appended to the GREYDescription.
 *
 *  @return An instance of an object conforming to GREYDescription with the provided
 *          @c text appended to it.
 */
- (id<GREYDescription>)appendText:(NSString *)text;

/**
 *  Appends the description of the provided object to the GREYDescription.
 *
 *  @param object The object whose description is to be appended to the GREYDescription.
 *
 *  @return An instance of an object conforming to GREYDescription with the provided
 *          object's description appended to it.
 */
- (id<GREYDescription>)appendDescriptionOf:(id)object;

@end

NS_ASSUME_NONNULL_END

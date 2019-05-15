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

NS_ASSUME_NONNULL_BEGIN

/**
 *  Actions for manipulating a UIPickerView.
 */
@interface GREYPickerAction : GREYBaseAction

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
 *  Selects a value in a given column of a UIPickerView.
 *
 *  @param column Column of the UIPickerView to change.
 *  @param value  The value to set in the UIPickerView column.
 *
 *  @return An instance of UIPickerAction, initialized with the @c column and @c value.
 */
- (instancetype)initWithColumn:(NSInteger)column value:(NSString *)value NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

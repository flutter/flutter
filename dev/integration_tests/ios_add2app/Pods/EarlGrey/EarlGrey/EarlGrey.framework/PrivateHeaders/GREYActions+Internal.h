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

/**
 *  @file GREYActions+Internal.h
 *  @brief Exposes GREYActions' interfaces and methods that are otherwise private for
 *  testing purposes.
 */

NS_ASSUME_NONNULL_BEGIN

@interface GREYActions (Internal)

/**
 *  Use the iOS keyboard to type a string starting from the provided UITextPosition. If the
 *  position is @c nil, then type text from the text input's current position. Should only be called
 *  with a position if element conforms to the UITextInput protocol - which it should if you
 *  derived the UITextPosition from the element.
 *
 *  @param text     The text to be typed.
 *  @param position The position in the text field at which the text is to be typed.
 *
 *  @return @c YES if the action succeeded, else @c NO. If an action returns @c NO, it does not
 *          mean that the action was not performed at all but somewhere during the action execution
 *          the error occured and so the UI may be in an unrecoverable state.
 *
 *  @remark This is available only for internal testing purposes.
 */
+ (id<GREYAction>)grey_actionForTypeText:(NSString *)text
                        atUITextPosition:(UITextPosition *)position;
@end

NS_ASSUME_NONNULL_END

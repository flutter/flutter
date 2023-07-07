// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// A simple set of pre/post-condition checkers based on the
/// [Guava](https://code.google.com/p/guava-libraries/) Preconditions
/// class in Java.
///
/// These checks are stronger than 'assert' statements, which can be
/// switched off, so they must only be used in situations where we actively
/// want the program to break when the check fails.
///
/// ## Performance
/// Performance may be an issue with these checks if complex logic is computed
/// in order to make the method call. You should be careful with its use in
/// these cases - this library is aimed at improving maintainability and
/// readability rather than performance. They are also useful when the program
/// should fail early - for example, null-checking a parameter that might not
/// be used until the end of the method call.
///
/// ## Error messages
/// The message parameter can be either a `() => Object` or any other `Object`.
/// The object will be converted to an error message by calling its
/// `toString()`. The `Function` should be preferred if the message is complex
/// to construct (i.e., it uses `String` interpolation), because it is only
/// called when the check fails.
///
/// If the message parameter is `null` or returns `null`, a default error
/// message will be used.
library quiver.check;

/// Throws an [ArgumentError] if the given [expression] is `false`.
void checkArgument(bool expression, {message}) {
  if (!expression) {
    throw ArgumentError(_resolveMessage(message, null));
  }
}

/// Throws a [RangeError] if the given [index] is not a valid index for a list
/// with [size] elements. Otherwise, returns the [index] parameter.
int checkListIndex(int index, int size, {message}) {
  if (index < 0 || index >= size) {
    throw RangeError(_resolveMessage(
        message, 'index $index not valid for list of size $size'));
  }
  return index;
}

/// Throws an [ArgumentError] if the given [reference] is `null`. Otherwise,
/// returns the [reference] parameter.
///
/// Users of Dart SDK 2.1 or later should prefer [ArgumentError.checkNotNull].
@Deprecated('Use ArgumentError.checkNotNull. Will be removed in 4.0.0')
T checkNotNull<T>(T reference, {message}) {
  if (reference == null) {
    throw ArgumentError(_resolveMessage(message, 'null pointer'));
  }
  return reference;
}

/// Throws a [StateError] if the given [expression] is `false`.
void checkState(bool expression, {message}) {
  if (!expression) {
    throw StateError(_resolveMessage(message, 'failed precondition')!);
  }
}

String? _resolveMessage(message, String? defaultMessage) {
  if (message is Function) message = message();
  if (message == null) return defaultMessage;
  return message.toString();
}

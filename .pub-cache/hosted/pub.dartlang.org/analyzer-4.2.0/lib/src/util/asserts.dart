// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Ensures that the given [value] is not null.
/// Otherwise throws an [ArgumentError].
/// An optional [description] is used in the error message.
void notNull(Object? value, [String? description]) {
  if (value == null) {
    if (description == null) {
      throw ArgumentError('Must not be null');
    } else {
      throw ArgumentError('Must not be null: $description');
    }
  }
}

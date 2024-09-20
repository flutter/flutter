// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

/// Codes that transformed sync*/async/async* functions use to communicate with
/// js_helper functions.
library;

const int SUCCESS = 0;
const int ERROR = 1;
const int STREAM_WAS_CANCELED = 2;

// A sync* function transformed 'body' returns the following codes to
// communicate the updated state of the `_SyncStarIterator` (Iterator).

/// The sync* body has terminated. The body should not be called again.
const int SYNC_STAR_DONE = 0;

/// The sync* body has updated the `_current` field of the Iterator with the
/// value that is yielded.
const int SYNC_STAR_YIELD = 1;

/// The sync* body has updated the Iterator with an Iterable. The elements of
/// the Iterable are the next values of the Iterator.
const int SYNC_STAR_YIELD_STAR = 2;

/// The sync* body throws an exception. The exception has been stored on a field
/// of the Iterator.
const int SYNC_STAR_UNCAUGHT_EXCEPTION = 3;

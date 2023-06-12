// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Analysis data for which we have a modification time.
class TimestampedData<E> {
  /// The modification time of the source from which the data was created.
  final int modificationTime;

  /// The data that was created from the source.
  final E data;

  /// Initialize a newly created holder to associate the given [data] with the
  /// given [modificationTime].
  TimestampedData(this.modificationTime, this.data);
}

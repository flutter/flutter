// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Growable typed-data lists.
///
/// These lists works just as a typed-data list, except that they are growable.
/// They use an underlying buffer, and when that buffer becomes too small, it
/// is replaced by a new buffer.
///
/// That means that using the `buffer` getter is not guaranteed
/// to return the same result each time it is used, and that the buffer may
/// be larger than what the list is using.
library typed_data.typed_buffers;

export 'src/typed_buffer.dart' hide TypedDataBuffer;

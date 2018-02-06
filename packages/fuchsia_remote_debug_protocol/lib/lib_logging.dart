// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Library for logging the remote debug protocol internals.
///
/// Useful for determining connection issues and the like. This is included as a
/// separate library so that it can be imported under a separate namespace, or
/// not at all when using the remote debugging protocol.
library lib_logging;

export 'src/common/logging.dart';

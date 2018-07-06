// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Library for logging the remote debug protocol internals.
///
/// Useful for determining connection issues and the like. This is included as a
/// separate library so that it can be imported under a separate namespace in
/// the event that you are using a logging package with similar class names.
library logging;

export 'src/common/logging.dart';

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'isolates.dart' as isolates;

/// The dart:html implementation of [isolate.compute].
Future<R> compute<Q, R>(isolates.ComputeCallback<Q, R> callback, Q message, { String debugLabel }) async {
  await null;
  return callback(message);
}

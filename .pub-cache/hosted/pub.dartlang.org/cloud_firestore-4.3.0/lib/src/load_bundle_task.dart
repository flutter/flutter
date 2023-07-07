// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

class LoadBundleTask {
  LoadBundleTask._(this._delegate) {
    LoadBundleTaskPlatform.verify(_delegate);
  }

  final LoadBundleTaskPlatform _delegate;

  late final Stream<LoadBundleTaskSnapshot> stream =
      // ignore: unnecessary_lambdas, false positive, event is dynamic
      _delegate.stream.map((event) => LoadBundleTaskSnapshot._(event));
}

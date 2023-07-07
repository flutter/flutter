// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CancelableToken extends CancellationToken {
  bool _isCancelled = false;

  @override
  bool get isCancellationRequested => _isCancelled;

  void cancel() => _isCancelled = true;
}

/// A token used to signal cancellation of an operation. This allows computation
/// to be skipped when a caller is no longer interested in the result, for example
/// when a $/cancel request is received for an in-progress request.
abstract class CancellationToken {
  bool get isCancellationRequested;
}

/// A [CancellationToken] that cannot be cancelled.
class NotCancelableToken extends CancellationToken {
  @override
  bool get isCancellationRequested => false;
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../../exceptions.dart';
import '../foundation/enums.g.dart';
import '../foundation/iasyncaction.dart';
import '../foundation/iasyncinfo.dart';
import '../foundation/iasyncoperation.dart';

/// Completes the given [completer] when [asyncAction] completes.
void completeAsyncAction(
  IAsyncAction asyncAction,
  Completer<void> completer,
) =>
    _completeAsyncDelegate(asyncAction, completer, completer.complete);

/// Completes the given [completer] when [asyncOperation] completes.
///
/// If [asyncOperation] completes successfully, [completer] will be completed
/// with the [value].
void completeAsyncOperation<T, C>(
  IAsyncOperation<T> asyncOperation,
  Completer<C> completer,
  C Function() value,
) =>
    _completeAsyncDelegate(
        asyncOperation, completer, () => completer.complete(value()));

/// Completes the given [completer] by polling [asyncDelegate]'s `status`
/// property every `1/60` seconds until the [asyncDelegate] completes.
///
/// [onCompleted] is called when the [asyncDelegate] completes successfully.
Future<void> _completeAsyncDelegate<T extends IAsyncInfo, C>(T asyncDelegate,
    Completer<C> completer, void Function() onCompleted) async {
  try {
    while (asyncDelegate.status == AsyncStatus.started) {
      // Yield execution to Dart for 1/60 seconds to avoid blocking the app.
      await Future<void>.delayed(
          const Duration(microseconds: 1 * 1000 * 1000 ~/ 60));
    }

    switch (asyncDelegate.status) {
      // This case is handled by the while loop above.
      case AsyncStatus.started:
        break;
      case AsyncStatus.completed:
        onCompleted();
        break;
      case AsyncStatus.canceled:
        completer.completeError('The async operation canceled!');
        break;
      case AsyncStatus.error:
        completer.completeError(WindowsException(asyncDelegate.errorCode));
        break;
    }
  } catch (error, stackTrace) {
    completer.completeError(error, stackTrace);
  } finally {
    asyncDelegate.release();
  }
}

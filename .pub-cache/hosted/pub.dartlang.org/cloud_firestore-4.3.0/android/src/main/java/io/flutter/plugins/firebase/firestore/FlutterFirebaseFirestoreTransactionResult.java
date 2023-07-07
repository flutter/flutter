// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.firestore;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class FlutterFirebaseFirestoreTransactionResult {

  public final @Nullable Exception exception;

  private FlutterFirebaseFirestoreTransactionResult(@NonNull Exception failureException) {
    exception = failureException;
  }

  private FlutterFirebaseFirestoreTransactionResult() {
    exception = null;
  }

  public static FlutterFirebaseFirestoreTransactionResult failed(@NonNull Exception exception) {
    return new FlutterFirebaseFirestoreTransactionResult(exception);
  }

  public static FlutterFirebaseFirestoreTransactionResult complete() {
    return new FlutterFirebaseFirestoreTransactionResult();
  }
}

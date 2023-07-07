/*
 * Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

package io.flutter.plugins.firebase.firestore.streamhandler;

import static io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin.DEFAULT_ERROR_CODE;

import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.LoadBundleTask;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.firebase.firestore.utils.ExceptionConverter;
import java.util.Map;
import java.util.Objects;

public class LoadBundleStreamHandler implements EventChannel.StreamHandler {
  private EventChannel.EventSink eventSink;

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    eventSink = events;

    @SuppressWarnings("unchecked")
    Map<String, Object> argumentsMap = (Map<String, Object>) arguments;
    byte[] bundle = (byte[]) Objects.requireNonNull(argumentsMap.get("bundle"));
    FirebaseFirestore firestore =
        (FirebaseFirestore) Objects.requireNonNull(argumentsMap.get("firestore"));

    LoadBundleTask task = firestore.loadBundle(bundle);

    task.addOnProgressListener(
        snapshot -> {
          events.success(snapshot);
        });

    task.addOnFailureListener(
        exception -> {
          Map<String, String> exceptionDetails = ExceptionConverter.createDetails(exception);
          events.error(DEFAULT_ERROR_CODE, exception.getMessage(), exceptionDetails);
          onCancel(null);
        });
  }

  @Override
  public void onCancel(Object arguments) {
    eventSink.endOfStream();
  }
}

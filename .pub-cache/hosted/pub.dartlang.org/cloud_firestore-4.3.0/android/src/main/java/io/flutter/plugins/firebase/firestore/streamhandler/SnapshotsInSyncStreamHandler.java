/*
 * Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

package io.flutter.plugins.firebase.firestore.streamhandler;

import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import java.util.Map;
import java.util.Objects;

public class SnapshotsInSyncStreamHandler implements StreamHandler {

  ListenerRegistration listenerRegistration;

  @Override
  public void onListen(Object arguments, EventSink events) {
    @SuppressWarnings("unchecked")
    Map<String, Object> argumentsMap = (Map<String, Object>) arguments;

    FirebaseFirestore firestore =
        (FirebaseFirestore) Objects.requireNonNull(argumentsMap.get("firestore"));

    Runnable snapshotsInSyncRunnable = () -> events.success(null);

    listenerRegistration = firestore.addSnapshotsInSyncListener(snapshotsInSyncRunnable);
  }

  @Override
  public void onCancel(Object arguments) {
    if (listenerRegistration != null) {
      listenerRegistration.remove();
      listenerRegistration = null;
    }
  }
}

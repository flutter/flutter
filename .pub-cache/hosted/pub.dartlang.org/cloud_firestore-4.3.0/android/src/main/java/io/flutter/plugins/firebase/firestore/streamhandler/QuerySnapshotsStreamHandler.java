/*
 * Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

package io.flutter.plugins.firebase.firestore.streamhandler;

import static io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin.DEFAULT_ERROR_CODE;

import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.MetadataChanges;
import com.google.firebase.firestore.Query;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin;
import io.flutter.plugins.firebase.firestore.utils.ExceptionConverter;
import io.flutter.plugins.firebase.firestore.utils.ServerTimestampBehaviorConverter;
import java.util.Map;
import java.util.Objects;

public class QuerySnapshotsStreamHandler implements StreamHandler {

  ListenerRegistration listenerRegistration;

  @Override
  public void onListen(Object arguments, EventSink events) {
    @SuppressWarnings("unchecked")
    Map<String, Object> argumentsMap = (Map<String, Object>) arguments;

    MetadataChanges metadataChanges =
        (Boolean) Objects.requireNonNull(argumentsMap.get("includeMetadataChanges"))
            ? MetadataChanges.INCLUDE
            : MetadataChanges.EXCLUDE;

    Query query = (Query) argumentsMap.get("query");
    String serverTimestampBehaviorString = (String) argumentsMap.get("serverTimestampBehavior");
    DocumentSnapshot.ServerTimestampBehavior serverTimestampBehavior =
        ServerTimestampBehaviorConverter.toServerTimestampBehavior(serverTimestampBehaviorString);

    if (query == null) {
      throw new IllegalArgumentException(
          "An error occurred while parsing query arguments, see native logs for more information. Please report this issue.");
    }

    listenerRegistration =
        query.addSnapshotListener(
            metadataChanges,
            (querySnapshot, exception) -> {
              if (exception != null) {
                Map<String, String> exceptionDetails = ExceptionConverter.createDetails(exception);
                events.error(DEFAULT_ERROR_CODE, exception.getMessage(), exceptionDetails);
                events.endOfStream();

                onCancel(null);
              } else {
                if (querySnapshot != null) {
                  FlutterFirebaseFirestorePlugin.serverTimestampBehaviorHashMap.put(
                      querySnapshot.hashCode(), serverTimestampBehavior);
                }
                events.success(querySnapshot);
              }
            });
  }

  @Override
  public void onCancel(Object arguments) {
    if (listenerRegistration != null) {
      listenerRegistration.remove();
      listenerRegistration = null;
    }
  }
}

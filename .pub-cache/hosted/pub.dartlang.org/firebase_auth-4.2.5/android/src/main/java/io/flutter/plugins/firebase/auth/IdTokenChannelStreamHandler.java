/*
 * Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

package io.flutter.plugins.firebase.auth;

import static io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin.parseFirebaseUser;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuth.IdTokenListener;
import com.google.firebase.auth.FirebaseUser;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

public class IdTokenChannelStreamHandler implements StreamHandler {

  private final FirebaseAuth firebaseAuth;
  private IdTokenListener idTokenListener;

  public IdTokenChannelStreamHandler(FirebaseAuth firebaseAuth) {
    this.firebaseAuth = firebaseAuth;
  }

  @Override
  public void onListen(Object arguments, EventSink events) {
    Map<String, Object> event = new HashMap<>();
    event.put(Constants.APP_NAME, firebaseAuth.getApp().getName());

    final AtomicBoolean initialAuthState = new AtomicBoolean(true);

    idTokenListener =
        auth -> {
          if (initialAuthState.get()) {
            initialAuthState.set(false);
            return;
          }

          FirebaseUser user = auth.getCurrentUser();

          if (user == null) {
            event.put(Constants.USER, null);
          } else {
            event.put(Constants.USER, parseFirebaseUser(user));
          }

          events.success(event);
        };

    firebaseAuth.addIdTokenListener(idTokenListener);
  }

  @Override
  public void onCancel(Object arguments) {
    if (idTokenListener != null) {
      firebaseAuth.removeIdTokenListener(idTokenListener);
      idTokenListener = null;
    }
  }
}

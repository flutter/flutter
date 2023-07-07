// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.PermissionRequest;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.PermissionRequestFlutterApi;
import java.util.Arrays;

/**
 * Flutter API implementation for `PermissionRequest`.
 *
 * <p>This class may handle adding native instances that are attached to a Dart instance or passing
 * arguments of callbacks methods to a Dart instance.
 */
public class PermissionRequestFlutterApiImpl {
  // To ease adding additional methods, this value is added prematurely.
  @SuppressWarnings({"unused", "FieldCanBeLocal"})
  private final BinaryMessenger binaryMessenger;

  private final InstanceManager instanceManager;
  private PermissionRequestFlutterApi api;

  /**
   * Constructs a {@link PermissionRequestFlutterApiImpl}.
   *
   * @param binaryMessenger used to communicate with Dart over asynchronous messages
   * @param instanceManager maintains instances stored to communicate with attached Dart objects
   */
  public PermissionRequestFlutterApiImpl(
      @NonNull BinaryMessenger binaryMessenger, @NonNull InstanceManager instanceManager) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
    api = new PermissionRequestFlutterApi(binaryMessenger);
  }

  /**
   * Stores the `PermissionRequest` instance and notifies Dart to create and store a new
   * `PermissionRequest` instance that is attached to this one. If `instance` has already been
   * added, this method does nothing.
   */
  public void create(
      @NonNull PermissionRequest instance,
      @NonNull String[] resources,
      @NonNull PermissionRequestFlutterApi.Reply<Void> callback) {
    if (!instanceManager.containsInstance(instance)) {
      api.create(
          instanceManager.addHostCreatedInstance(instance), Arrays.asList(resources), callback);
    }
  }

  /**
   * Sets the Flutter API used to send messages to Dart.
   *
   * <p>This is only visible for testing.
   */
  @VisibleForTesting
  void setApi(@NonNull PermissionRequestFlutterApi api) {
    this.api = api;
  }
}

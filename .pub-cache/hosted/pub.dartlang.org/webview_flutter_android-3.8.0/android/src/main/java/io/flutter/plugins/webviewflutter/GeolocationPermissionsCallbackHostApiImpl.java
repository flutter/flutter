// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.GeolocationPermissions;
import androidx.annotation.NonNull;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.GeolocationPermissionsCallbackHostApi;
import java.util.Objects;

/**
 * Host API implementation for `GeolocationPermissionsCallback`.
 *
 * <p>This class may handle instantiating and adding native object instances that are attached to a
 * Dart instance or handle method calls on the associated native class or an instance of the class.
 */
public class GeolocationPermissionsCallbackHostApiImpl
    implements GeolocationPermissionsCallbackHostApi {
  // To ease adding additional methods, this value is added prematurely.
  @SuppressWarnings({"unused", "FieldCanBeLocal"})
  private final BinaryMessenger binaryMessenger;

  private final InstanceManager instanceManager;

  /**
   * Constructs a {@link GeolocationPermissionsCallbackHostApiImpl}.
   *
   * @param binaryMessenger used to communicate with Dart over asynchronous messages
   * @param instanceManager maintains instances stored to communicate with attached Dart objects
   */
  public GeolocationPermissionsCallbackHostApiImpl(
      @NonNull BinaryMessenger binaryMessenger, @NonNull InstanceManager instanceManager) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
  }

  @Override
  public void invoke(
      @NonNull Long instanceId,
      @NonNull String origin,
      @NonNull Boolean allow,
      @NonNull Boolean retain) {
    getGeolocationPermissionsCallbackInstance(instanceId).invoke(origin, allow, retain);
  }

  private GeolocationPermissions.Callback getGeolocationPermissionsCallbackInstance(
      @NonNull Long identifier) {
    return Objects.requireNonNull(instanceManager.getInstance(identifier));
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Build;
import android.webkit.PermissionRequest;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.PermissionRequestHostApi;
import java.util.List;
import java.util.Objects;

/**
 * Host API implementation for `PermissionRequest`.
 *
 * <p>This class may handle instantiating and adding native object instances that are attached to a
 * Dart instance or handle method calls on the associated native class or an instance of the class.
 */
@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class PermissionRequestHostApiImpl implements PermissionRequestHostApi {
  // To ease adding additional methods, this value is added prematurely.
  @SuppressWarnings({"unused", "FieldCanBeLocal"})
  private final BinaryMessenger binaryMessenger;

  private final InstanceManager instanceManager;

  /**
   * Constructs a {@link PermissionRequestHostApiImpl}.
   *
   * @param binaryMessenger used to communicate with Dart over asynchronous messages
   * @param instanceManager maintains instances stored to communicate with attached Dart objects
   */
  public PermissionRequestHostApiImpl(
      @NonNull BinaryMessenger binaryMessenger, @NonNull InstanceManager instanceManager) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
  }

  @Override
  public void grant(@NonNull Long instanceId, @NonNull List<String> resources) {
    getPermissionRequestInstance(instanceId).grant(resources.toArray(new String[0]));
  }

  @Override
  public void deny(@NonNull Long instanceId) {
    getPermissionRequestInstance(instanceId).deny();
  }

  private PermissionRequest getPermissionRequestInstance(@NonNull Long identifier) {
    return Objects.requireNonNull(instanceManager.getInstance(identifier));
  }
}

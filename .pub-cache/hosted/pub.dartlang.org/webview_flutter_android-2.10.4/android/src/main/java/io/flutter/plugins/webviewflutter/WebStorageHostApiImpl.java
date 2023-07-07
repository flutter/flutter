// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.WebStorage;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebStorageHostApi;

/**
 * Host api implementation for {@link WebStorage}.
 *
 * <p>Handles creating {@link WebStorage}s that intercommunicate with a paired Dart object.
 */
public class WebStorageHostApiImpl implements WebStorageHostApi {
  private final InstanceManager instanceManager;
  private final WebStorageCreator webStorageCreator;

  /** Handles creating {@link WebStorage} for a {@link WebStorageHostApiImpl}. */
  public static class WebStorageCreator {
    /**
     * Creates a {@link WebStorage}.
     *
     * @return the created {@link WebStorage}. Defaults to {@link WebStorage#getInstance}
     */
    public WebStorage createWebStorage() {
      return WebStorage.getInstance();
    }
  }

  /**
   * Creates a host API that handles creating {@link WebStorage} and invoke its methods.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param webStorageCreator handles creating {@link WebStorage}s
   */
  public WebStorageHostApiImpl(
      InstanceManager instanceManager, WebStorageCreator webStorageCreator) {
    this.instanceManager = instanceManager;
    this.webStorageCreator = webStorageCreator;
  }

  @Override
  public void create(Long instanceId) {
    instanceManager.addDartCreatedInstance(webStorageCreator.createWebStorage(), instanceId);
  }

  @Override
  public void deleteAllData(Long instanceId) {
    final WebStorage webStorage = (WebStorage) instanceManager.getInstance(instanceId);
    webStorage.deleteAllData();
  }
}

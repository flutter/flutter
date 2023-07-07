// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.DownloadListener;
import androidx.annotation.NonNull;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.DownloadListenerHostApi;

/**
 * Host api implementation for {@link DownloadListener}.
 *
 * <p>Handles creating {@link DownloadListener}s that intercommunicate with a paired Dart object.
 */
public class DownloadListenerHostApiImpl implements DownloadListenerHostApi {
  private final InstanceManager instanceManager;
  private final DownloadListenerCreator downloadListenerCreator;
  private final DownloadListenerFlutterApiImpl flutterApi;

  /**
   * Implementation of {@link DownloadListener} that passes arguments of callback methods to Dart.
   */
  public static class DownloadListenerImpl implements DownloadListener {
    private final DownloadListenerFlutterApiImpl flutterApi;

    /**
     * Creates a {@link DownloadListenerImpl} that passes arguments of callbacks methods to Dart.
     *
     * @param flutterApi handles sending messages to Dart
     */
    public DownloadListenerImpl(@NonNull DownloadListenerFlutterApiImpl flutterApi) {
      this.flutterApi = flutterApi;
    }

    @Override
    public void onDownloadStart(
        @NonNull String url,
        @NonNull String userAgent,
        @NonNull String contentDisposition,
        @NonNull String mimetype,
        long contentLength) {
      flutterApi.onDownloadStart(
          this, url, userAgent, contentDisposition, mimetype, contentLength, reply -> {});
    }
  }

  /** Handles creating {@link DownloadListenerImpl}s for a {@link DownloadListenerHostApiImpl}. */
  public static class DownloadListenerCreator {
    /**
     * Creates a {@link DownloadListenerImpl}.
     *
     * @param flutterApi handles sending messages to Dart
     * @return the created {@link DownloadListenerImpl}
     */
    @NonNull
    public DownloadListenerImpl createDownloadListener(
        @NonNull DownloadListenerFlutterApiImpl flutterApi) {
      return new DownloadListenerImpl(flutterApi);
    }
  }

  /**
   * Creates a host API that handles creating {@link DownloadListener}s.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param downloadListenerCreator handles creating {@link DownloadListenerImpl}s
   * @param flutterApi handles sending messages to Dart
   */
  public DownloadListenerHostApiImpl(
      @NonNull InstanceManager instanceManager,
      @NonNull DownloadListenerCreator downloadListenerCreator,
      @NonNull DownloadListenerFlutterApiImpl flutterApi) {
    this.instanceManager = instanceManager;
    this.downloadListenerCreator = downloadListenerCreator;
    this.flutterApi = flutterApi;
  }

  @Override
  public void create(@NonNull Long instanceId) {
    final DownloadListener downloadListener =
        downloadListenerCreator.createDownloadListener(flutterApi);
    instanceManager.addDartCreatedInstance(downloadListener, instanceId);
  }
}

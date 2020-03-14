// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.contentprovider;

import androidx.annotation.NonNull;

/**
 * A {@link FlutterPlugin} that wants to know when it is running within a {@link ContentProvider}.
 */
public interface ContentProviderAware {
  /**
   * Callback triggered when a {@code ContentProviderAware} {@link FlutterPlugin} is associated with
   * a {@link ContentProvider}.
   */
  void onAttachedToContentProvider(@NonNull ContentProviderPluginBinding binding);

  /**
   * Callback triggered when a {@code ContentProviderAware} {@link FlutterPlugin} is detached from a
   * {@link ContentProvider}.
   */
  void onDetachedFromContentProvider();
}

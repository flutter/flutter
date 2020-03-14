// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.broadcastreceiver;

import androidx.annotation.NonNull;

/**
 * A {@link FlutterPlugin} that wants to know when it is running within a {@link BroadcastReceiver}.
 */
public interface BroadcastReceiverAware {
  /**
   * Callback triggered when a {@code BroadcastReceiverAware} {@link FlutterPlugin} is associated
   * with a {@link BroadcastReceiver}.
   */
  void onAttachedToBroadcastReceiver(@NonNull BroadcastReceiverPluginBinding binding);

  /**
   * Callback triggered when a {@code BroadcastReceiverAware} {@link FlutterPlugin} is detached from
   * a {@link BroadcastReceiver}.
   */
  void onDetachedFromBroadcastReceiver();
}

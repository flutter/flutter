// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

class FlutterWebViewFactory extends PlatformViewFactory {
  private final InstanceManager instanceManager;

  FlutterWebViewFactory(InstanceManager instanceManager) {
    super(StandardMessageCodec.INSTANCE);
    this.instanceManager = instanceManager;
  }

  @NonNull
  @Override
  public PlatformView create(Context context, int viewId, @Nullable Object args) {
    final Integer identifier = (Integer) args;
    if (identifier == null) {
      throw new IllegalStateException("An identifier is required to retrieve WebView instance.");
    }

    final PlatformView view = instanceManager.getInstance(identifier);
    if (view == null) {
      throw new IllegalStateException("Unable to find WebView instance: " + args);
    }
    return view;
  }
}

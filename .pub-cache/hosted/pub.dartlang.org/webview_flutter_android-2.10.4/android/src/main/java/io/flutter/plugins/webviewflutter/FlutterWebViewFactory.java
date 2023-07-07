// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.Context;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

class FlutterWebViewFactory extends PlatformViewFactory {
  private final InstanceManager instanceManager;

  FlutterWebViewFactory(InstanceManager instanceManager) {
    super(StandardMessageCodec.INSTANCE);
    this.instanceManager = instanceManager;
  }

  @Override
  public PlatformView create(Context context, int id, Object args) {
    final PlatformView view = (PlatformView) instanceManager.getInstance((Integer) args);
    if (view == null) {
      throw new IllegalStateException("Unable to find WebView instance: " + args);
    }
    return view;
  }
}

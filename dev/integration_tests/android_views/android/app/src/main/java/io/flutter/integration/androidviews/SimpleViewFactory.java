// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.platformviews;

import android.content.Context;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class SimpleViewFactory extends PlatformViewFactory {
    final DartExecutor executor;
    private final boolean useVirtualDisplay;

    public SimpleViewFactory(DartExecutor executor, boolean useVirtualDisplay) {
        super(null);
        this.executor = executor;
        this.useVirtualDisplay = useVirtualDisplay;
    }

    @Override
    public PlatformView create(Context context, int id, Object params) {
        MethodChannel methodChannel = new MethodChannel(executor, "simple_view/" + id);
        return new SimplePlatformView(context, methodChannel, useVirtualDisplay);
    }
}

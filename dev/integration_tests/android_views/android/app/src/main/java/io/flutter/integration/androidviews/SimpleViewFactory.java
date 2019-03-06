// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.androidviews;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class SimpleViewFactory extends PlatformViewFactory {
    final BinaryMessenger messenger;

    public SimpleViewFactory(BinaryMessenger messenger) {
        super(null);
        this.messenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int id, Object params) {
        MethodChannel methodChannel = new MethodChannel(messenger, "simple_view/" + id);
        return new SimplePlatformView(context, methodChannel);
    }
}

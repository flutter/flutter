// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.content.Context;

public interface PlatformViewFactory {
    /**
     * Creates a new Android view to be embedded in the Flutter hierarchy.
     *
     * @param context the context to be used when creating the view, this is different than FlutterView's context.
     * @param viewId unique identifier for the created instance, this value is known on the Dart side.
     */
    PlatformView create(Context context, int viewId);
}

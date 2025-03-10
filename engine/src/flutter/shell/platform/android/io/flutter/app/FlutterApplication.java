// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.app;

import android.app.Application;

/**
 * Empty implementation of the {@link Application} class, provided to avoid breaking older Flutter
 * projects. Flutter projects which need to extend an Application should migrate to extending {@link
 * android.app.Application} instead.
 *
 * <p>For more information on the removal of Flutter's v1 Android embedding, see:
 * https://docs.flutter.dev/release/breaking-changes/v1-android-embedding.
 */
@Deprecated
public class FlutterApplication extends Application {}

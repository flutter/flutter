// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.multipleflutters

import android.app.Application
import io.flutter.embedding.engine.FlutterEngineGroup

/**
 * Application class for this app.
 *
 * This holds onto our engine group.
 */
class App : Application() {
    lateinit var engines: FlutterEngineGroup

    override fun onCreate() {
        super.onCreate()
        engines = FlutterEngineGroup(this)
    }
}

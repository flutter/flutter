// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.deferred_components_test

import com.google.android.play.core.splitcompat.SplitCompatApplication
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterJNI
import io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager
import io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

class MainApplication : SplitCompatApplication() {
  override fun onCreate() {
    super.onCreate()

    val manager = PlayStoreDeferredComponentManager(this, null)
    FlutterInjector.setInstance(
      FlutterInjector.Builder()
        .setDeferredComponentManager(FailFirstDeferredComponentRequestManager(manager))
        .build()
    )
  }
}

private class FailFirstDeferredComponentRequestManager(
  private val delegate: DeferredComponentManager
) : DeferredComponentManager by delegate {
  private lateinit var flutterJNI: FlutterJNI
  private val failedLoadingUnitIds = mutableSetOf<Int>()

  override fun setJNI(flutterJNI: FlutterJNI) {
    this.flutterJNI = flutterJNI
    delegate.setJNI(flutterJNI)
  }

  override fun installDeferredComponent(loadingUnitId: Int, componentName: String?) {
    if (loadingUnitId >= 0 && failedLoadingUnitIds.add(loadingUnitId)) {
      flutterJNI.deferredComponentInstallFailure(
        loadingUnitId,
        "Injected deferred component installation failure",
        true
      )
      return
    }

    delegate.installDeferredComponent(loadingUnitId, componentName)
  }
}

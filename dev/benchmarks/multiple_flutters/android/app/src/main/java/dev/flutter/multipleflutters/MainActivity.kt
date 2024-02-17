// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.multipleflutters

import android.os.Bundle
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MainActivity : FragmentActivity() {
    private val numberOfFlutters = 20

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this)
        root.layoutParams =
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT,
            )
        root.orientation = LinearLayout.VERTICAL
        root.weightSum = numberOfFlutters.toFloat()

        val fragmentManager: FragmentManager = supportFragmentManager

        setContentView(root)

        val app = applicationContext as App
        val dartEntrypoint =
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "main",
            )
        val engines =
            generateSequence(0) { it + 1 }
                .take(numberOfFlutters)
                .map { app.engines.createAndRunEngine(this, dartEntrypoint) }
                .toList()
        for (i in 0 until numberOfFlutters) {
            val flutterContainer = FrameLayout(this)
            root.addView(flutterContainer)
            flutterContainer.id = 12345 + i
            flutterContainer.layoutParams =
                LinearLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    1.0f,
                )
            val engine = engines[i]
            FlutterEngineCache.getInstance().put(i.toString(), engine)
            val flutterFragment =
                FlutterFragment.withCachedEngine(i.toString()).build<FlutterFragment>()
            fragmentManager
                .beginTransaction()
                .add(
                    12345 + i,
                    flutterFragment,
                )
                .commit()
        }
    }

    override fun onDestroy() {
        for (i in 0 until numberOfFlutters) {
            FlutterEngineCache.getInstance().remove(i.toString())
        }

        super.onDestroy()
    }
}

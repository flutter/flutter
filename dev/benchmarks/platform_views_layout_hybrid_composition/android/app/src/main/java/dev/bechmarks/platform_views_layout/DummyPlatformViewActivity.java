// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.benchmarks.platform_views_layout_hybrid_composition;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.ViewGroup;
import io.flutter.Log;

public class DummyPlatformViewActivity extends FlutterActivity {
    private static final String TAG = "DummyPlatformViewActivity";
    private static final String CHANNEL = "samples.flutter.dev/invalidation";
    private boolean invalidationLoopRunning = false;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private View decorView;
    private int loopCount = 0;

    private final Runnable invalidationRunnable = new Runnable() {
        @Override
        public void run() {
            if (invalidationLoopRunning && decorView != null) {
                loopCount++;
                if (loopCount % 10 == 0) {
                    Log.i(TAG, "Invalidation loop running, count: " + loopCount);
                }
                invalidateFlutterImageViews(decorView);
                handler.postDelayed(this, 16); // ~60fps
            }
        }
    };

    private void invalidateFlutterImageViews(View view) {
        if (view.getClass().getName().equals("io.flutter.embedding.android.FlutterImageView")) {
            view.invalidate();
        } else if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) {
                invalidateFlutterImageViews(group.getChildAt(i));
            }
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        flutterEngine
            .getPlatformViewsController()
            .getRegistry()
            .registerViewFactory("benchmarks/platform_views_layout_hybrid_composition/DummyPlatformView", new DummyPlatformViewFactory());

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("startInvalidationLoop")) {
                        startInvalidationLoop();
                        result.success(null);
                    } else if (call.method.equals("stopInvalidationLoop")) {
                        stopInvalidationLoop();
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    private void startInvalidationLoop() {
        Log.i(TAG, "startInvalidationLoop called");
        if (!invalidationLoopRunning) {
            decorView = getWindow().getDecorView();
            invalidationLoopRunning = true;
            loopCount = 0;
            handler.post(invalidationRunnable);
        }
    }

    private void stopInvalidationLoop() {
        Log.i(TAG, "stopInvalidationLoop called, total loops: " + loopCount);
        invalidationLoopRunning = false;
        handler.removeCallbacks(invalidationRunnable);
    }
}

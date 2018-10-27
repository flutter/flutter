// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.demo.gallery;

import android.os.Build;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.view.FlutterView;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

    private FlutterGalleryInstrumentation instrumentation;

    /** Instrumentation for testing. */
    public FlutterGalleryInstrumentation getInstrumentation() {
        return instrumentation;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);
        instrumentation = new FlutterGalleryInstrumentation(this.getFlutterView());
        getFlutterView().addFirstFrameListener(new FlutterView.FirstFrameListener() {
            @Override
            public void onFirstFrame() {
                // Report fully drawn time for Play Store Console.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    MainActivity.this.reportFullyDrawn();
                }
                MainActivity.this.getFlutterView().removeFirstFrameListener(this);
            }
          });
    }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.view.Choreographer;

public class VsyncWaiter {
    // This estimate will be updated by FlutterView when it is attached to a Display.
    public static long refreshPeriodNanos = 1000000000 / 60;

    // This should also be updated by FlutterView when it is attached to a Display.
    // The initial value of 0.0 indicates unkonwn refresh rate.
    public static float refreshRateFPS = 0.0f;

    public static void asyncWaitForVsync(final long cookie) {
        Choreographer.getInstance().postFrameCallback(new Choreographer.FrameCallback() {
            @Override
            public void doFrame(long frameTimeNanos) {
                nativeOnVsync(frameTimeNanos, frameTimeNanos + refreshPeriodNanos, cookie);
            }
        });
    }

    private static native void nativeOnVsync(long frameTimeNanos, long frameTargetTimeNanos, long cookie);
}

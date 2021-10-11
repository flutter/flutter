// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.view.Choreographer;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterJNI;

// TODO(mattcarroll): add javadoc.
public class VsyncWaiter {
  private static VsyncWaiter instance;

  @NonNull
  public static VsyncWaiter getInstance(float fps) {
    if (instance == null) {
      instance = new VsyncWaiter(fps);
    }
    return instance;
  }

  private final float fps;
  private final long refreshPeriodNanos;

  private final FlutterJNI.AsyncWaitForVsyncDelegate asyncWaitForVsyncDelegate =
      new FlutterJNI.AsyncWaitForVsyncDelegate() {
        @Override
        public void asyncWaitForVsync(long cookie) {
          Choreographer.getInstance()
              .postFrameCallback(
                  new Choreographer.FrameCallback() {
                    @Override
                    public void doFrame(long frameTimeNanos) {
                      long delay = System.nanoTime() - frameTimeNanos;
                      if (delay < 0) {
                        delay = 0;
                      }
                      FlutterJNI.nativeOnVsync(delay, refreshPeriodNanos, cookie);
                    }
                  });
        }
      };

  private VsyncWaiter(float fps) {
    this.fps = fps;
    refreshPeriodNanos = (long) (1000000000.0 / fps);
  }

  public void init() {
    FlutterJNI.setAsyncWaitForVsyncDelegate(asyncWaitForVsyncDelegate);

    // TODO(mattcarroll): look into moving FPS reporting to a plugin
    FlutterJNI.setRefreshRateFPS(fps);
  }
}

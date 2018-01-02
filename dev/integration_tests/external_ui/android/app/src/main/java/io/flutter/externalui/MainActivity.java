// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.externalui;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.os.Bundle;
import android.view.Surface;
import android.view.SurfaceHolder;

import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.TextureRegistry;
import io.flutter.view.TextureRegistry.SurfaceTextureEntry;

public class MainActivity extends FlutterActivity {
  private Surface surface;
  private SurfaceTexture texture;
  private Timer producerTimer;
  private Timer consumerTimer;
  private long startTime;
  private long endTime;
  private AtomicInteger framesProduced = new AtomicInteger(0);
  private AtomicInteger framesConsumed = new AtomicInteger(0);

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    final MethodChannel channel = new MethodChannel(getFlutterView(), "texture");
    channel.setMethodCallHandler(new MethodCallHandler() {
      @Override
      public void onMethodCall(MethodCall methodCall, Result result) {
        switch (methodCall.method) {
          case "start":
            framesProduced.set(0);
            framesConsumed.set(0);
            final int fps = methodCall.arguments();
            final FrameRenderer renderer = new FrameRenderer(surface);
            producerTimer = new Timer();
            producerTimer.scheduleAtFixedRate(new TimerTask() {
              @Override
              public void run() {
                final long time = System.currentTimeMillis();
                if (frameRate(framesProduced, startTime, time) < fps) {
                  renderer.drawFrame();
                  framesProduced.incrementAndGet();
                }
              }
            }, 0, 1000 / fps);
            consumerTimer = new Timer();
            consumerTimer.scheduleAtFixedRate(new TimerTask() {
              private long lastTimestamp = -1L;

              @Override
              public void run() {
                final long timestamp = texture.getTimestamp();
                // The texture's timestamp is updated on consumption.
                // We detect the change by asking very frequently.
                if (timestamp != lastTimestamp) {
                  lastTimestamp = timestamp;
                  framesConsumed.incrementAndGet();
                }
              }
            }, 0, 1);
            startTime = System.currentTimeMillis();
            result.success(null);
            break;
          case "stop":
            producerTimer.cancel();
            consumerTimer.cancel();
            endTime = System.currentTimeMillis();
            result.success(null);
            break;
          case "getProducedFrameRate":
            result.success(frameRate(framesProduced, startTime, endTime));
            break;
          case "getConsumedFrameRate":
            result.success(frameRate(framesConsumed, startTime, endTime));
            break;
          default: result.notImplemented();
        }
      }
    });

    getFlutterView().getHolder().addCallback(new SurfaceHolder.Callback() {
      @Override
      public void surfaceCreated(SurfaceHolder holder) {
        final SurfaceTextureEntry textureEntry = getFlutterView().createSurfaceTexture();
        texture = textureEntry.surfaceTexture();
        texture.setDefaultBufferSize(300, 200);
        surface = new Surface(texture);
      }

      @Override
      public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
      }

      @Override
      public void surfaceDestroyed(SurfaceHolder holder) {
      }
    });
  }

  double frameRate(AtomicInteger frameCounter, long startTime, long endTime) {
    return frameCounter.get() * 1000 / (double) (endTime - startTime);
  }

  @Override
  protected void onDestroy() {
    if (surface != null) {
      surface.release();
    }
    super.onDestroy();
  }
}

class FrameRenderer {
  private final Surface surface;
  private final Paint paint;
  private int frameCount = 0;

  FrameRenderer(Surface surface) {
    this.surface = surface;
    this.paint = new Paint();
    paint.setColor(0xffff0000);
    paint.setTextSize(48.0f);
    paint.setAntiAlias(true);
  }

  void drawFrame() {
    final Canvas canvas = surface.lockCanvas(null);
    canvas.drawColor(0xff000000);
    canvas.drawText(String.valueOf(++frameCount), 20, 120, paint);
    surface.unlockCanvasAndPost(canvas);
  }
}

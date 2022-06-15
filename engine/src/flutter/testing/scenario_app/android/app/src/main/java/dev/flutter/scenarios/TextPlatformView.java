// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import android.content.Context;
import android.graphics.Color;
import android.view.Choreographer;
import android.view.View;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.platform.PlatformView;

public class TextPlatformView implements PlatformView {
  final TextView textView;

  @SuppressWarnings("unchecked")
  TextPlatformView(@NonNull final Context context, int id, @Nullable String params) {
    textView = new TextView(context);
    textView.setTextSize(72);
    textView.setBackgroundColor(Color.rgb(255, 255, 255));
    textView.setText(params);

    // Investigate why this is needed to pass some gold tests.
    Choreographer.getInstance()
        .postFrameCallbackDelayed(
            new Choreographer.FrameCallback() {
              @Override
              public void doFrame(long frameTimeNanos) {
                textView.invalidate();
              }
            },
            500);
  }

  @Override
  @NonNull
  public View getView() {
    return textView;
  }

  @Override
  public void dispose() {}
}

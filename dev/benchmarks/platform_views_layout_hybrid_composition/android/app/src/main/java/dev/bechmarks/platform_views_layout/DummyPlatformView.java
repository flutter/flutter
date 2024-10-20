// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.benchmarks.platform_views_layout_hybrid_composition;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.widget.TextView;
import io.flutter.plugin.platform.PlatformView;

public class DummyPlatformView implements PlatformView {
    private final TextView textView;

    @SuppressWarnings("unchecked")
    DummyPlatformView(final Context context, int id) {
        textView = new TextView(context);
        textView.setTextSize(72);
        textView.setBackgroundColor(Color.rgb(255, 255, 255));
        textView.setText("DummyPlatformView");
    }

    @Override
    public View getView() {
        return textView;
    }

    @Override
    public void dispose() {}
}

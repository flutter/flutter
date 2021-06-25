// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.integration_test_example;

import android.os.Bundle;
import dev.flutter.plugins.integration_test.IntegrationTestPlugin;
import io.flutter.embedding.android.FlutterActivity;



import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Instrumentation;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.Rect;
import android.graphics.Canvas;
import androidx.annotation.NonNull;
import androidx.test.platform.app.InstrumentationRegistry;
import java.io.ByteArrayOutputStream;
import io.flutter.util.PathUtils;
import java.io.FileOutputStream;
import java.io.File;
import android.content.Context;
import java.io.IOException;
import java.lang.IllegalStateException;
import android.view.View;
import android.view.PixelCopy;
import android.view.ViewGroup;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterImageView;

import android.os.Looper;
import android.os.Handler;
import java.util.concurrent.Future;
import android.view.Choreographer;

public class EmbedderV1Activity extends FlutterActivity {

    static FlutterView getFlutterView(Activity activity) {
      final ViewGroup root = (ViewGroup)activity.findViewById(android.R.id.content);
      return (FlutterView)(((ViewGroup)root.getChildAt(0)).getChildAt(0));
    }

    static String getViewName(View view) {
      if (view instanceof FlutterImageView) {
          return "FlutterImageView";
      }
      if (view instanceof FlutterSurfaceView) {
          view.setAlpha(0.0f);
          return "FlutterSurfaceView";
      }
      if (view instanceof FlutterTextureView) {
          return "FlutterTextureView";
      }
      if (view instanceof FlutterView) {
          return "FlutterView";
      }
      if (view instanceof ViewGroup) {
          return "ViewGroup";
      }
      return "View";
  }
  
  static void recurseViewHierarchy(View current, String padding, StringBuilder builder) {
      if (current.getVisibility() != View.VISIBLE || current.getAlpha() == 0) {
          return;
      }
      String name = getViewName(current);
      builder.append(padding);
      builder.append("|-");
      builder.append(name);
      builder.append("\n");
  
      if (current instanceof ViewGroup) {
          ViewGroup viewGroup = (ViewGroup) current;
          for (int index = 0; index < viewGroup.getChildCount(); index++) {
              recurseViewHierarchy(viewGroup.getChildAt(index), padding + "  ", builder);
          }
      }
  }
  
  /**
   * Serializes the view hierarchy, so it can be sent to Dart over the method channel.
   *
   * Notation:
   * |- <view-name>
   *   |- ... child view ordered by z order.
   *
   * Example output:
   * |- FlutterView
   *   |- FlutterImageView
   *      |- ViewGroup
   *        |- View
   */
  static String getSerializedViewHierarchy(View root) {
      StringBuilder builder = new StringBuilder();
      recurseViewHierarchy(root, "", builder);
      return builder.toString();
  }
  
  static boolean hasInstrumentation() {
      try {
        return InstrumentationRegistry.getInstrumentation() != null;
      } catch (IllegalStateException exception) {
        return false;
      }
    }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    final FlutterView flutterView = getFlutterView(this);

    io.flutter.Log.d("flutter 1", getSerializedViewHierarchy(flutterView));

  }
}

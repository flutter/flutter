// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.view.View;

class FlutterMeasureSpec {

  interface MeasureCallback {
    void onMeasure(int finalWidth, int finalHeight);
  };

  /**
   * SurfaceView Has No Intrinsic Size: Unlike a TextView which can measure its text or an ImageView
   * which can measure its image, a SurfaceView has no content of its own to measure by default. Its
   * content is drawn externally by the Flutter engine. Therefore, when asked how big it wants to
   * be, the default onMeasure() implementation has no information to work with and reports a size
   * of 0 (or sometimes the minimum size of the view).
   *
   * @param widthMeasureSpec horizontal space requirements as imposed by the parent. The
   *     requirements are encoded with {@link android.view.View.MeasureSpec}.
   * @param heightMeasureSpec vertical space requirements as imposed by the parent. The requirements
   *     are encoded with {@link android.view.View.MeasureSpec}.
   */
  static void onMeasure(int widthMeasureSpec, int heightMeasureSpec, MeasureCallback callback) {
    int widthMode = View.MeasureSpec.getMode(widthMeasureSpec);
    int parentSuggestedWidth = View.MeasureSpec.getSize(widthMeasureSpec);
    int heightMode = View.MeasureSpec.getMode(heightMeasureSpec);
    int parentSuggestedHeight = View.MeasureSpec.getSize(heightMeasureSpec);

    // Unspecified means the parent is set to wrap_content, default it to 1 px to allow the engine
    // to start up on the creation of the surface, then constraints will trigger the framework to
    // content size the view.  The size will be reported back.
    int finalHeight =
        Math.max(parentSuggestedHeight, heightMode == View.MeasureSpec.UNSPECIFIED ? 1 : 0);
    int finalWidth =
        Math.max(parentSuggestedWidth, widthMode == View.MeasureSpec.UNSPECIFIED ? 1 : 0);

    callback.onMeasure(finalWidth, finalHeight);
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.mutatorsstack;

import static android.view.View.OnFocusChangeListener;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RenderEffect;
import android.graphics.RuntimeShader;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.accessibility.AccessibilityEvent;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.util.ViewUtils;

/**
 * A view that applies the {@link io.flutter.embedding.engine.mutatorsstack.FlutterMutatorsStack} to
 * its children.
 */
public class FlutterMutatorView extends FrameLayout {
  private FlutterMutatorsStack mutatorsStack;
  private float screenDensity;
  private int left;
  private int top;

  private final AndroidTouchProcessor androidTouchProcessor;
  private Paint paint;

  private static final String STRETCH_SHADER =
      "uniform float u_overscroll_x;\n"
          + "uniform float u_overscroll_y;\n"
          + "uniform float u_interpolation_strength;\n"
          + "uniform shader u_texture;\n"
          + "uniform vec2 u_size;\n"
          + "float ease_in(float t, float d) { return t * d; }\n"
          + "float compute_overscroll_start(float in_pos, float overscroll, float u_stretch_affected_dist, float u_inverse_stretch_affected_dist, float distance_stretched, float interpolation_strength) {\n"
          + "  float offset_pos = u_stretch_affected_dist - in_pos;\n"
          + "  float pos_based_variation = mix(1.0, ease_in(offset_pos, u_inverse_stretch_affected_dist), interpolation_strength);\n"
          + "  float stretch_intensity = overscroll * pos_based_variation;\n"
          + "  return distance_stretched - (offset_pos / (1.0 + stretch_intensity));\n"
          + "}\n"
          + "float compute_overscroll_end(float in_pos, float overscroll, float reverse_stretch_dist, float u_stretch_affected_dist, float u_inverse_stretch_affected_dist, float distance_stretched, float interpolation_strength, float viewport_dimension) {\n"
          + "  float offset_pos = in_pos - reverse_stretch_dist;\n"
          + "  float pos_based_variation = mix(1.0, ease_in(offset_pos, u_inverse_stretch_affected_dist), interpolation_strength);\n"
          + "  float stretch_intensity = (-overscroll) * pos_based_variation;\n"
          + "  return viewport_dimension - (distance_stretched - (offset_pos / (1.0 + stretch_intensity)));\n"
          + "}\n"
          + "float compute_streched_effect(float in_pos, float overscroll, float u_stretch_affected_dist, float u_inverse_stretch_affected_dist, float distance_stretched, float distance_diff, float interpolation_strength, float viewport_dimension) {\n"
          + "  if (overscroll > 0.0) {\n"
          + "    if (in_pos <= u_stretch_affected_dist) { return compute_overscroll_start(in_pos, overscroll, u_stretch_affected_dist, u_inverse_stretch_affected_dist, distance_stretched, interpolation_strength); }\n"
          + "    else { return distance_diff + in_pos; }\n"
          + "  } else if (overscroll < 0.0) {\n"
          + "    float stretch_affected_dist_calc = viewport_dimension - u_stretch_affected_dist;\n"
          + "    if (in_pos >= stretch_affected_dist_calc) { return compute_overscroll_end(in_pos, overscroll, stretch_affected_dist_calc, u_stretch_affected_dist, u_inverse_stretch_affected_dist, distance_stretched, interpolation_strength, viewport_dimension); }\n"
          + "    else { return -distance_diff + in_pos; }\n"
          + "  } else { return in_pos; }\n"
          + "}\n"
          + "half4 main(vec2 fragCoord) {\n"
          // fragCoord and u_texture.eval() both operate in the rendered view's
          // pixel space, whose dimensions are u_size. Normalize and de-normalize
          // by that single size so the mapping is self-consistent and
          // density-independent (mirrors shaders/stretch_effect.frag).
          + "  vec2 uv = fragCoord / u_size;\n"
          + "  float overscroll = u_overscroll_y != 0.0 ? u_overscroll_y : u_overscroll_x;\n"
          + "  float distance_stretched = 1.0 / (1.0 + abs(overscroll));\n"
          + "  float distance_diff = distance_stretched - 1.0;\n"
          + "  float out_u_norm = u_overscroll_y != 0.0 ? uv.x : compute_streched_effect(uv.x, overscroll, 1.0, 1.0, distance_stretched, distance_diff, u_interpolation_strength, 1.0);\n"
          + "  float out_v_norm = u_overscroll_y != 0.0 ? compute_streched_effect(uv.y, overscroll, 1.0, 1.0, distance_stretched, distance_diff, u_interpolation_strength, 1.0) : uv.y;\n"
          + "  return u_texture.eval(vec2(out_u_norm, out_v_norm) * u_size);\n"
          + "}\n";

  /**
   * Initialize the FlutterMutatorView. Use this to set the screenDensity, which will be used to
   * correct the final transform matrix.
   */
  public FlutterMutatorView(
      @NonNull Context context,
      float screenDensity,
      @Nullable AndroidTouchProcessor androidTouchProcessor) {
    super(context, null);
    this.screenDensity = screenDensity;
    this.androidTouchProcessor = androidTouchProcessor;
    this.paint = new Paint();
  }

  /** Initialize the FlutterMutatorView. */
  public FlutterMutatorView(@NonNull Context context) {
    this(context, 1, /* androidTouchProcessor=*/ null);
  }

  @Nullable @VisibleForTesting ViewTreeObserver.OnGlobalFocusChangeListener activeFocusListener;

  /**
   * Sets a focus change listener that notifies when the current view or any of its descendant views
   * have received focus.
   *
   * <p>If there's an active focus listener, it will first remove the current listener, and then add
   * the new one.
   *
   * @param userFocusListener A user provided focus listener.
   */
  public void setOnDescendantFocusChangeListener(@NonNull OnFocusChangeListener userFocusListener) {
    unsetOnDescendantFocusChangeListener();

    final View mutatorView = this;
    final ViewTreeObserver observer = getViewTreeObserver();
    if (observer.isAlive() && activeFocusListener == null) {
      activeFocusListener =
          new ViewTreeObserver.OnGlobalFocusChangeListener() {
            @Override
            public void onGlobalFocusChanged(View oldFocus, View newFocus) {
              userFocusListener.onFocusChange(mutatorView, ViewUtils.childHasFocus(mutatorView));
            }
          };
      observer.addOnGlobalFocusChangeListener(activeFocusListener);
    }
  }

  /** Unsets any active focus listener. */
  public void unsetOnDescendantFocusChangeListener() {
    final ViewTreeObserver observer = getViewTreeObserver();
    if (observer.isAlive() && activeFocusListener != null) {
      final ViewTreeObserver.OnGlobalFocusChangeListener currFocusListener = activeFocusListener;
      activeFocusListener = null;
      observer.removeOnGlobalFocusChangeListener(currFocusListener);
    }
  }

  /**
   * Pass the necessary parameters to the view so it can apply correct mutations to its children.
   */
  public void readyToDisplay(
      @NonNull FlutterMutatorsStack mutatorsStack, int left, int top, int width, int height) {
    this.mutatorsStack = mutatorsStack;
    this.left = left;
    this.top = top;
    FrameLayout.LayoutParams layoutParams =
        new FrameLayout.LayoutParams(width, height, Gravity.LEFT | Gravity.TOP);
    layoutParams.leftMargin = left;
    layoutParams.topMargin = top;
    setLayoutParams(layoutParams);
    setWillNotDraw(false);

    if (android.os.Build.VERSION.SDK_INT >= io.flutter.Build.API_LEVELS.API_31) {
      float totalXStretch = 0.0f;
      float totalYStretch = 0.0f;
      for (FlutterMutatorsStack.FlutterMutator mutator : mutatorsStack.getMutators()) {
        if (mutator.getType() == FlutterMutatorsStack.FlutterMutatorType.STRETCH_OVERSCROLL) {
          totalXStretch += mutator.getXStretch();
          totalYStretch += mutator.getYStretch();
        }
      }
      if (totalXStretch != 0.0f || totalYStretch != 0.0f) {
        RuntimeShader shader = new RuntimeShader(STRETCH_SHADER);
        shader.setFloatUniform("u_overscroll_x", totalXStretch);
        shader.setFloatUniform("u_overscroll_y", totalYStretch);
        shader.setFloatUniform("u_interpolation_strength", 0.7f);
        shader.setFloatUniform("u_size", (float) width, (float) height);
        this.setRenderEffect(RenderEffect.createRuntimeShaderEffect(shader, "u_texture"));
      } else {
        this.setRenderEffect(null);
      }
    }
  }

  @Override
  public void draw(Canvas canvas) {
    // Apply all clippings on the parent canvas.
    canvas.save();
    for (Path path : mutatorsStack.getFinalClippingPaths()) {
      // Reverse the current offset.
      //
      // The frame of this view includes the final offset of the bounding rect.
      // We need to apply all the mutators to the view, which includes the mutation that leads to
      // the final offset. We should reverse this final offset, both as a translate mutation and to
      // all the clipping paths
      Path pathCopy = new Path(path);
      pathCopy.offset(-left, -top);
      canvas.clipPath(pathCopy);
    }

    int newAlpha = (int) (255 * mutatorsStack.getFinalOpacity());
    boolean shouldApplyOpacity = paint.getAlpha() != newAlpha;
    if (shouldApplyOpacity) {
      paint.setAlpha((int) (255 * mutatorsStack.getFinalOpacity()));
      this.setLayerType(View.LAYER_TYPE_HARDWARE, paint);
    }

    super.draw(canvas);
    canvas.restore();
  }

  @Override
  public void dispatchDraw(Canvas canvas) {
    // Apply all the transforms on the child canvas.
    canvas.save();

    canvas.concat(getPlatformViewMatrix());
    super.dispatchDraw(canvas);
    canvas.restore();
  }

  private Matrix getPlatformViewMatrix() {
    Matrix finalMatrix = new Matrix(mutatorsStack.getFinalMatrix());

    // Reverse scale based on screen scale.
    //
    // The Android frame is set based on the logical resolution instead of physical.
    // (https://developer.android.com/training/multiscreen/screendensities).
    // However, flow is based on the physical resolution. For example, 1000 pixels in flow equals
    // 500 points in Android. And until this point, we did all the calculation based on the flow
    // resolution. So we need to scale down to match Android's logical resolution.
    finalMatrix.preScale(1 / screenDensity, 1 / screenDensity);

    // Reverse the current offset.
    //
    // The frame of this view includes the final offset of the bounding rect.
    // We need to apply all the mutators to the view, which includes the mutation that leads to
    // the final offset. We should reverse this final offset, both as a translate mutation and to
    // all the clipping paths
    finalMatrix.postTranslate(-left, -top);

    return finalMatrix;
  }

  /** Intercept the events here and do not propagate them to the child platform views. */
  @Override
  public boolean onInterceptTouchEvent(MotionEvent event) {
    return true;
  }

  @Override
  public boolean requestSendAccessibilityEvent(View child, AccessibilityEvent event) {
    final View embeddedView = getChildAt(0);
    if (embeddedView != null
        && embeddedView.getImportantForAccessibility()
            == View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS) {
      return false;
    }
    // Forward the request only if the embedded view is in the Flutter accessibility tree.
    // The embedded view may be ignored when the framework doesn't populate a SemanticNode
    // for the current platform view.
    // See AccessibilityBridge for more.
    return super.requestSendAccessibilityEvent(child, event);
  }

  @Override
  @SuppressLint("ClickableViewAccessibility")
  public boolean onTouchEvent(MotionEvent event) {
    if (androidTouchProcessor == null) {
      return super.onTouchEvent(event);
    }
    final Matrix screenMatrix = new Matrix();
    screenMatrix.postTranslate(getLeft(), getTop());
    return androidTouchProcessor.onTouchEvent(event, screenMatrix);
  }
}

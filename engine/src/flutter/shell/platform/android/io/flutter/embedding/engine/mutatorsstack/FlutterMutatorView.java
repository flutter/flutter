// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.mutatorsstack;

import static android.view.View.OnFocusChangeListener;
import static io.flutter.Build.API_LEVELS;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.RenderEffect;
import android.graphics.RuntimeShader;
import android.os.Build;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.accessibility.AccessibilityEvent;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.plugin.platform.PlatformViewGestureTracker;
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
  private int width;
  private int height;
  private int viewOriginLeft;
  private int viewOriginTop;
  private boolean hasActiveRenderEffect = false;
  private boolean useMatrixStretchFallback = false;
  private boolean hasScaledSurfaceViewChild = false;
  private float savedChildScaleX = 1.0f;
  private float savedChildScaleY = 1.0f;
  private float savedChildPivotX = 0.0f;
  private float savedChildPivotY = 0.0f;
  private final Matrix stretchMatrix = new Matrix();

  private static final Class[] VIEW_TYPES_REQUIRE_NO_SHADER_STRETCH = {SurfaceView.class};
  @Nullable private Boolean cachedHasChildSurfaceView = null;

  // Each FlutterMutatorView instance owns its own RuntimeShader so that when two
  // or more platform views stretch simultaneously in the same frame, updating
  // u_pv_rect / u_container uniforms on one view never clobbers another view's
  // shader state.
  @Nullable private RuntimeShader cachedStretchShader;
  private static boolean stretchShaderInitFailed = false;
  private float lastOverscrollX = Float.NaN;
  private float lastOverscrollY = Float.NaN;
  private float lastInterpolationStrength = Float.NaN;
  private final RectF lastContainerRect = new RectF();
  private final RectF lastPvRect = new RectF();

  // Pre-bundled AGSL stretch shader matching Impeller's stretch_filter.frag and
  // Android's hwui/effects/StretchEffect.cpp. Evaluates the platform view's
  // sub-span within the viewport container (u_container) and returns transparent
  // black for any source coordinate outside the unstretched platform view bounds
  // (u_pv_rect).
  private static final String STRETCH_EFFECT_AGSL =
      "uniform shader u_texture;\n"
          + "uniform float4 u_container;\n"
          + "uniform float4 u_pv_rect;\n"
          + "uniform float u_overscroll_x;\n"
          + "uniform float u_overscroll_y;\n"
          + "uniform float u_interpolation_strength;\n"
          + "\n"
          + "float computeOverscroll(\n"
          + "    float in_pos,\n"
          + "    float overscroll,\n"
          + "    float interpolation_strength) {\n"
          + "  if (abs(overscroll) <= 0.0001) {\n"
          + "    return in_pos;\n"
          + "  }\n"
          + "  float p = abs(overscroll);\n"
          + "  float u_d = 1.0 / (1.0 + p);\n"
          + "  float u_s = 1.0 + p * (1.0 - interpolation_strength);\n"
          + "  if (overscroll > 0.0) {\n"
          + "    float e = 1.0 - in_pos;\n"
          + "    float c = e / (u_s + (p * e) * interpolation_strength);\n"
          + "    return u_d - c;\n"
          + "  } else {\n"
          + "    float e = in_pos;\n"
          + "    float c = e / (u_s + (p * e) * interpolation_strength);\n"
          + "    return 1.0 - u_d + c;\n"
          + "  }\n"
          + "}\n"
          + "\n"
          + "half4 main(float2 fragCoord) {\n"
          + "  float2 containerOrigin = u_container.xy;\n"
          + "  float2 containerSize = max(u_container.zw - u_container.xy, float2(1.0));\n"
          + "  float2 rel = (fragCoord - containerOrigin) / containerSize;\n"
          + "  float srcRelX = (rel.x >= 0.0 && rel.x <= 1.0)\n"
          + "      ? computeOverscroll(rel.x, u_overscroll_x, u_interpolation_strength)\n"
          + "      : rel.x;\n"
          + "  float srcRelY = (rel.y >= 0.0 && rel.y <= 1.0)\n"
          + "      ? computeOverscroll(rel.y, u_overscroll_y, u_interpolation_strength)\n"
          + "      : rel.y;\n"
          + "  float2 src = containerOrigin + float2(srcRelX, srcRelY) * containerSize;\n"
          + "  if (src.x < u_pv_rect.x || src.x > u_pv_rect.z ||\n"
          + "      src.y < u_pv_rect.y || src.y > u_pv_rect.w) {\n"
          + "    return half4(0.0);\n"
          + "  }\n"
          + "  return u_texture.eval(src);\n"
          + "}\n";

  private final AndroidTouchProcessor androidTouchProcessor;
  private final PlatformViewGestureTracker gestureTracker = new PlatformViewGestureTracker();
  private Paint paint;

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
    this.width = width;
    this.height = height;

    FlutterMutatorsStack.FlutterStretchEffect stretch =
        mutatorsStack == null ? null : mutatorsStack.getFinalStretchEffect();
    boolean isStretchActive = stretch != null && stretch.isActive() && width > 0 && height > 0;

    int layoutLeft = left;
    int layoutTop = top;
    int layoutWidth = width;
    int layoutHeight = height;

    if (!isStretchActive) {
      if (hasActiveRenderEffect && Build.VERSION.SDK_INT >= API_LEVELS.API_33) {
        clearStretchRenderEffect();
      }
      resetChildScaleIfNeeded();
      cachedHasChildSurfaceView = null;
      useMatrixStretchFallback = false;
      stretchMatrix.reset();
    } else {
      RectF stretchedRect = computeStretchedRect(left, top, width, height, stretch);
      boolean hasSurfaceView = hasChildSurfaceView();
      boolean appliedShader = false;

      if (Build.VERSION.SDK_INT >= API_LEVELS.API_33 && !hasSurfaceView) {
        int uLeft = (int) Math.floor(Math.min(left, stretchedRect.left));
        int uTop = (int) Math.floor(Math.min(top, stretchedRect.top));
        int uRight = (int) Math.ceil(Math.max(left + width, stretchedRect.right));
        int uBottom = (int) Math.ceil(Math.max(top + height, stretchedRect.bottom));
        appliedShader = applyStretchRenderEffect(stretch, uLeft, uTop);
        if (appliedShader) {
          resetChildScaleIfNeeded();
          useMatrixStretchFallback = false;
          stretchMatrix.reset();
          layoutLeft = uLeft;
          layoutTop = uTop;
          layoutWidth = Math.max(0, uRight - uLeft);
          layoutHeight = Math.max(0, uBottom - uTop);
        }
      }

      if (!appliedShader) {
        if (hasActiveRenderEffect && Build.VERSION.SDK_INT >= API_LEVELS.API_33) {
          clearStretchRenderEffect();
        }
        // Apply a scale and translation Matrix transform fallback mapping the
        // unstretched platform view bounds [v0, v1] onto the stretched bounds
        // [v0', v1'] when a SurfaceView child is present or on API < 33.
        int stLeft = Math.round(stretchedRect.left);
        int stTop = Math.round(stretchedRect.top);
        int stRight = Math.round(stretchedRect.right);
        int stBottom = Math.round(stretchedRect.bottom);
        int stWidth = Math.max(0, stRight - stLeft);
        int stHeight = Math.max(0, stBottom - stTop);

        float scaleX = stWidth / (float) width;
        float scaleY = stHeight / (float) height;
        useMatrixStretchFallback = true;
        stretchMatrix.reset();
        stretchMatrix.setScale(scaleX, scaleY);

        if (hasSurfaceView) {
          View child = getChildAt(0);
          if (child != null) {
            if (!hasScaledSurfaceViewChild) {
              savedChildScaleX = child.getScaleX();
              savedChildScaleY = child.getScaleY();
              savedChildPivotX = child.getPivotX();
              savedChildPivotY = child.getPivotY();
            }
            child.setPivotX(0.0f);
            child.setPivotY(0.0f);
            child.setScaleX(scaleX);
            child.setScaleY(scaleY);
            hasScaledSurfaceViewChild = true;
          }
        } else {
          resetChildScaleIfNeeded();
        }

        layoutLeft = stLeft;
        layoutTop = stTop;
        layoutWidth = stWidth;
        layoutHeight = stHeight;
      }
    }

    this.viewOriginLeft = layoutLeft;
    this.viewOriginTop = layoutTop;
    FrameLayout.LayoutParams layoutParams =
        new FrameLayout.LayoutParams(layoutWidth, layoutHeight, Gravity.LEFT | Gravity.TOP);
    layoutParams.leftMargin = layoutLeft;
    layoutParams.topMargin = layoutTop;
    setLayoutParams(layoutParams);
    setWillNotDraw(false);
  }

  private boolean hasChildSurfaceView() {
    if (cachedHasChildSurfaceView == null) {
      cachedHasChildSurfaceView =
          ViewUtils.hasChildViewOfType(this, VIEW_TYPES_REQUIRE_NO_SHADER_STRETCH);
    }
    return cachedHasChildSurfaceView;
  }

  @Override
  public void onViewAdded(View child) {
    super.onViewAdded(child);
    cachedHasChildSurfaceView = null;
  }

  @Override
  public void onViewRemoved(View child) {
    super.onViewRemoved(child);
    cachedHasChildSurfaceView = null;
  }

  private void resetChildScaleIfNeeded() {
    if (hasScaledSurfaceViewChild) {
      View child = getChildAt(0);
      if (child != null) {
        child.setScaleX(savedChildScaleX);
        child.setScaleY(savedChildScaleY);
        child.setPivotX(savedChildPivotX);
        child.setPivotY(savedChildPivotY);
      }
      hasScaledSurfaceViewChild = false;
    }
  }

  @RequiresApi(API_LEVELS.API_33)
  @Nullable
  @VisibleForTesting
  RuntimeShader getOrCreateStretchShader() {
    if (stretchShaderInitFailed) {
      return null;
    }
    if (cachedStretchShader == null) {
      try {
        cachedStretchShader = new RuntimeShader(STRETCH_EFFECT_AGSL);
      } catch (IllegalArgumentException e) {
        stretchShaderInitFailed = true;
        return null;
      }
    }
    return cachedStretchShader;
  }

  @RequiresApi(API_LEVELS.API_33)
  private boolean applyStretchRenderEffect(
      @NonNull FlutterMutatorsStack.FlutterStretchEffect stretch, int originLeft, int originTop) {
    float cLeft = stretch.rect.left - originLeft;
    float cTop = stretch.rect.top - originTop;
    float cRight = stretch.rect.right - originLeft;
    float cBottom = stretch.rect.bottom - originTop;
    float pvLeft = left - originLeft;
    float pvTop = top - originTop;
    float pvRight = left - originLeft + width;
    float pvBottom = top - originTop + height;

    if (hasActiveRenderEffect
        && stretch.overscrollX == lastOverscrollX
        && stretch.overscrollY == lastOverscrollY
        && stretch.interpolationStrength == lastInterpolationStrength
        && lastContainerRect.left == cLeft
        && lastContainerRect.top == cTop
        && lastContainerRect.right == cRight
        && lastContainerRect.bottom == cBottom
        && lastPvRect.left == pvLeft
        && lastPvRect.top == pvTop
        && lastPvRect.right == pvRight
        && lastPvRect.bottom == pvBottom) {
      return true;
    }

    RuntimeShader shader = getOrCreateStretchShader();
    if (shader == null) {
      return false;
    }
    try {
      shader.setFloatUniform("u_container", cLeft, cTop, cRight, cBottom);
      shader.setFloatUniform("u_pv_rect", pvLeft, pvTop, pvRight, pvBottom);
      shader.setFloatUniform("u_overscroll_x", stretch.overscrollX);
      shader.setFloatUniform("u_overscroll_y", stretch.overscrollY);
      shader.setFloatUniform("u_interpolation_strength", stretch.interpolationStrength);
      RenderEffect effect = RenderEffect.createRuntimeShaderEffect(shader, "u_texture");
      if (effect == null) {
        return false;
      }
      setRenderEffect(effect);
      hasActiveRenderEffect = true;
      lastOverscrollX = stretch.overscrollX;
      lastOverscrollY = stretch.overscrollY;
      lastInterpolationStrength = stretch.interpolationStrength;
      lastContainerRect.set(cLeft, cTop, cRight, cBottom);
      lastPvRect.set(pvLeft, pvTop, pvRight, pvBottom);
      return true;
    } catch (IllegalArgumentException e) {
      stretchShaderInitFailed = true;
      return false;
    }
  }

  @RequiresApi(API_LEVELS.API_33)
  private void clearStretchRenderEffect() {
    setRenderEffect(null);
    hasActiveRenderEffect = false;
    lastOverscrollX = Float.NaN;
    lastOverscrollY = Float.NaN;
    lastInterpolationStrength = Float.NaN;
  }

  /**
   * Computes the forward stretched normalized coordinate in [0, 1] for a given unstretched
   * normalized coordinate {@code srcNorm} in [0, 1].
   *
   * <p>This is the exact algebraic inverse of {@code computeOverscroll} in {@link
   * #STRETCH_EFFECT_AGSL}.
   */
  @VisibleForTesting
  static float computeStretchedPosition(
      float srcNorm, float overscroll, float interpolationStrength) {
    if (Math.abs(overscroll) <= 1e-4f) {
      return srcNorm;
    }
    float p = Math.abs(overscroll);
    float d = 1.0f / (1.0f + p);
    float a = 1.0f + p * (1.0f - interpolationStrength);
    float b = p * interpolationStrength;
    if (overscroll > 0.0f) {
      float delta = d - srcNorm;
      if (delta <= 0.0f) {
        return 1.0f;
      }
      float denom = 1.0f - delta * b;
      if (denom <= 1e-6f) {
        return 1.0f;
      }
      float u = (delta * a) / denom;
      return Math.max(0.0f, Math.min(1.0f, 1.0f - u));
    } else {
      float delta = d - (1.0f - srcNorm);
      if (delta <= 0.0f) {
        return 0.0f;
      }
      float denom = 1.0f - delta * b;
      if (denom <= 1e-6f) {
        return 0.0f;
      }
      float u = (delta * a) / denom;
      return Math.max(0.0f, Math.min(1.0f, u));
    }
  }

  @NonNull
  @VisibleForTesting
  static RectF computeStretchedRect(
      int left,
      int top,
      int width,
      int height,
      @NonNull FlutterMutatorsStack.FlutterStretchEffect stretch) {
    RectF container = stretch.getRect();
    float cLeft = container.left;
    float cTop = container.top;
    float cWidth = container.width();
    float cHeight = container.height();

    float stLeft = left;
    float stRight = left + width;
    if (cWidth > 0.0f && Math.abs(stretch.getOverscrollX()) > 1e-4f) {
      float normL = (left - cLeft) / cWidth;
      if (normL >= 0.0f && normL <= 1.0f) {
        stLeft =
            cLeft
                + computeStretchedPosition(
                        normL, stretch.getOverscrollX(), stretch.getInterpolationStrength())
                    * cWidth;
      }
      float normR = (left + width - cLeft) / cWidth;
      if (normR >= 0.0f && normR <= 1.0f) {
        stRight =
            cLeft
                + computeStretchedPosition(
                        normR, stretch.getOverscrollX(), stretch.getInterpolationStrength())
                    * cWidth;
      }
    }

    float stTop = top;
    float stBottom = top + height;
    if (cHeight > 0.0f && Math.abs(stretch.getOverscrollY()) > 1e-4f) {
      float normT = (top - cTop) / cHeight;
      if (normT >= 0.0f && normT <= 1.0f) {
        stTop =
            cTop
                + computeStretchedPosition(
                        normT, stretch.getOverscrollY(), stretch.getInterpolationStrength())
                    * cHeight;
      }
      float normB = (top + height - cTop) / cHeight;
      if (normB >= 0.0f && normB <= 1.0f) {
        stBottom =
            cTop
                + computeStretchedPosition(
                        normB, stretch.getOverscrollY(), stretch.getInterpolationStrength())
                    * cHeight;
      }
    }

    return new RectF(
        Math.min(stLeft, stRight),
        Math.min(stTop, stBottom),
        Math.max(stLeft, stRight),
        Math.max(stTop, stBottom));
  }

  @VisibleForTesting
  boolean hasActiveStretchRenderEffect() {
    return hasActiveRenderEffect;
  }

  @VisibleForTesting
  boolean isUsingMatrixStretchFallback() {
    return useMatrixStretchFallback;
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
      // all the clipping paths.
      //
      // Note on stretch + clipping order: Android applies a view's RenderEffect to the output of
      // its draw(Canvas) pass, so canvas.clipPath here always executes in unstretched coordinates
      // before the stretch RenderEffect. For the standard StretchingOverscrollIndicator (which
      // places its viewport ClipRect outside the StretchEffect), the clip matches u_container
      // (which maps [0, 1] -> [0, 1] under stretch), and offsetting by (-viewOriginLeft,
      // -viewOriginTop) keeps an inner clip aligned with the unstretched child view before the
      // RenderEffect stretches it.
      Path pathCopy = new Path(path);
      if (useMatrixStretchFallback) {
        pathCopy.offset(-left, -top);
        pathCopy.transform(stretchMatrix);
      } else {
        pathCopy.offset(-viewOriginLeft, -viewOriginTop);
      }
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

    if (hasScaledSurfaceViewChild) {
      Matrix baseMatrix = new Matrix(mutatorsStack.getFinalMatrix());
      baseMatrix.preScale(1 / screenDensity, 1 / screenDensity);
      baseMatrix.postTranslate(-left, -top);
      canvas.concat(baseMatrix);
    } else {
      canvas.concat(getPlatformViewMatrix());
    }
    super.dispatchDraw(canvas);
    canvas.restore();
  }

  @VisibleForTesting
  Matrix getPlatformViewMatrix() {
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
    if (useMatrixStretchFallback) {
      finalMatrix.postTranslate(-left, -top);
      finalMatrix.postConcat(stretchMatrix);
    } else {
      finalMatrix.postTranslate(-viewOriginLeft, -viewOriginTop);
    }

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

  /**
   * Informs this view that Flutter has won the gesture arena for the active touch sequence.
   *
   * <p>Subsequent {@link MotionEvent#ACTION_MOVE} events will request unbuffered dispatch to
   * minimize latency and prevent stutter for Flutter-driven gestures (e.g., scrolling).
   *
   * @param gestureId The identifier (downTime) of the gesture that Flutter won. Unbuffered dispatch
   *     is only enabled if this matches the currently active gesture's downTime.
   */
  public void onFlutterWonGesture(long gestureId) {
    gestureTracker.onFlutterWonGesture(gestureId);
  }

  @VisibleForTesting
  public boolean getFlutterWonGesture() {
    return gestureTracker.getFlutterWonGesture();
  }

  @VisibleForTesting
  boolean isGestureActive() {
    return gestureTracker.isGestureActive();
  }

  @VisibleForTesting
  long getCurrentDownTime() {
    return gestureTracker.getCurrentDownTime();
  }

  @VisibleForTesting
  void requestUnbuffered(MotionEvent event) {
    requestUnbufferedDispatch(event);
  }

  @Override
  @SuppressLint("ClickableViewAccessibility")
  public boolean onTouchEvent(MotionEvent event) {
    if (androidTouchProcessor == null) {
      return super.onTouchEvent(event);
    }
    gestureTracker.onTouchEvent(event, this::requestUnbuffered);
    final Matrix screenMatrix = new Matrix();
    screenMatrix.postTranslate(getLeft(), getTop());
    return androidTouchProcessor.onTouchEvent(event, screenMatrix);
  }
}

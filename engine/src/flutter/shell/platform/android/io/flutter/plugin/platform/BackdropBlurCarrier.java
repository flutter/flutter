// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static io.flutter.Build.API_LEVELS;

import android.graphics.PixelFormat;
import android.graphics.RectF;
import android.os.Build;
import android.view.AttachedSurfaceControl;
import android.view.BlurRegion;
import android.view.RoundedRectBlurRegion;
import android.view.SurfaceControl;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.FrameLayout;
import androidx.annotation.ChecksSdkIntAtLeast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.UiThread;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.android.FlutterView;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.function.Consumer;

/**
 * Applies {@code BackdropFilter} blurs over Hybrid Composition++ platform views using
 * SurfaceFlinger.
 *
 * <p>Under HCPP a platform view's pixels never reach Flutter, so Flutter cannot blur them itself.
 * SurfaceFlinger is the only place where the Flutter background, the Android view hierarchy and any
 * child {@code SurfaceView}s are all composited on the same frame, and it can blur the content
 * behind a layer. Public API for that exists only on {@link SurfaceView#setBlurRegions} (API 37),
 * so this class adds one full-size, transparent, buffer-less {@link SurfaceView} (the "carrier") to
 * the {@link FlutterView} and hands it the blur regions each frame:
 *
 * <ul>
 *   <li>The carrier is composited above the window content (and therefore above platform views) via
 *       {@link SurfaceView#setCompositionOrder}. It never posts a buffer; SurfaceFlinger draws a
 *       layer that only has blur regions, so it costs no pixel memory.
 *   <li>The Flutter overlay {@link SurfaceControl} is reparented under {@link
 *       SurfaceView#getSurfaceControl()}, which the SurfaceView documentation describes as that
 *       method's "only well-defined usage". Children with z {@code >= 0} draw above their parent,
 *       so the filter's own children stay sharp above the blur.
 *   <li>{@code SurfaceView} applies blur regions from a RenderThread position listener that is
 *       merged into the same frame as the view hierarchy draw, which is also the frame {@link
 *       AttachedSurfaceControl#applyTransactionOnDraw} targets, so the blur tracks the overlay
 *       without lag.
 * </ul>
 *
 * <p>Known limitations: only Gaussian-style blur is supported (color filters and shaders in a
 * backdrop filter are dropped), regions are axis-aligned rounded rectangles, and Flutter content
 * painted between a platform view and the filter is composited above the blur rather than under it.
 *
 * <p>All methods must be called on the platform (UI) thread.
 */
class BackdropBlurCarrier {
  private static final String TAG = "BackdropBlurCarrier";

  /** Number of floats per blur sent by the engine: left, top, right, bottom, sigma, corner. */
  static final int BLUR_FIELDS = 6;

  /**
   * Composition order of the carrier relative to the window. Platform views that use {@link
   * SurfaceView#setZOrderOnTop} sit at 1; the carrier must be above them to blur them.
   */
  @VisibleForTesting static final int CARRIER_COMPOSITION_ORDER = 1000;

  /** Z of the Flutter overlay among the carrier's children (the carrier's own buffer is at -1). */
  private static final int OVERLAY_LAYER_Z = 1000;

  /**
   * SurfaceFlinger's blur "radius" is the Kawase pass radius, not a Gaussian sigma. This factor was
   * tuned by eye against Flutter's own Gaussian blur of the same sigma.
   */
  private static final float SIGMA_TO_BLUR_RADIUS = 2.0f;

  /** Minimum SDK with {@link SurfaceView#setBlurRegions}. */
  @ChecksSdkIntAtLeast(api = API_LEVELS.API_37)
  static boolean isSupported() {
    return Build.VERSION.SDK_INT >= API_LEVELS.API_37;
  }

  @Nullable private FlutterView flutterView;
  @Nullable private SurfaceView carrier;
  @Nullable private SurfaceControl overlay;
  private boolean overlayParentedToCarrier = false;
  private boolean hasBlurRegions = false;
  private boolean crossWindowBlurEnabled = true;
  @Nullable private Consumer<Boolean> blurEnabledListener;
  private boolean loggedBlurUnavailable = false;
  // Reused per frame to avoid garbage during animations; SurfaceView copies the regions.
  private final ArrayList<BlurRegion> scratchRegions = new ArrayList<>();

  /**
   * Attaches to a {@link FlutterView}. Creates the carrier eagerly so that its surface exists
   * before the first blurred frame; an idle carrier draws nothing and is skipped by SurfaceFlinger.
   */
  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  void attachToView(@NonNull FlutterView view) {
    if (!isSupported() || view.getContext() == null) {
      return;
    }
    flutterView = view;
    final WindowManager wm = view.getContext().getSystemService(WindowManager.class);
    if (wm != null) {
      crossWindowBlurEnabled = wm.isCrossWindowBlurEnabled();
      blurEnabledListener = this::onCrossWindowBlurEnabledChanged;
      wm.addCrossWindowBlurEnabledListener(blurEnabledListener);
    }
    ensureCarrier();
  }

  /** Detaches from the {@link FlutterView}, removing the carrier and its listeners. */
  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  void detachFromView() {
    if (flutterView == null) {
      return;
    }
    if (blurEnabledListener != null) {
      final WindowManager wm = flutterView.getContext().getSystemService(WindowManager.class);
      if (wm != null) {
        wm.removeCrossWindowBlurEnabledListener(blurEnabledListener);
      }
      blurEnabledListener = null;
    }
    // The overlay is destroyed by the controller on detach; make sure it is not left under a
    // SurfaceControl that is about to be released in case it outlives this call.
    reparentOverlayToRoot();
    if (carrier != null) {
      final ViewGroup parent = (ViewGroup) carrier.getParent();
      if (parent != null) {
        parent.removeView(carrier);
      }
      carrier = null;
    }
    hasBlurRegions = false;
    flutterView = null;
  }

  /**
   * Registers the Flutter overlay surface. Must be called whenever the controller creates a new
   * overlay {@link SurfaceControl}; it is reparented under the carrier if one is available.
   */
  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  void setOverlaySurfaceControl(@Nullable SurfaceControl overlaySurfaceControl) {
    if (overlay == overlaySurfaceControl) {
      return;
    }
    if (overlay != null && overlayParentedToCarrier) {
      // The controller is swapping overlays; put the old one back before it is released.
      reparentOverlayToRoot();
    }
    overlay = overlaySurfaceControl;
    overlayParentedToCarrier = false;
    reparentOverlayToCarrier();
  }

  /**
   * Applies this frame's backdrop blurs. Each blur is {@code [left, top, right, bottom, sigma,
   * cornerRadius]} in physical pixels, in the {@link FlutterView}'s coordinate space.
   *
   * @return whether native blur is available (API level, attachment and device settings). When
   *     false, the engine keeps applying backdrop filters to Flutter's own content and only the
   *     platform view stays sharp.
   */
  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  boolean onBackdropBlurs(@NonNull float[] blurs) {
    final int count = blurs.length / BLUR_FIELDS;
    if (!isSupported() || carrier == null) {
      if (count > 0 && !loggedBlurUnavailable) {
        Log.w(
            TAG,
            "A BackdropFilter blur covers a platform view, but native blur needs API "
                + API_LEVELS.API_37
                + ". The platform view will not be blurred. Use a texture-based platform view"
                + " mode if this effect is required.");
        loggedBlurUnavailable = true;
      }
      return false;
    }
    if (!crossWindowBlurEnabled) {
      if (count > 0 && !loggedBlurUnavailable) {
        Log.w(
            TAG,
            "A BackdropFilter blur covers a platform view, but cross-window blur is disabled on"
                + " this device. The platform view will not be blurred.");
        loggedBlurUnavailable = true;
      }
      clearBlurRegions();
      return false;
    }
    if (count > 0 || hasBlurRegions) {
      applyBlurRegions(blurs, count);
    }
    return true;
  }

  @RequiresApi(API_LEVELS.API_37)
  private void applyBlurRegions(@NonNull float[] blurs, int count) {
    scratchRegions.clear();
    for (int i = 0; i < count; i++) {
      final int base = i * BLUR_FIELDS;
      final float[] cornerRadii = new float[8];
      Arrays.fill(cornerRadii, blurs[base + 5]);
      scratchRegions.add(
          new RoundedRectBlurRegion(
              new RectF(blurs[base], blurs[base + 1], blurs[base + 2], blurs[base + 3]),
              cornerRadii,
              /* alpha= */ 1.0f,
              sigmaToBlurRadius(blurs[base + 4])));
    }
    carrier.setBlurRegions(scratchRegions);
    scratchRegions.clear();
    hasBlurRegions = count > 0;
    // The overlay may have been created after the carrier's surface.
    if (!overlayParentedToCarrier) {
      reparentOverlayToCarrier();
    }
  }

  @RequiresApi(API_LEVELS.API_37)
  private void clearBlurRegions() {
    if (carrier != null && hasBlurRegions) {
      carrier.setBlurRegions(null);
      hasBlurRegions = false;
    }
  }

  @UiThread
  @RequiresApi(API_LEVELS.API_34)
  private void onCrossWindowBlurEnabledChanged(boolean enabled) {
    crossWindowBlurEnabled = enabled;
    if (!enabled && isSupported()) {
      clearBlurRegions();
    }
    // When blur becomes available again the next frame's onBackdropBlurs re-applies the regions.
  }

  @RequiresApi(API_LEVELS.API_37)
  private void ensureCarrier() {
    if (carrier != null || flutterView == null) {
      return;
    }
    final SurfaceView view = new SurfaceView(flutterView.getContext());
    view.setCompositionOrder(CARRIER_COMPOSITION_ORDER);
    // No black background layer; the carrier never draws anything of its own.
    view.getHolder().setFormat(PixelFormat.TRANSLUCENT);
    // Keep the surface (and the overlay parented under it) across visibility changes.
    view.setSurfaceLifecycle(SurfaceView.SURFACE_LIFECYCLE_FOLLOWS_ATTACHMENT);
    // The carrier must be invisible to input and accessibility: touches fall through to the
    // platform views and FlutterView beneath it.
    view.setClickable(false);
    view.setFocusable(false);
    view.setFocusableInTouchMode(false);
    view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
    view.getHolder()
        .addCallback(
            new SurfaceHolder.Callback() {
              @Override
              public void surfaceCreated(@NonNull SurfaceHolder holder) {
                overlayParentedToCarrier = false;
                reparentOverlayToCarrier();
              }

              @Override
              public void surfaceChanged(
                  @NonNull SurfaceHolder holder, int format, int width, int height) {}

              @Override
              public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
                // The carrier's SurfaceControl is about to be released, which would take the
                // overlay with it.
                reparentOverlayToRoot();
                hasBlurRegions = false;
              }
            });
    flutterView.addView(
        view,
        new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    carrier = view;
  }

  /**
   * Makes the overlay a child of the carrier's SurfaceControl.
   *
   * <p>This is applied immediately rather than in the frame's synced transaction: the carrier is
   * created before any blur is requested and the overlay is reparented as soon as it exists, so the
   * reparent never races a frame that depends on it. Reparenting preserves the overlay's buffer and
   * visibility.
   */
  @RequiresApi(API_LEVELS.API_34)
  private void reparentOverlayToCarrier() {
    if (overlayParentedToCarrier || carrier == null || overlay == null || !overlay.isValid()) {
      return;
    }
    final SurfaceControl carrierSc = carrier.getSurfaceControl();
    if (carrierSc == null || !carrierSc.isValid()) {
      // Not created yet; surfaceCreated will retry.
      return;
    }
    final SurfaceControl.Transaction tx = new SurfaceControl.Transaction();
    tx.reparent(overlay, carrierSc).setLayer(overlay, OVERLAY_LAYER_Z).apply();
    tx.close();
    overlayParentedToCarrier = true;
  }

  /** Puts the overlay back under the window's root SurfaceControl. */
  @RequiresApi(API_LEVELS.API_34)
  private void reparentOverlayToRoot() {
    if (!overlayParentedToCarrier) {
      return;
    }
    overlayParentedToCarrier = false;
    if (overlay == null || !overlay.isValid() || flutterView == null) {
      return;
    }
    final AttachedSurfaceControl root = flutterView.getRootSurfaceControl();
    final SurfaceControl.Transaction tx =
        root == null ? null : root.buildReparentTransaction(overlay);
    if (tx != null) {
      tx.setLayer(overlay, OVERLAY_LAYER_Z).apply();
      tx.close();
      return;
    }
    // The window is gone (or refused), so there is no root to go back to. Detach the overlay
    // rather than let the carrier's SurfaceControl take it down when it is released; the
    // controller releases the overlay itself on detach.
    final SurfaceControl.Transaction detach = new SurfaceControl.Transaction();
    detach.reparent(overlay, null).apply();
    detach.close();
  }

  @VisibleForTesting
  static float sigmaToBlurRadius(float sigma) {
    return Math.max(0f, sigma * SIGMA_TO_BLUR_RADIUS);
  }

  @VisibleForTesting
  @Nullable
  SurfaceView getCarrierViewForTest() {
    return carrier;
  }

  /** Simulates the system toggling cross-window blur (e.g. battery saver). */
  @VisibleForTesting
  @RequiresApi(API_LEVELS.API_34)
  void setCrossWindowBlurEnabledForTest(boolean enabled) {
    onCrossWindowBlurEnabledChanged(enabled);
  }
}

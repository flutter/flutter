// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import java.nio.ByteBuffer;

/** Request sent from Flutter to create a new platform view. */
public class PlatformViewCreationRequest {
  /**
   * Platform view display modes that can be requested at creation time. Not used by Hybrid
   * Composition++ (HCPP), as HCPP always takes priority if enabled and does not use fallbacks in
   * the creation path, and as such does not need to be requested.
   */
  public enum RequestedDisplayMode {
    /**
     * Use Texture Layer Hybrid Composition (TLHC) if possible, falling back to Virtual Display (VD)
     * if not.
     */
    TEXTURE_WITH_VIRTUAL_FALLBACK,
    /**
     * Use Texture Layer Hybrid Composition (TLHC), falling back to Hybrid Composition (HC) if not.
     */
    TEXTURE_WITH_HYBRID_FALLBACK,
    /** Use Hybrid Composition (HC) in all cases. */
    HYBRID_ONLY,
  }

  /** The ID of the platform view as seen by the Flutter side. */
  public final int viewId;

  /** The type of Android {@code View} to create for this platform view. */
  @NonNull public final String viewType;

  /** The density independent width to display the platform view. */
  public final double logicalWidth;

  /** The density independent height to display the platform view. */
  public final double logicalHeight;

  /** The density independent top position to display the platform view. */
  public final double logicalTop;

  /** The density independent left position to display the platform view. */
  public final double logicalLeft;

  /**
   * The layout direction of the new platform view.
   *
   * <p>See {@link android.view.View#LAYOUT_DIRECTION_LTR} and {@link
   * android.view.View#LAYOUT_DIRECTION_RTL}
   */
  public final int direction;

  public final RequestedDisplayMode displayMode;

  /** Custom parameters that are unique to the desired platform view. */
  @Nullable public final ByteBuffer params;

  // TODO(gmackall): we can give each of these static constructors a corresponding private
  // constructor.
  public static PlatformViewCreationRequest createHCPPRequest(
      int viewId, String viewType, int direction, ByteBuffer params) {
    return new PlatformViewCreationRequest(viewId, viewType, 0, 0, 0, 0, direction, null, params);
  }

  public static PlatformViewCreationRequest createHybridCompositionRequest(
      int viewId, String viewType, int direction, ByteBuffer params) {
    return new PlatformViewCreationRequest(
        viewId, viewType, 0, 0, 0, 0, direction, RequestedDisplayMode.HYBRID_ONLY, params);
  }

  public static PlatformViewCreationRequest createTLHCWithFallbackRequest(
      int viewId,
      String viewType,
      double top,
      double left,
      double width,
      double height,
      int direction,
      boolean hybridFallback,
      ByteBuffer params) {
    return new PlatformViewCreationRequest(
        viewId,
        viewType,
        top,
        left,
        width,
        height,
        direction,
        hybridFallback
            ? RequestedDisplayMode.TEXTURE_WITH_HYBRID_FALLBACK
            : RequestedDisplayMode.TEXTURE_WITH_VIRTUAL_FALLBACK,
        params);
  }

  /**
   * Creates a request to construct a platform view. Prefer use of the mode-specific named
   * constructors above where possible.
   */
  @VisibleForTesting
  public PlatformViewCreationRequest(
      int viewId,
      @NonNull String viewType,
      double logicalTop,
      double logicalLeft,
      double logicalWidth,
      double logicalHeight,
      int direction,
      @Nullable ByteBuffer params) {
    this(
        viewId,
        viewType,
        logicalTop,
        logicalLeft,
        logicalWidth,
        logicalHeight,
        direction,
        RequestedDisplayMode.TEXTURE_WITH_VIRTUAL_FALLBACK,
        params);
  }

  /**
   * Creates a request to construct a platform view with the given display mode. Prefer use of the
   * mode-specific named constructors above where possible.
   */
  public PlatformViewCreationRequest(
      int viewId,
      @NonNull String viewType,
      double logicalTop,
      double logicalLeft,
      double logicalWidth,
      double logicalHeight,
      int direction,
      @Nullable RequestedDisplayMode displayMode,
      @Nullable ByteBuffer params) {
    this.viewId = viewId;
    this.viewType = viewType;
    this.logicalTop = logicalTop;
    this.logicalLeft = logicalLeft;
    this.logicalWidth = logicalWidth;
    this.logicalHeight = logicalHeight;
    this.direction = direction;
    this.displayMode = displayMode;
    this.params = params;
  }
}

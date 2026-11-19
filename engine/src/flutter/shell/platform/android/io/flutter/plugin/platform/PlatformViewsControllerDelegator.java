// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.content.Context;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.PlatformViewCreationRequest;
import io.flutter.embedding.engine.systemchannels.PlatformViewTouch;
import io.flutter.embedding.engine.systemchannels.PlatformViewsChannel;
import io.flutter.embedding.engine.systemchannels.PlatformViewsChannel2;
import io.flutter.view.AccessibilityBridge;
import io.flutter.view.TextureRegistry;

public class PlatformViewsControllerDelegator
    implements PlatformViewsAccessibilityDelegate, PlatformViewsChannel.PlatformViewsHandler {

  PlatformViewsController platformViewsController;
  PlatformViewsController2 platformViewsController2;
  private final PlatformViewsChannel.PlatformViewsHandler channelHandler;
  private final PlatformViewsChannel2.PlatformViewsHandler channelHandler2;

  public PlatformViewsControllerDelegator(
      @NonNull PlatformViewsController platformViewsController,
      @NonNull PlatformViewsController2 platformViewsController2) {
    this(
        platformViewsController,
        platformViewsController2,
        platformViewsController.channelHandler,
        platformViewsController2.channelHandler);
  }

  @VisibleForTesting
  PlatformViewsControllerDelegator(
      @NonNull PlatformViewsController platformViewsController,
      @NonNull PlatformViewsController2 platformViewsController2,
      @NonNull PlatformViewsChannel.PlatformViewsHandler channelHandler,
      @NonNull PlatformViewsChannel2.PlatformViewsHandler channelHandler2) {
    this.platformViewsController = platformViewsController;
    this.platformViewsController2 = platformViewsController2;
    this.channelHandler = channelHandler;
    this.channelHandler2 = channelHandler2;
  }

  @Nullable
  @Override
  public View getPlatformViewById(int viewId) {
    return platformViewsController2.getPlatformViewById(viewId) != null
        ? platformViewsController2.getPlatformViewById(viewId)
        : platformViewsController.getPlatformViewById(viewId);
  }

  @Override
  public boolean usesVirtualDisplay(int id) {
    return platformViewsController2.getPlatformViewById(id) != null
        ? platformViewsController2.usesVirtualDisplay(id)
        : platformViewsController.usesVirtualDisplay(id);
  }

  @Override
  public void attachAccessibilityBridge(@NonNull AccessibilityBridge accessibilityBridge) {
    platformViewsController.attachAccessibilityBridge(accessibilityBridge);
    platformViewsController2.attachAccessibilityBridge(accessibilityBridge);
  }

  @Override
  public void detachAccessibilityBridge() {
    platformViewsController.detachAccessibilityBridge();
    platformViewsController2.detachAccessibilityBridge();
  }

  @Override
  public void dispose(int viewId) {
    if (platformViewsController2.getPlatformViewById(viewId) != null) {
      channelHandler2.dispose(viewId);
    } else {
      channelHandler.dispose(viewId);
    }
  }

  @Override
  public void resize(
      @NonNull PlatformViewsChannel.PlatformViewResizeRequest request,
      @NonNull PlatformViewsChannel.PlatformViewBufferResized onComplete) {
    if (platformViewsController2.getPlatformViewById(request.viewId) != null) {
      // no op
    } else {
      channelHandler.resize(request, onComplete);
    }
  }

  @Override
  public void offset(int viewId, double top, double left) {
    if (platformViewsController2.getPlatformViewById(viewId) != null) {
      // no op
    } else {
      channelHandler.offset(viewId, top, left);
    }
  }

  @Override
  public void onTouch(@NonNull PlatformViewTouch touch) {
    if (platformViewsController2.getPlatformViewById(touch.viewId) != null) {
      channelHandler2.onTouch(touch);
    } else {
      channelHandler.onTouch(touch);
    }
  }

  @Override
  public void setDirection(int viewId, int direction) {
    if (platformViewsController2.getPlatformViewById(viewId) != null) {
      channelHandler2.setDirection(viewId, direction);
    } else {
      channelHandler.setDirection(viewId, direction);
    }
  }

  @Override
  public void clearFocus(int viewId) {
    if (platformViewsController2.getPlatformViewById(viewId) != null) {
      channelHandler2.clearFocus(viewId);
    } else {
      channelHandler.clearFocus(viewId);
    }
  }

  @Override
  public void synchronizeToNativeViewHierarchy(boolean yes) {
    channelHandler.synchronizeToNativeViewHierarchy(yes);
  }

  @Override
  public void onRejectGesture(int viewId, long gestureId) {
    if (platformViewsController2.getPlatformViewById(viewId) != null) {
      channelHandler2.onRejectGesture(viewId, gestureId);
    } else {
      channelHandler.onRejectGesture(viewId, gestureId);
    }
  }

  /** Returns true if creation of HC++ platform views is currently supported. */
  @Override
  public boolean isHcppEnabled() {
    return platformViewsController2.isHcppEnabled();
  }

  // hc only
  @Override
  public void createForPlatformViewLayer(@NonNull PlatformViewCreationRequest request) {
    channelHandler.createForPlatformViewLayer(request);
  }

  // tlhc w/ fallbacks
  @Override
  public long createForTextureLayer(@NonNull PlatformViewCreationRequest request) {
    return channelHandler.createForTextureLayer(request);
  }

  // hcpp
  @Override
  public void createPlatformViewHcpp(@NonNull PlatformViewCreationRequest request) {
    channelHandler2.createPlatformView(request);
  }

  public void attach(
      @Nullable Context context,
      @NonNull TextureRegistry textureRegistry,
      @NonNull DartExecutor dartExecutor) {
    platformViewsController.attach(context, textureRegistry, dartExecutor);
    platformViewsController2.attach(context, dartExecutor);
    platformViewsController.getPlatformViewsChannel().setPlatformViewsHandler(this);
  }

  // TODO(gmackall) Can we define a common interface, allowing us to do something like this?
  //  private PlatformViewsController delegateToController(int viewId) {
  //    return platformViewsController2.getPlatformViewById(viewId) != null
  //            ? platformViewsController2
  //            : platformViewsController;
  //  }
}

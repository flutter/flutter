// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static org.junit.Assert.assertFalse;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.app.Activity;
import android.hardware.camera2.CameraAccessException;
import androidx.lifecycle.LifecycleObserver;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.camera.utils.TestUtils;
import io.flutter.view.TextureRegistry;
import org.junit.Before;
import org.junit.Test;

public class MethodCallHandlerImplTest {

  MethodChannel.MethodCallHandler handler;
  MethodChannel.Result mockResult;
  Camera mockCamera;

  @Before
  public void setUp() {
    handler =
        new MethodCallHandlerImpl(
            mock(Activity.class),
            mock(BinaryMessenger.class),
            mock(CameraPermissions.class),
            mock(CameraPermissions.PermissionsRegistry.class),
            mock(TextureRegistry.class));
    mockResult = mock(MethodChannel.Result.class);
    mockCamera = mock(Camera.class);
    TestUtils.setPrivateField(handler, "camera", mockCamera);
  }

  @Test
  public void shouldNotImplementLifecycleObserverInterface() {
    Class<MethodCallHandlerImpl> methodCallHandlerClass = MethodCallHandlerImpl.class;

    assertFalse(LifecycleObserver.class.isAssignableFrom(methodCallHandlerClass));
  }

  @Test
  public void onMethodCall_pausePreview_shouldPausePreviewAndSendSuccessResult()
      throws CameraAccessException {
    handler.onMethodCall(new MethodCall("pausePreview", null), mockResult);

    verify(mockCamera, times(1)).pausePreview();
    verify(mockResult, times(1)).success(null);
  }

  @Test
  public void onMethodCall_pausePreview_shouldSendErrorResultOnCameraAccessException()
      throws CameraAccessException {
    doThrow(new CameraAccessException(0)).when(mockCamera).pausePreview();

    handler.onMethodCall(new MethodCall("pausePreview", null), mockResult);

    verify(mockResult, times(1)).error("CameraAccess", null, null);
  }

  @Test
  public void onMethodCall_resumePreview_shouldResumePreviewAndSendSuccessResult() {
    handler.onMethodCall(new MethodCall("resumePreview", null), mockResult);

    verify(mockCamera, times(1)).resumePreview();
    verify(mockResult, times(1)).success(null);
  }
}

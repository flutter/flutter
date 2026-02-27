// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.view.SurfaceHolder;
import io.flutter.Build.API_LEVELS;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
public class SurfaceHolderCallbackCompatTest {

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN, maxSdk = API_LEVELS.API_25)
  public void onAttachToRendererShouldRemoveListenerBelowApi26() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(null, fakeSurfaceView, fakeFlutterRenderer);
    test.onAttachToRenderer(null);
    verify(fakeFlutterRenderer, times(1)).removeIsDisplayingFlutterUiListener(test.alphaCallback);
  }

  @Test
  @Config(minSdk = API_LEVELS.API_26)
  public void onAttachToRendererShouldNotRemoveListenerApi26OrAbove() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(null, fakeSurfaceView, fakeFlutterRenderer);
    test.onAttachToRenderer(null);
    verify(fakeFlutterRenderer, never()).removeIsDisplayingFlutterUiListener(test.alphaCallback);
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN, maxSdk = API_LEVELS.API_25)
  public void onResumeShouldAddListenerBelowApi26() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(null, fakeSurfaceView, fakeFlutterRenderer);
    test.onResume();
    verify(fakeFlutterRenderer, times(1)).addIsDisplayingFlutterUiListener(test.alphaCallback);
  }

  @Test
  @Config(minSdk = API_LEVELS.API_26)
  public void onResumeShouldAddListenerOnApi26OrAbove() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(null, fakeSurfaceView, fakeFlutterRenderer);
    test.onResume();
    verify(fakeFlutterRenderer, never()).addIsDisplayingFlutterUiListener(test.alphaCallback);
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN, maxSdk = API_LEVELS.API_25)
  public void onDetachFromRendererShouldRemoveListenerAndSetAlphaBelowApi26() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(null, fakeSurfaceView, fakeFlutterRenderer);
    test.onDetachFromRenderer();
    verify(fakeFlutterRenderer, times(1)).removeIsDisplayingFlutterUiListener(test.alphaCallback);
    verify(fakeSurfaceView, times(2)).setAlpha(0.0f);
  }

  @Test
  @Config(minSdk = API_LEVELS.API_26)
  public void onDetachFromRendererShouldNotRemoveListenerOnApi26OrAbove() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(null, fakeSurfaceView, fakeFlutterRenderer);
    test.onDetachFromRenderer();
    verify(fakeFlutterRenderer, never()).removeIsDisplayingFlutterUiListener(test.alphaCallback);
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN, maxSdk = API_LEVELS.API_25)
  public void alphaCallbackShouldSetAlphaOnSurfaceViewBelowApi26() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(null, fakeSurfaceView, fakeFlutterRenderer);
    test.alphaCallback.onFlutterUiDisplayed();
    verify(fakeSurfaceView, times(1)).setAlpha(0.0f);
    verify(fakeSurfaceView, times(1)).setAlpha(1.0f);
    verify(fakeFlutterRenderer, times(1)).removeIsDisplayingFlutterUiListener(test.alphaCallback);
  }

  @Test
  @Config(minSdk = API_LEVELS.FLUTTER_MIN)
  public void testSurfaceHolderCallbackPassesThroughToInnerCallback() {
    FlutterSurfaceView fakeSurfaceView = mock(FlutterSurfaceView.class);
    FlutterRenderer fakeFlutterRenderer = mock(FlutterRenderer.class);
    SurfaceHolder.Callback innerCallback = mock(SurfaceHolder.Callback.class);
    SurfaceHolderCallbackCompat test =
        new SurfaceHolderCallbackCompat(innerCallback, fakeSurfaceView, fakeFlutterRenderer);
    test.surfaceCreated(null);
    verify(innerCallback, times(1)).surfaceCreated(null);
    test.surfaceChanged(null, 0, 0, 0);
    verify(innerCallback, times(1)).surfaceChanged(null, 0, 0, 0);
    test.surfaceDestroyed(null);
    verify(innerCallback, times(1)).surfaceDestroyed(null);
  }
}

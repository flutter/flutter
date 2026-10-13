// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.os.Build;
import android.view.AttachedSurfaceControl;
import android.view.BlurRegion;
import android.view.RoundedRectBlurRegion;
import android.view.SurfaceView;
import android.view.View;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterView;
import java.util.List;
import org.junit.Assume;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class BackdropBlurCarrierTest {
  private static final float[] ONE_BLUR = {10f, 20f, 110f, 220f, /*sigma=*/ 6f, /*corner=*/ 8f};

  private FlutterView newFlutterView() {
    final Context context = ApplicationProvider.getApplicationContext();
    return new FlutterView(context, new FlutterSurfaceView(context));
  }

  private static SurfaceView requireCarrier(BackdropBlurCarrier carrier) {
    final SurfaceView view = carrier.getCarrierViewForTest();
    assertNotNull(view);
    return view;
  }

  @Test
  public void attachCreatesAnInputAndA11yTransparentCarrier() {
    Assume.assumeTrue(BackdropBlurCarrier.isSupported());
    final FlutterView flutterView = newFlutterView();
    final BackdropBlurCarrier carrier = new BackdropBlurCarrier();

    carrier.attachToView(flutterView);

    final SurfaceView view = requireCarrier(carrier);
    assertEquals(flutterView, view.getParent());
    assertEquals(BackdropBlurCarrier.CARRIER_COMPOSITION_ORDER, view.getCompositionOrder());
    assertEquals(SurfaceView.SURFACE_LIFECYCLE_FOLLOWS_ATTACHMENT, view.getSurfaceLifecycle());
    assertEquals(false, view.isClickable());
    assertEquals(false, view.isFocusable());
    assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO, view.getImportantForAccessibility());
  }

  @Test
  public void detachRemovesTheCarrier() {
    Assume.assumeTrue(BackdropBlurCarrier.isSupported());
    final FlutterView flutterView = newFlutterView();
    final BackdropBlurCarrier carrier = new BackdropBlurCarrier();
    carrier.attachToView(flutterView);
    assertEquals(1, flutterView.getChildCount());

    carrier.detachFromView();

    assertNull(carrier.getCarrierViewForTest());
    assertEquals(0, flutterView.getChildCount());
  }

  @Test
  public void onBackdropBlursSetsRoundedRectRegionsInCarrierCoordinates() {
    Assume.assumeTrue(BackdropBlurCarrier.isSupported());
    final BackdropBlurCarrier carrier = new BackdropBlurCarrier();
    carrier.attachToView(newFlutterView());

    carrier.onBackdropBlurs(ONE_BLUR);

    final List<BlurRegion> regions = requireCarrier(carrier).getBlurRegions();
    assertEquals(1, regions.size());
    final RoundedRectBlurRegion region = (RoundedRectBlurRegion) regions.get(0);
    assertEquals(10f, region.getBounds().left, 0f);
    assertEquals(20f, region.getBounds().top, 0f);
    assertEquals(110f, region.getBounds().right, 0f);
    assertEquals(220f, region.getBounds().bottom, 0f);
    assertEquals(8f, region.getCornerRadii()[0], 0f);
    assertEquals(1.0f, region.getAlpha(), 0f);
    assertEquals(BackdropBlurCarrier.sigmaToBlurRadius(6f), region.getBlurRadius(), 0f);
  }

  @Test
  public void emptyBlursClearRegions() {
    Assume.assumeTrue(BackdropBlurCarrier.isSupported());
    final BackdropBlurCarrier carrier = new BackdropBlurCarrier();
    carrier.attachToView(newFlutterView());
    carrier.onBackdropBlurs(ONE_BLUR);
    assertEquals(1, requireCarrier(carrier).getBlurRegions().size());

    carrier.onBackdropBlurs(new float[0]);

    assertTrue(requireCarrier(carrier).getBlurRegions().isEmpty());
  }

  @Test
  public void isANoopWhenNotAttached() {
    final BackdropBlurCarrier carrier = new BackdropBlurCarrier();
    // Must not throw: the engine reports blurs regardless of API level.
    carrier.onBackdropBlurs(ONE_BLUR);
    carrier.onBackdropBlurs(new float[0]);
    carrier.setOverlaySurfaceControl(null);
    carrier.detachFromView();
    assertNull(carrier.getCarrierViewForTest());
  }

  @Test
  public void isANoopForMockedFlutterViewWithoutContext() {
    final BackdropBlurCarrier carrier = new BackdropBlurCarrier();
    final FlutterView flutterView = mock(FlutterView.class);
    when(flutterView.getRootSurfaceControl()).thenReturn(mock(AttachedSurfaceControl.class));

    carrier.attachToView(flutterView);
    carrier.onBackdropBlurs(ONE_BLUR);

    assertNull(carrier.getCarrierViewForTest());
  }

  @Test
  @Config(sdk = Build.VERSION_CODES.VANILLA_ICE_CREAM)
  public void doesNotCreateACarrierBelowApi37() {
    final BackdropBlurCarrier carrier = new BackdropBlurCarrier();
    carrier.attachToView(newFlutterView());
    carrier.onBackdropBlurs(ONE_BLUR);
    assertNull(carrier.getCarrierViewForTest());
  }

  @Test
  public void sigmaToBlurRadiusIsMonotonicAndNonNegative() {
    assertEquals(0f, BackdropBlurCarrier.sigmaToBlurRadius(0f), 0f);
    assertEquals(0f, BackdropBlurCarrier.sigmaToBlurRadius(-1f), 0f);
    assertTrue(
        BackdropBlurCarrier.sigmaToBlurRadius(20f) > BackdropBlurCarrier.sigmaToBlurRadius(10f));
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.view.View;
import io.flutter.embedding.engine.systemchannels.PlatformViewsChannel;
import io.flutter.embedding.engine.systemchannels.PlatformViewsChannel2;
import io.flutter.view.AccessibilityBridge;
import org.junit.Assert;
import org.junit.Test;

public class PlatformViewsControllerDelegatorTest {
  @Test
  public void getPlatformViewById_returnsFromPVC2ifPresent() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    View pv1 = mock(View.class);
    View pv2 = mock(View.class);
    when(platformViewsController.getPlatformViewById(0)).thenReturn(pv1);
    when(platformViewsController2.getPlatformViewById(0)).thenReturn(pv2);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(platformViewsController, platformViewsController2);
    View returnedView = delegator.getPlatformViewById(0);

    Assert.assertEquals(pv2, returnedView);
    Assert.assertNotEquals(pv1, returnedView);
  }

  @Test
  public void getPlatformViewById_returnsFromPVC1ifNotPresentInPVC2() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    View pv1 = mock(View.class);
    when(platformViewsController.getPlatformViewById(0)).thenReturn(pv1);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(platformViewsController, platformViewsController2);
    View returnedView = delegator.getPlatformViewById(0);

    Assert.assertEquals(pv1, returnedView);
  }

  @Test
  public void usesVirtualDisplay_returnsFromPVC2() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    View pv1 = mock(View.class);
    when(platformViewsController2.getPlatformViewById(0)).thenReturn(pv1);
    when(platformViewsController.usesVirtualDisplay(0)).thenReturn(true);
    when(platformViewsController2.usesVirtualDisplay(0)).thenReturn(false);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(platformViewsController, platformViewsController2);

    Assert.assertFalse(delegator.usesVirtualDisplay(0));
  }

  @Test
  public void usesVirtualDisplay_returnsFromPVC1ifNotPresentInPVC2() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    when(platformViewsController2.getPlatformViewById(0)).thenReturn(null);
    when(platformViewsController.usesVirtualDisplay(0)).thenReturn(true);
    when(platformViewsController2.usesVirtualDisplay(0)).thenReturn(false);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(platformViewsController, platformViewsController2);

    Assert.assertTrue(delegator.usesVirtualDisplay(0));
  }

  @Test
  public void attachAccessibilityBridge_attachesForBothPVCs() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    AccessibilityBridge accessibilityBridge = mock(AccessibilityBridge.class);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(platformViewsController, platformViewsController2);
    delegator.attachAccessibilityBridge(accessibilityBridge);

    verify(platformViewsController).attachAccessibilityBridge(accessibilityBridge);
    verify(platformViewsController2).attachAccessibilityBridge(accessibilityBridge);
  }

  @Test
  public void detachAccessibilityBridge_detachesForBothPVCs() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(platformViewsController, platformViewsController2);
    delegator.detachAccessibilityBridge();

    verify(platformViewsController).detachAccessibilityBridge();
    verify(platformViewsController2).detachAccessibilityBridge();
  }

  @Test
  public void onRejectGesture_delegatesToPVC2ifPresent() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    PlatformViewsChannel.PlatformViewsHandler pvcHandler =
        mock(PlatformViewsChannel.PlatformViewsHandler.class);
    PlatformViewsChannel2.PlatformViewsHandler pvc2Handler =
        mock(PlatformViewsChannel2.PlatformViewsHandler.class);
    View pv2 = mock(View.class);
    when(platformViewsController2.getPlatformViewById(0)).thenReturn(pv2);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(
            platformViewsController, platformViewsController2, pvcHandler, pvc2Handler);
    delegator.onRejectGesture(0, 12345L);

    verify(pvc2Handler).onRejectGesture(0, 12345L);
  }

  @Test
  public void onRejectGesture_delegatesToPVC1ifNotPresentInPVC2() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    PlatformViewsChannel.PlatformViewsHandler pvcHandler =
        mock(PlatformViewsChannel.PlatformViewsHandler.class);
    PlatformViewsChannel2.PlatformViewsHandler pvc2Handler =
        mock(PlatformViewsChannel2.PlatformViewsHandler.class);

    PlatformViewsControllerDelegator delegator =
        new PlatformViewsControllerDelegator(
            platformViewsController, platformViewsController2, pvcHandler, pvc2Handler);
    delegator.onRejectGesture(0, 12345L);

    verify(pvcHandler).onRejectGesture(0, 12345L);
  }

  @Test
  public void constructor_handlesNullControllersWithoutThrowing() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);
    PlatformViewsControllerDelegator delegatorWithNullSecond =
        new PlatformViewsControllerDelegator(platformViewsController, null);
    Assert.assertNotNull(delegatorWithNullSecond);

    PlatformViewsController2 platformViewsController2 = mock(PlatformViewsController2.class);
    PlatformViewsControllerDelegator delegatorWithNullFirst =
        new PlatformViewsControllerDelegator(null, platformViewsController2);
    Assert.assertNotNull(delegatorWithNullFirst);

    PlatformViewsControllerDelegator delegatorWithBothNull =
        new PlatformViewsControllerDelegator(null, null);
    Assert.assertNotNull(delegatorWithBothNull);
  }
}

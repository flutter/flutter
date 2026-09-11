// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import android.app.Presentation;
import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.SurfaceTexture;
import android.media.Image;
import android.util.SparseArray;
import android.view.AttachedSurfaceControl;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceControl;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.FlutterImageView;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.MotionEventTracker;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.mutatorsstack.FlutterMutatorView;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.embedding.engine.systemchannels.MouseCursorChannel;
import io.flutter.embedding.engine.systemchannels.PlatformViewCreationRequest;
import io.flutter.embedding.engine.systemchannels.PlatformViewTouch;
import io.flutter.embedding.engine.systemchannels.ScribeChannel;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.plugin.localization.LocalizationPlugin;
import io.flutter.view.TextureRegistry;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Assume;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadows.ShadowDialog;
import org.robolectric.shadows.ShadowSurfaceView;

@RunWith(AndroidJUnit4.class)
public class PlatformViewsController2Test {
  // An implementation of PlatformView that counts invocations of its lifecycle callbacks.
  class CountingPlatformView implements PlatformView {
    static final String VIEW_TYPE_ID = "CountingPlatformView";
    private View view;

    public CountingPlatformView(Context context) {
      view = new SurfaceView(context);
    }

    public int disposeCalls = 0;
    public int attachCalls = 0;
    public int detachCalls = 0;

    @Override
    public void dispose() {
      // We have been removed from the view hierarhy before the call to dispose.
      assertNull(view.getParent());
      disposeCalls++;
    }

    @Override
    public View getView() {
      return view;
    }

    @Override
    public void onFlutterViewAttached(View flutterView) {
      attachCalls++;
    }

    @Override
    public void onFlutterViewDetached() {
      detachCalls++;
    }
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void itRemovesPlatformViewBeforeDiposeIsCalled() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);
    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);
    // Get the platform view registry.
    PlatformViewRegistry registry = PlatformViewsController2.getRegistry();

    // Register a factory for our platform view.
    registry.registerViewFactory(
        CountingPlatformView.VIEW_TYPE_ID,
        new PlatformViewFactory(StandardMessageCodec.INSTANCE) {
          @Override
          public PlatformView create(Context context, int viewId, Object args) {
            return new CountingPlatformView(context);
          }
        });

    // Create the platform view.
    int viewId = 0;

    final PlatformViewCreationRequest request =
        PlatformViewCreationRequest.createHCPPRequest(
            viewId, CountingPlatformView.VIEW_TYPE_ID, View.LAYOUT_DIRECTION_LTR, null);
    PlatformView pView = PlatformViewsController2.createFlutterPlatformView(request);
    assertTrue(pView instanceof CountingPlatformView);
    CountingPlatformView cpv = (CountingPlatformView) pView;

    PlatformViewsController2.disposePlatformView(viewId);
    assertEquals(1, cpv.disposeCalls);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void itNotifiesPlatformViewsOfEngineAttachmentAndDetachment() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);
    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);
    // Get the platform view registry.
    PlatformViewRegistry registry = PlatformViewsController2.getRegistry();

    // Register a factory for our platform view.
    registry.registerViewFactory(
        CountingPlatformView.VIEW_TYPE_ID,
        new PlatformViewFactory(StandardMessageCodec.INSTANCE) {
          @Override
          public PlatformView create(Context context, int viewId, Object args) {
            return new CountingPlatformView(context);
          }
        });

    // Create the platform view.
    int viewId = 0;
    final PlatformViewCreationRequest request =
        PlatformViewCreationRequest.createHCPPRequest(
            viewId, CountingPlatformView.VIEW_TYPE_ID, View.LAYOUT_DIRECTION_LTR, null);

    PlatformView pView = PlatformViewsController2.createFlutterPlatformView(request);
    assertTrue(pView instanceof CountingPlatformView);
    CountingPlatformView cpv = (CountingPlatformView) pView;
    assertEquals(1, cpv.attachCalls);
    assertEquals(0, cpv.detachCalls);
    assertEquals(0, cpv.disposeCalls);
    PlatformViewsController2.detachFromView();
    assertEquals(1, cpv.attachCalls);
    assertEquals(1, cpv.detachCalls);
    assertEquals(0, cpv.disposeCalls);
    PlatformViewsController2.disposePlatformView(viewId);
  }

  @Test
  public void itUsesActionEventTypeFromFrameworkEventAsActionChanged() {
    MotionEventTracker motionEventTracker = MotionEventTracker.getInstance();
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    MotionEvent original =
        MotionEvent.obtain(
            10, // downTime
            10, // eventTime
            261, // action
            0, // x
            0, // y
            0 // metaState
            );

    MotionEventTracker.MotionEventId motionEventId = motionEventTracker.track(original);

    PlatformViewTouch frameWorkTouch =
        new PlatformViewTouch(
            0, // viewId
            original.getDownTime(),
            original.getEventTime(),
            0, // action
            1, // pointerCount
            Arrays.asList(Arrays.asList(0, 0)), // pointer properties
            Arrays.asList(Arrays.asList(0., 1., 2., 3., 4., 5., 6., 7., 8.)), // pointer coords
            original.getMetaState(),
            original.getButtonState(),
            original.getXPrecision(),
            original.getYPrecision(),
            original.getDeviceId(),
            original.getEdgeFlags(),
            original.getSource(),
            original.getFlags(),
            motionEventId.getId());
    MotionEvent resolvedEvent =
        PlatformViewsController2.toMotionEvent(
            1, // density
            frameWorkTouch);
    assertEquals(resolvedEvent.getAction(), original.getAction());
    assertNotEquals(resolvedEvent.getAction(), frameWorkTouch.action);
  }

  private MotionEvent makePlatformViewTouchAndInvokeToMotionEvent(
      PlatformViewsController2 PlatformViewsController2,
      MotionEventTracker motionEventTracker,
      MotionEvent original,
      boolean usingVirtualDisplays) {
    MotionEventTracker.MotionEventId motionEventId = motionEventTracker.track(original);

    // Construct a PlatformViewTouch.rawPointerPropertiesList by doing the inverse of
    // PlatformViewsController2.parsePointerPropertiesList.
    List<List<Integer>> pointerProperties =
        Arrays.asList(Arrays.asList(original.getPointerId(0), original.getToolType(0)));
    // Construct a PlatformViewTouch.rawPointerCoords by doing the inverse of
    // PlatformViewsController2.parsePointerCoordsList.
    List<List<Double>> pointerCoordinates =
        Arrays.asList(
            Arrays.asList(
                (double) original.getOrientation(),
                (double) original.getPressure(),
                (double) original.getSize(),
                (double) original.getToolMajor(),
                (double) original.getToolMinor(),
                (double) original.getTouchMajor(),
                (double) original.getTouchMinor(),
                (double) original.getX(),
                (double) original.getY()));
    // Make a platform view touch from the motion event.
    PlatformViewTouch frameWorkTouchNonVd =
        new PlatformViewTouch(
            0, // viewId
            original.getDownTime(),
            original.getEventTime(),
            original.getAction(),
            1, // pointerCount
            pointerProperties, // pointer properties
            pointerCoordinates, // pointer coords
            original.getMetaState(),
            original.getButtonState(),
            original.getXPrecision(),
            original.getYPrecision(),
            original.getDeviceId(),
            original.getEdgeFlags(),
            original.getSource(),
            original.getFlags(),
            motionEventId.getId());

    return PlatformViewsController2.toMotionEvent(
        1, // density
        frameWorkTouchNonVd);
  }

  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void getPlatformViewById() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");

    assertTrue(PlatformViewsController2.initializePlatformViewIfNeeded(platformViewId));

    View resultAndroidView = PlatformViewsController2.getPlatformViewById(platformViewId);
    assertNotNull(resultAndroidView);
    assertEquals(resultAndroidView, androidView);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createPlatformViewMessage_initializesAndroidView() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(mock(View.class));
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    verify(viewFactory, times(1)).create(any(), eq(platformViewId), any());
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createPlatformViewMessage_setsAndroidViewLayoutDirection() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);

    View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    verify(androidView, times(1)).setLayoutDirection(0);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createPlatformViewMessage_throwsIfViewIsNull() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(null);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    assertEquals(1, ShadowFlutterJNI.getResponses().size());

    assertFalse(PlatformViewsController2.initializePlatformViewIfNeeded(platformViewId));
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createHybridPlatformViewMessage_throwsIfViewIsNull() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(null);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    assertEquals(1, ShadowFlutterJNI.getResponses().size());

    assertFalse(PlatformViewsController2.initializePlatformViewIfNeeded(platformViewId));
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void setPlatformViewDirection_throwIfPlatformViewNotFound() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    final View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    verify(androidView, never()).setLayoutDirection(anyInt());

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    assertEquals(1, ShadowFlutterJNI.getResponses().size());

    // Simulate set direction call from the framework.
    setLayoutDirection(jni, PlatformViewsController2, platformViewId, 1);
    verify(androidView, times(1)).setLayoutDirection(1);

    // The limit value of reply message will be equal to 2 if the layout direction is set
    // successfully, otherwise it will be much more than 2 due to the reply message contains
    // an error message wrapped with exception detail information.
    assertEquals(2, ShadowFlutterJNI.getResponses().get(0).limit());
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void disposeAndroidView() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);

    Context context = ApplicationProvider.getApplicationContext();
    View androidView = new View(context);

    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    assertTrue(PlatformViewsController2.initializePlatformViewIfNeeded(platformViewId));

    assertNotNull(androidView.getParent());
    assertTrue(androidView.getParent() instanceof FlutterMutatorView);

    // Simulate dispose call from the framework.
    disposePlatformView(jni, PlatformViewsController2, platformViewId);
    assertNull(androidView.getParent());

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    assertTrue(PlatformViewsController2.initializePlatformViewIfNeeded(platformViewId));

    assertNotNull(androidView.getParent());
    assertTrue(androidView.getParent() instanceof FlutterMutatorView);
    verify(platformView, times(1)).dispose();
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void disposeNullAndroidView() {
    PlatformViewRegistryImpl registryImpl = new PlatformViewRegistryImpl();
    PlatformViewsController2 PlatformViewsController2 = new PlatformViewsController2();
    PlatformViewsController2.setRegistry(registryImpl);

    int platformViewId = 0;
    assertNull(PlatformViewsController2.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);

    View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    PlatformViewsController2.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, PlatformViewsController2);

    // Simulate create call from the framework.
    createPlatformView(jni, PlatformViewsController2, platformViewId, "testType");
    assertTrue(PlatformViewsController2.initializePlatformViewIfNeeded(platformViewId));

    when(platformView.getView()).thenReturn(null);

    // Simulate dispose call from the framework.
    disposePlatformView(jni, PlatformViewsController2, platformViewId);
    verify(platformView, times(1)).dispose();
  }

  // Class member variable
  private SurfaceControl.Transaction mCapturedTx;

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void showOverlaySurfaceDefersTransactionUntilEndFrame() {

    PlatformViewsController2 controller =
        new PlatformViewsController2() {
          @Override
          public SurfaceControl.Transaction createTransaction() {
            // Call super to ensure the real transaction is added to the private
            // 'pendingTransactions' list
            SurfaceControl.Transaction realTx = super.createTransaction();
            // Spy on it so we can verify calls like 'apply()'
            mCapturedTx = spy(realTx);
            return mCapturedTx;
          }
        };

    PlatformViewRegistryImpl registry = new PlatformViewRegistryImpl();
    controller.setRegistry(registry);

    // Mocks
    FlutterView mockFlutterView = mock(FlutterView.class);
    AttachedSurfaceControl mockAttachedSurfaceControl = mock(AttachedSurfaceControl.class);

    when(mockFlutterView.getRootSurfaceControl()).thenReturn(mockAttachedSurfaceControl);
    when(mockAttachedSurfaceControl.buildReparentTransaction(any()))
        .thenReturn(new SurfaceControl.Transaction());

    controller.attachToView(mockFlutterView);
    controller.createOverlaySurface();

    controller.showOverlaySurface();
    assertNotNull("Transaction should have been created", mCapturedTx);
    verify(mCapturedTx, never()).apply();

    controller.swapTransactions();
    controller.onEndFrame();

    verify(mockAttachedSurfaceControl, times(1))
        .applyTransactionOnDraw(any(SurfaceControl.Transaction.class));
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createTransactionConsolidatesOnPlatformThread() {
    PlatformViewsController2 controller = new PlatformViewsController2();
    controller.setRegistry(new PlatformViewRegistryImpl());

    // On the platform/test thread, repeated calls to createTransaction() return the same instance.
    SurfaceControl.Transaction tx1 = controller.createTransaction();
    SurfaceControl.Transaction tx2 = controller.createTransaction();
    assertSame("Platform thread should reuse the consolidated transaction", tx1, tx2);

    controller.swapTransactions();

    // After swapping, a new frame gets a new consolidated transaction.
    SurfaceControl.Transaction tx3 = controller.createTransaction();
    assertNotSame("New frame on platform thread should get a fresh transaction", tx1, tx3);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createTransactionIsolatesRasterThreadTransactions() throws Exception {
    PlatformViewsController2 controller = new PlatformViewsController2();
    controller.setRegistry(new PlatformViewRegistryImpl());

    // Transaction on platform thread:
    SurfaceControl.Transaction platformTx = controller.createTransaction();

    // Transactions created on a background/raster thread:
    final SurfaceControl.Transaction[] rasterTxs = new SurfaceControl.Transaction[2];
    Thread rasterThread =
        new Thread(
            () -> {
              rasterTxs[0] = controller.createTransaction();
              rasterTxs[1] = controller.createTransaction();
            });
    rasterThread.start();
    rasterThread.join();

    assertNotNull(rasterTxs[0]);
    assertNotNull(rasterTxs[1]);
    assertNotSame("Raster thread must not share platform transaction", platformTx, rasterTxs[0]);
    assertNotSame(
        "Raster thread submissions must receive isolated transactions", rasterTxs[0], rasterTxs[1]);

    // Swapping and ending frame should merge both without crashing.
    FlutterView mockFlutterView = mock(FlutterView.class);
    AttachedSurfaceControl mockAttachedSurfaceControl = mock(AttachedSurfaceControl.class);
    when(mockFlutterView.getRootSurfaceControl()).thenReturn(mockAttachedSurfaceControl);
    controller.attachToView(mockFlutterView);

    controller.swapTransactions();
    controller.onEndFrame();

    verify(mockAttachedSurfaceControl, times(1))
        .applyTransactionOnDraw(any(SurfaceControl.Transaction.class));
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void swapTransactionsClosesTransactionsThatWereNeverApplied() throws Exception {
    final List<SurfaceControl.Transaction> created = new ArrayList<>();
    PlatformViewsController2 controller =
        new PlatformViewsController2() {
          @Override
          SurfaceControl.Transaction newTransaction() {
            SurfaceControl.Transaction tx = spy(super.newTransaction());
            created.add(tx);
            return tx;
          }
        };
    controller.setRegistry(new PlatformViewRegistryImpl());

    // Frame 1: one consolidated platform transaction and one isolated raster transaction.
    controller.createTransaction();
    Thread rasterThread = new Thread(controller::createTransaction);
    rasterThread.start();
    rasterThread.join();
    assertEquals(2, created.size());

    // Frame 1 is swapped into the active slots but onEndFrame() never runs, so frame 2's swap
    // discards them. They must be closed rather than leaked.
    controller.swapTransactions();
    controller.swapTransactions();

    for (SurfaceControl.Transaction tx : created) {
      verify(tx, times(1)).close();
    }
  }

  /**
   * Reproduces the HCPP transaction data race.
   *
   * <p>With the AHB swapchain, the raster thread calls {@code createTransaction()} once per
   * present, while the platform thread calls it once per SurfaceView platform view per frame and
   * then runs {@code swapTransactions()} and {@code onEndFrame()}. If the lists holding those
   * transactions are not synchronized, an {@code add()} racing a {@code clear()} leaves {@code
   * null} at a live index, and {@code onEndFrame()} then calls {@code merge(null)}. On device that
   * NPE unwinds into {@code onEndFrame2()}, where {@code FML_CHECK(fml::jni::CheckException(env))}
   * turns it into an {@code abort()}.
   *
   * <p>This is a probabilistic detector, but a one-sided one: it has no timing assertions, so
   * scheduling luck decides whether it catches an unsynchronized implementation, never whether it
   * fails a synchronized one. It reliably catches wholesale loss of the locking; it is not
   * guaranteed to catch a subtle partial regression.
   *
   * <p>It covers only the transaction <i>lists</i>, not the transaction objects. In production the
   * raster thread keeps writing to a transaction after {@code createTransaction()} has published it
   * -- the buffer and the completion callback are attached afterwards -- and that
   * write-after-publish is out of scope here. See {@code createTransaction()} in the controller.
   */
  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createTransactionIsSafeWhenRasterAndPlatformThreadsRaceOnFrames() throws Exception {
    final PlatformViewsController2 controller = new PlatformViewsController2();
    controller.setRegistry(new PlatformViewRegistryImpl());

    final int rasterThreadCount = 4;
    // The pending list is what swapTransactions() has to walk, so its length sets how long the
    // clear()/addAll() pair stays exposed to a concurrent add(). It is the dominant lever on
    // whether the race is observed at all; 8 presents per round detects it far less reliably.
    final int presentsPerRound = 64;
    final int rounds = 300;
    // Only a safety net: the cleanup below breaks the barrier explicitly, so a failing run does
    // not wait this out.
    final long timeoutMs = 30000;

    // This test is only meaningful if isPlatformThread() classifies the test thread and the
    // background threads differently. It is not asserted here because
    // createTransactionConsolidatesOnPlatformThread and
    // createTransactionIsolatesRasterThreadTransactions already assert exactly that, on exactly
    // these two kinds of thread; if the classification broke, they would go red first.

    // Each round is barrier-synchronized so the raster threads' add()s land inside the platform
    // thread's swapTransactions(), instead of relying on two free-running loops happening to
    // overlap. Collision density is then a property of the test rather than of the machine.
    final CyclicBarrier roundStart = new CyclicBarrier(rasterThreadCount + 1);
    // Two buckets, deliberately. A product failure is an assertion; a bot that could not schedule
    // the threads is a skip. Collapsing them makes a slow machine indistinguishable from the
    // crash this test is named after.
    final AtomicReference<Throwable> raceFailure = new AtomicReference<>();
    final AtomicReference<Throwable> harnessFailure = new AtomicReference<>();
    final AtomicBoolean running = new AtomicBoolean(true);
    final List<Thread> rasterThreads = new ArrayList<>();

    for (int i = 0; i < rasterThreadCount; i++) {
      final Thread rasterThread =
          new Thread(
              () -> {
                try {
                  for (int round = 0; round < rounds && running.get(); round++) {
                    roundStart.await(timeoutMs, TimeUnit.MILLISECONDS);
                    for (int present = 0; present < presentsPerRound; present++) {
                      // Unlike production, this thread is finished with the transaction as soon
                      // as it is returned. The real raster thread goes on to attach a buffer and
                      // a completion callback to it; that write-after-publish is out of scope
                      // here (see the class doc above).
                      controller.createTransaction();
                    }
                  }
                } catch (TimeoutException e) {
                  harnessFailure.compareAndSet(null, e);
                } catch (BrokenBarrierException e) {
                  // Another participant stopped early. Whichever one it was recorded why.
                } catch (Throwable t) {
                  raceFailure.compareAndSet(null, t);
                } finally {
                  running.set(false);
                  // Release anyone parked on the barrier so a failure cannot turn into a hang.
                  roundStart.reset();
                }
              },
              "fake-raster-" + i);
      rasterThread.setDaemon(true);
      rasterThreads.add(rasterThread);
      rasterThread.start();
    }

    try {
      for (int round = 0; round < rounds; round++) {
        roundStart.await(timeoutMs, TimeUnit.MILLISECONDS);

        // Stand-in for maybeApplyClipToSurfaceView(), which runs once per SurfaceView platform
        // view in onDisplayPlatformView().
        controller.createTransaction();
        controller.createTransaction();

        controller.swapTransactions();
        // flutterView is null, so onEndFrame() drops the frame instead of applying it. It still
        // walks and closes the active transactions first, which is where the race shows up.
        controller.onEndFrame();
      }
    } catch (TimeoutException | BrokenBarrierException e) {
      // Either this thread stalled, or a raster thread left the barrier. If it left because it
      // hit a real failure, it recorded that in raceFailure, which is reported first below.
      harnessFailure.compareAndSet(null, e);
    } catch (Throwable t) {
      raceFailure.compareAndSet(null, t);
    } finally {
      running.set(false);
      for (Thread rasterThread : rasterThreads) {
        // A raster thread can be parked on the barrier waiting for a participant that has already
        // left, so keep breaking the barrier until it exits. Without this, a failing run waits out
        // the barrier timeout before it reports, which is exactly when you want a fast answer.
        for (int attempt = 0; attempt < 500 && rasterThread.isAlive(); attempt++) {
          roundStart.reset();
          rasterThread.join(10);
        }
        if (rasterThread.isAlive()) {
          harnessFailure.compareAndSet(
              null, new AssertionError(rasterThread.getName() + " did not terminate"));
        }
      }
    }

    if (raceFailure.get() != null) {
      throw new AssertionError(
          "Concurrent createTransaction()/swapTransactions() corrupted the transaction lists.",
          raceFailure.get());
    }
    Assume.assumeNoException(
        "The harness could not complete a clean run on this machine; this is not a product "
            + "failure.",
        harnessFailure.get());
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void onEndFrameInvalidatesEvenWhenTheFrameProducedNoTransactions() {
    PlatformViewsController2 controller = new PlatformViewsController2();
    controller.setRegistry(new PlatformViewRegistryImpl());

    FlutterView mockFlutterView = mock(FlutterView.class);
    AttachedSurfaceControl mockAttachedSurfaceControl = mock(AttachedSurfaceControl.class);
    when(mockFlutterView.getRootSurfaceControl()).thenReturn(mockAttachedSurfaceControl);
    controller.attachToView(mockFlutterView);

    controller.swapTransactions();
    controller.onEndFrame();

    // Nothing of our own to apply, but the invalidate is still owed: applyTransactionOnDraw()
    // applies with the next draw and does not schedule one, so skipping the invalidate can
    // strand a transaction ViewRootImpl is already holding.
    verify(mockFlutterView, times(1)).invalidate();
    verify(mockAttachedSurfaceControl, never())
        .applyTransactionOnDraw(any(SurfaceControl.Transaction.class));
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void onEndFrameIsANoopAfterDetachFromView() {
    PlatformViewsController2 controller = new PlatformViewsController2();
    controller.setRegistry(new PlatformViewRegistryImpl());

    FlutterView mockFlutterView = mock(FlutterView.class);
    AttachedSurfaceControl mockAttachedSurfaceControl = mock(AttachedSurfaceControl.class);
    when(mockFlutterView.getRootSurfaceControl()).thenReturn(mockAttachedSurfaceControl);

    controller.attachToView(mockFlutterView);
    controller.detachFromView();

    // onEndFrame is posted from the raster thread, so it can run after the view was detached.
    // It must not throw: the JNI caller turns a pending exception into an abort.
    controller.onEndFrame();

    verify(mockAttachedSurfaceControl, never())
        .applyTransactionOnDraw(any(SurfaceControl.Transaction.class));
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void onEndFrameIsANoopWhenFlutterViewHasNoRootSurfaceControl() {
    PlatformViewsController2 controller = new PlatformViewsController2();
    controller.setRegistry(new PlatformViewRegistryImpl());

    // getRootSurfaceControl() returns null while the view is not attached to a window.
    FlutterView mockFlutterView = mock(FlutterView.class);
    when(mockFlutterView.getRootSurfaceControl()).thenReturn(null);

    controller.attachToView(mockFlutterView);

    controller.onEndFrame();

    verify(mockFlutterView, never()).invalidate();
  }

  private static ByteBuffer encodeMethodCall(MethodCall call) {
    final ByteBuffer buffer = StandardMethodCodec.INSTANCE.encodeMethodCall(call);
    buffer.rewind();
    return buffer;
  }

  private static void createPlatformView(
      FlutterJNI jni,
      PlatformViewsController2 PlatformViewsController2,
      int platformViewId,
      String viewType) {
    final Map<String, Object> args = new HashMap<>();
    args.put("id", platformViewId);
    args.put("viewType", viewType);
    args.put("direction", 0);
    args.put("width", 1.0);
    args.put("height", 1.0);

    final MethodCall platformCreateMethodCall = new MethodCall("create", args);

    jni.handlePlatformMessage(
        "flutter/platform_views_2",
        encodeMethodCall(platformCreateMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static void setLayoutDirection(
      FlutterJNI jni,
      PlatformViewsController2 PlatformViewsController2,
      int platformViewId,
      int direction) {
    final Map<String, Object> args = new HashMap<>();
    args.put("id", platformViewId);
    args.put("direction", direction);

    final MethodCall platformSetDirectionMethodCall = new MethodCall("setDirection", args);

    jni.handlePlatformMessage(
        "flutter/platform_views_2",
        encodeMethodCall(platformSetDirectionMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static void disposePlatformView(
      FlutterJNI jni, PlatformViewsController2 PlatformViewsController2, int platformViewId) {

    final Map<String, Object> args = new HashMap<>();
    args.put("id", platformViewId);

    final MethodCall platformDisposeMethodCall = new MethodCall("dispose", args);

    jni.handlePlatformMessage(
        "flutter/platform_views_2",
        encodeMethodCall(platformDisposeMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static void synchronizeToNativeViewHierarchy(
      FlutterJNI jni, PlatformViewsController2 PlatformViewsController2, boolean yes) {

    final MethodCall convertMethodCall = new MethodCall("synchronizeToNativeViewHierarchy", yes);

    jni.handlePlatformMessage(
        "flutter/platform_views_2",
        encodeMethodCall(convertMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static FlutterView attach(
      FlutterJNI jni, PlatformViewsController2 PlatformViewsController2) {
    final Context context = ApplicationProvider.getApplicationContext();
    final FlutterView flutterView =
        new FlutterView(context, new FlutterSurfaceView(context)) {
          @Override
          public FlutterImageView createImageView() {
            final FlutterImageView view = mock(FlutterImageView.class);
            when(view.acquireLatestImage()).thenReturn(true);
            return mock(FlutterImageView.class);
          }
        };
    attachToFlutterView(jni, PlatformViewsController2, flutterView);
    return flutterView;
  }

  private static void attachToFlutterView(
      FlutterJNI jni, PlatformViewsController2 PlatformViewsController2, FlutterView flutterView) {
    final DartExecutor executor = new DartExecutor(jni, mock(AssetManager.class));
    executor.onAttachedToJNI();
    final TextureRegistry registry =
        spy(
            new TextureRegistry() {
              public void TextureRegistry() {}

              @NonNull
              @Override
              public SurfaceTextureEntry createSurfaceTexture() {
                return registerSurfaceTexture(mock(SurfaceTexture.class));
              }

              @NonNull
              @Override
              public SurfaceTextureEntry registerSurfaceTexture(
                  @NonNull SurfaceTexture surfaceTexture) {
                return new SurfaceTextureEntry() {
                  @NonNull
                  @Override
                  public SurfaceTexture surfaceTexture() {
                    return mock(SurfaceTexture.class);
                  }

                  @Override
                  public long id() {
                    return 0;
                  }

                  @Override
                  public void release() {}
                };
              }

              @NonNull
              @Override
              public ImageTextureEntry createImageTexture() {
                return new ImageTextureEntry() {
                  @Override
                  public long id() {
                    return 0;
                  }

                  @Override
                  public void release() {}

                  @Override
                  public void pushImage(Image image) {}
                };
              }

              @NonNull
              @Override
              public SurfaceProducer createSurfaceProducer(SurfaceLifecycle lifecycle) {
                return new SurfaceProducer() {
                  @Override
                  public void setCallback(SurfaceProducer.Callback cb) {}

                  @Override
                  public long id() {
                    return 0;
                  }

                  @Override
                  public void release() {}

                  @Override
                  public int getWidth() {
                    return 0;
                  }

                  @Override
                  public int getHeight() {
                    return 0;
                  }

                  @Override
                  public void setSize(int width, int height) {}

                  @Override
                  public Surface getSurface() {
                    return null;
                  }

                  @Override
                  public Surface getForcedNewSurface() {
                    return null;
                  }

                  @Override
                  public boolean handlesCropAndRotation() {
                    return false;
                  }

                  public void scheduleFrame() {}
                };
              }
            });

    final Context context = ApplicationProvider.getApplicationContext();

    PlatformViewsController oldController = new PlatformViewsController();

    PlatformViewsControllerDelegator platformViewsControllerDelegator =
        new PlatformViewsControllerDelegator(oldController, PlatformViewsController2);

    final FlutterEngine engine = mock(FlutterEngine.class);
    when(engine.getRenderer()).thenReturn(new FlutterRenderer(jni));
    when(engine.getMouseCursorChannel()).thenReturn(mock(MouseCursorChannel.class));
    when(engine.getTextInputChannel()).thenReturn(mock(TextInputChannel.class));
    when(engine.getSettingsChannel()).thenReturn(new SettingsChannel(executor));
    when(engine.getScribeChannel()).thenReturn(mock(ScribeChannel.class));
    when(engine.getPlatformViewsController2()).thenReturn(PlatformViewsController2);
    when(engine.getPlatformViewsController()).thenReturn(oldController);
    when(engine.getPlatformViewsControllerDelegator()).thenReturn(platformViewsControllerDelegator);
    when(engine.getLocalizationPlugin()).thenReturn(mock(LocalizationPlugin.class));
    when(engine.getAccessibilityChannel()).thenReturn(mock(AccessibilityChannel.class));
    when(engine.getDartExecutor()).thenReturn(executor);

    flutterView.attachToFlutterEngine(engine);
    PlatformViewsController2.attachToView(flutterView);
    platformViewsControllerDelegator.attach(context, registry, executor);
  }

  /**
   * For convenience when writing tests, this allows us to make fake messages from Flutter via
   * Platform Channels. Typically those calls happen on the ui thread which dispatches to the
   * platform thread. Since tests run on the platform thread it makes it difficult to test without
   * this, but isn't technically required.
   */
  @Implements(io.flutter.embedding.engine.dart.PlatformTaskQueue.class)
  public static class ShadowPlatformTaskQueue {
    @Implementation
    public void dispatch(Runnable runnable) {
      runnable.run();
    }
  }

  /**
   * The shadow class of {@link Presentation} to simulate Presentation showing logic.
   *
   * <p>Robolectric doesn't support VirtualDisplay creating correctly now, so this shadow class is
   * used to simulate custom logic for Presentation.
   */
  @Implements(Presentation.class)
  public static class ShadowPresentation extends ShadowDialog {
    private boolean isShowing = false;

    public ShadowPresentation() {}

    @Implementation
    protected void show() {
      isShowing = true;
    }

    @Implementation
    protected void dismiss() {
      isShowing = false;
    }

    @Implementation
    protected boolean isShowing() {
      return isShowing;
    }
  }

  @Implements(FlutterJNI.class)
  public static class ShadowFlutterJNI {
    private static SparseArray<ByteBuffer> replies = new SparseArray<>();

    public ShadowFlutterJNI() {}

    @Implementation
    public boolean getIsSoftwareRenderingEnabled() {
      return false;
    }

    @Implementation
    public long performNativeAttach(FlutterJNI flutterJNI) {
      return 1;
    }

    @Implementation
    public void dispatchPlatformMessage(
        String channel, ByteBuffer message, int position, int responseId) {}

    @Implementation
    public void onSurfaceCreated(Surface surface) {}

    @Implementation
    public void onSurfaceDestroyed() {}

    @Implementation
    public void onSurfaceWindowChanged(Surface surface) {}

    @Implementation
    public void setViewportMetrics(
        float devicePixelRatio,
        int physicalWidth,
        int physicalHeight,
        int physicalPaddingTop,
        int physicalPaddingRight,
        int physicalPaddingBottom,
        int physicalPaddingLeft,
        int physicalViewInsetTop,
        int physicalViewInsetRight,
        int physicalViewInsetBottom,
        int physicalViewInsetLeft,
        int systemGestureInsetTop,
        int systemGestureInsetRight,
        int systemGestureInsetBottom,
        int systemGestureInsetLeft,
        int physicalTouchSlop,
        int[] displayFeaturesBounds,
        int[] displayFeaturesType,
        int[] displayFeaturesState) {}

    @Implementation
    public void invokePlatformMessageResponseCallback(
        int responseId, ByteBuffer message, int position) {
      replies.put(responseId, message);
    }

    public static SparseArray<ByteBuffer> getResponses() {
      return replies;
    }
  }

  @Implements(SurfaceView.class)
  public static class ShadowFlutterSurfaceView extends ShadowSurfaceView {
    private final FakeSurfaceHolder holder = new FakeSurfaceHolder();

    public static class FakeSurfaceHolder extends ShadowSurfaceView.FakeSurfaceHolder {
      private final Surface surface = mock(Surface.class);

      public Surface getSurface() {
        return surface;
      }

      @Implementation
      public void addCallback(SurfaceHolder.Callback callback) {
        callback.surfaceCreated(this);
      }
    }

    public ShadowFlutterSurfaceView() {}

    @Implementation
    public SurfaceHolder getHolder() {
      return holder;
    }
  }
}

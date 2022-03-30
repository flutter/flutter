package io.flutter.plugin.platform;

import static android.os.Looper.getMainLooper;
import static io.flutter.embedding.engine.systemchannels.PlatformViewsChannel.PlatformViewTouch;
import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.robolectric.Shadows.shadowOf;

import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.SurfaceTexture;
import android.util.SparseArray;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewParent;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.FlutterImageView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.MotionEventTracker;
import io.flutter.embedding.android.RenderMode;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.FlutterOverlaySurface;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.mutatorsstack.FlutterMutatorView;
import io.flutter.embedding.engine.mutatorsstack.FlutterMutatorsStack;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.embedding.engine.systemchannels.MouseCursorChannel;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.plugin.localization.LocalizationPlugin;
import io.flutter.view.TextureRegistry;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadows.ShadowSurfaceView;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class PlatformViewsControllerTest {

  @Ignore
  @Test
  public void itUsesActionEventTypeFromMotionEventForHybridPlatformViews() {
    MotionEventTracker motionEventTracker = MotionEventTracker.getInstance();
    PlatformViewsController platformViewsController = new PlatformViewsController();

    MotionEvent original =
        MotionEvent.obtain(
            100, // downTime
            100, // eventTime
            1, // action
            0, // x
            0, // y
            0 // metaState
            );

    // track an event that will later get passed to us from framework
    MotionEventTracker.MotionEventId motionEventId = motionEventTracker.track(original);

    PlatformViewTouch frameWorkTouch =
        new PlatformViewTouch(
            0, // viewId
            original.getDownTime(),
            original.getEventTime(),
            2, // action
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
        platformViewsController.toMotionEvent(/*density=*/ 1, frameWorkTouch);

    assertNotEquals(resolvedEvent.getAction(), frameWorkTouch.action);
    assertEquals(resolvedEvent.getAction(), original.getAction());
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void getPlatformViewById__hybridComposition() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);

    platformViewsController.initializePlatformViewIfNeeded(platformViewId);

    View resultAndroidView = platformViewsController.getPlatformViewById(platformViewId);
    assertNotNull(resultAndroidView);
    assertEquals(resultAndroidView, androidView);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createPlatformViewMessage__initializesAndroidView() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(mock(View.class));
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);
    verify(viewFactory, times(1)).create(any(), eq(platformViewId), any());
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createPlatformViewMessage__throwsIfViewIsNull() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(null);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(
        jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ false);
    assertEquals(ShadowFlutterJNI.getResponses().size(), 1);

    assertThrows(
        IllegalStateException.class,
        () -> {
          platformViewsController.initializePlatformViewIfNeeded(platformViewId);
        });
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createHybridPlatformViewMessage__throwsIfViewIsNull() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(null);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);
    assertEquals(ShadowFlutterJNI.getResponses().size(), 1);

    assertThrows(
        IllegalStateException.class,
        () -> {
          platformViewsController.initializePlatformViewIfNeeded(platformViewId);
        });
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createPlatformViewMessage__throwsIfViewHasParent() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    View androidView = mock(View.class);
    when(androidView.getParent()).thenReturn(mock(ViewParent.class));
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(
        jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ false);
    assertEquals(ShadowFlutterJNI.getResponses().size(), 1);

    assertThrows(
        IllegalStateException.class,
        () -> {
          platformViewsController.initializePlatformViewIfNeeded(platformViewId);
        });
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void createHybridPlatformViewMessage__throwsIfViewHasParent() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    View androidView = mock(View.class);
    when(androidView.getParent()).thenReturn(mock(ViewParent.class));
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);
    assertEquals(ShadowFlutterJNI.getResponses().size(), 1);

    assertThrows(
        IllegalStateException.class,
        () -> {
          platformViewsController.initializePlatformViewIfNeeded(platformViewId);
        });
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void setPlatformViewDirection__throwIfPlatformViewNotFound() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    final View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    verify(androidView, never()).setLayoutDirection(anyInt());

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);
    assertEquals(ShadowFlutterJNI.getResponses().size(), 1);

    // Simulate set direction call from the framework.
    setLayoutDirection(jni, platformViewsController, platformViewId, 1);
    verify(androidView, times(1)).setLayoutDirection(1);

    // The limit value of reply message will be equal to 2 if the layout direction is set
    // successfully, otherwise it will be much more than 2 due to the reply message contains
    // an error message wrapped with exception detail information.
    assertEquals(ShadowFlutterJNI.getResponses().get(0).limit(), 2);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void disposeAndroidView__hybridComposition() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);

    Context context = RuntimeEnvironment.application.getApplicationContext();
    View androidView = new View(context);

    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);
    platformViewsController.initializePlatformViewIfNeeded(platformViewId);

    assertNotNull(androidView.getParent());
    assertTrue(androidView.getParent() instanceof FlutterMutatorView);

    // Simulate dispose call from the framework.
    disposePlatformView(jni, platformViewsController, platformViewId);
    assertNull(androidView.getParent());

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);
    platformViewsController.initializePlatformViewIfNeeded(platformViewId);

    assertNotNull(androidView.getParent());
    assertTrue(androidView.getParent() instanceof FlutterMutatorView);
    verify(platformView, times(1)).dispose();
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void disposeNullAndroidView() {
    PlatformViewsController platformViewsController = new PlatformViewsController();

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);

    Context context = RuntimeEnvironment.application.getApplicationContext();
    View androidView = new View(context);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    attach(jni, platformViewsController);

    // Simulate create call from the framework.
    createPlatformView(
        jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ false);
    platformViewsController.initializePlatformViewIfNeeded(platformViewId);

    when(platformView.getView()).thenReturn(null);

    // Simulate dispose call from the framework.
    disposePlatformView(jni, platformViewsController, platformViewId);
    verify(platformView, times(1)).dispose();
  }

  @Test
  @Config(
      shadows = {
        ShadowFlutterSurfaceView.class,
        ShadowFlutterJNI.class,
        ShadowPlatformTaskQueue.class
      })
  public void onEndFrame__destroysOverlaySurfaceAfterFrameOnFlutterSurfaceView() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(mock(View.class));
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    attach(jni, platformViewsController);

    jni.onFirstFrame();

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);

    // Produce a frame that displays a platform view and an overlay surface.
    platformViewsController.onBeginFrame();
    platformViewsController.onDisplayPlatformView(
        platformViewId,
        /* x=*/ 0,
        /* y=*/ 0,
        /* width=*/ 10,
        /* height=*/ 10,
        /* viewWidth=*/ 10,
        /* viewHeight=*/ 10,
        /* mutatorsStack=*/ new FlutterMutatorsStack());

    final FlutterImageView overlayImageView = mock(FlutterImageView.class);
    when(overlayImageView.acquireLatestImage()).thenReturn(true);

    final FlutterOverlaySurface overlaySurface =
        platformViewsController.createOverlaySurface(overlayImageView);
    platformViewsController.onDisplayOverlaySurface(
        overlaySurface.getId(), /* x=*/ 0, /* y=*/ 0, /* width=*/ 10, /* height=*/ 10);

    platformViewsController.onEndFrame();

    // Simulate first frame from the framework.
    jni.onFirstFrame();

    verify(overlayImageView, never()).detachFromRenderer();

    // Produce a frame that doesn't display platform views.
    platformViewsController.onBeginFrame();
    platformViewsController.onEndFrame();

    shadowOf(getMainLooper()).idle();
    verify(overlayImageView, times(1)).detachFromRenderer();
  }

  @Test
  @Config(shadows = {ShadowFlutterSurfaceView.class, ShadowFlutterJNI.class})
  public void onEndFrame__removesPlatformView() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    final View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    attach(jni, platformViewsController);

    jni.onFirstFrame();

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);

    // Simulate first frame from the framework.
    jni.onFirstFrame();
    platformViewsController.onBeginFrame();

    platformViewsController.onEndFrame();
    verify(androidView, never()).setVisibility(View.GONE);

    final ViewParent parentView = mock(ViewParent.class);
    when(androidView.getParent()).thenReturn(parentView);
  }

  @Test
  @Config(
      shadows = {
        ShadowFlutterSurfaceView.class,
        ShadowFlutterJNI.class,
        ShadowPlatformTaskQueue.class
      })
  public void onEndFrame__removesPlatformViewParent() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    final View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();

    final FlutterView flutterView = attach(jni, platformViewsController);

    jni.onFirstFrame();

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);
    platformViewsController.initializePlatformViewIfNeeded(platformViewId);
    assertEquals(flutterView.getChildCount(), 2);

    // Simulate first frame from the framework.
    jni.onFirstFrame();
    platformViewsController.onBeginFrame();
    platformViewsController.onEndFrame();

    // Simulate dispose call from the framework.
    disposePlatformView(jni, platformViewsController, platformViewId);
    assertEquals(flutterView.getChildCount(), 1);
  }

  @Test
  @Config(
      shadows = {
        ShadowFlutterSurfaceView.class,
        ShadowFlutterJNI.class,
        ShadowPlatformTaskQueue.class
      })
  public void detach__destroysOverlaySurfaces() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(mock(View.class));
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    attach(jni, platformViewsController);

    jni.onFirstFrame();

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);

    // Produce a frame that displays a platform view and an overlay surface.
    platformViewsController.onBeginFrame();
    platformViewsController.onDisplayPlatformView(
        platformViewId,
        /* x=*/ 0,
        /* y=*/ 0,
        /* width=*/ 10,
        /* height=*/ 10,
        /* viewWidth=*/ 10,
        /* viewHeight=*/ 10,
        /* mutatorsStack=*/ new FlutterMutatorsStack());

    final FlutterImageView overlayImageView = mock(FlutterImageView.class);
    when(overlayImageView.acquireLatestImage()).thenReturn(true);

    final FlutterOverlaySurface overlaySurface =
        platformViewsController.createOverlaySurface(overlayImageView);
    // This is OK.
    platformViewsController.onDisplayOverlaySurface(
        overlaySurface.getId(), /* x=*/ 0, /* y=*/ 0, /* width=*/ 10, /* height=*/ 10);

    platformViewsController.detach();

    verify(overlayImageView, times(1)).closeImageReader();
    verify(overlayImageView, times(1)).detachFromRenderer();
  }

  @Test
  @Config(shadows = {ShadowFlutterSurfaceView.class, ShadowFlutterJNI.class})
  public void detachFromView__removesAndDestroysOverlayViews() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(mock(View.class));
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    attach(jni, platformViewsController);

    final FlutterView flutterView = mock(FlutterView.class);
    platformViewsController.attachToView(flutterView);

    final FlutterImageView overlayImageView = mock(FlutterImageView.class);
    when(overlayImageView.acquireLatestImage()).thenReturn(true);

    final FlutterOverlaySurface overlaySurface =
        platformViewsController.createOverlaySurface(overlayImageView);

    platformViewsController.onDisplayOverlaySurface(
        overlaySurface.getId(), /* x=*/ 0, /* y=*/ 0, /* width=*/ 10, /* height=*/ 10);

    platformViewsController.detachFromView();

    verify(overlayImageView, times(1)).closeImageReader();
    verify(overlayImageView, times(1)).detachFromRenderer();
    verify(flutterView, times(1)).removeView(overlayImageView);
  }

  @Test
  @Config(shadows = {ShadowFlutterSurfaceView.class, ShadowFlutterJNI.class})
  public void destroyOverlaySurfaces__doesNotThrowIfFlutterViewIsDetached() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(mock(View.class));
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    attach(jni, platformViewsController);

    final FlutterView flutterView = mock(FlutterView.class);
    platformViewsController.attachToView(flutterView);

    final FlutterImageView overlayImageView = mock(FlutterImageView.class);
    when(overlayImageView.acquireLatestImage()).thenReturn(true);

    final FlutterOverlaySurface overlaySurface =
        platformViewsController.createOverlaySurface(overlayImageView);

    platformViewsController.onDisplayOverlaySurface(
        overlaySurface.getId(), /* x=*/ 0, /* y=*/ 0, /* width=*/ 10, /* height=*/ 10);

    platformViewsController.detachFromView();

    platformViewsController.destroyOverlaySurfaces();
    verify(overlayImageView, times(1)).closeImageReader();
    verify(overlayImageView, times(1)).detachFromRenderer();
  }

  @Test
  @Config(shadows = {ShadowFlutterSurfaceView.class, ShadowFlutterJNI.class})
  public void destroyOverlaySurfaces__doesNotRemoveOverlayView() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    when(platformView.getView()).thenReturn(mock(View.class));
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    attach(jni, platformViewsController);

    final FlutterView flutterView = mock(FlutterView.class);
    platformViewsController.attachToView(flutterView);

    final FlutterImageView overlayImageView = mock(FlutterImageView.class);
    when(overlayImageView.acquireLatestImage()).thenReturn(true);

    final FlutterOverlaySurface overlaySurface =
        platformViewsController.createOverlaySurface(overlayImageView);

    platformViewsController.onDisplayOverlaySurface(
        overlaySurface.getId(), /* x=*/ 0, /* y=*/ 0, /* width=*/ 10, /* height=*/ 10);

    platformViewsController.destroyOverlaySurfaces();
    verify(flutterView, never()).removeView(overlayImageView);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void convertPlatformViewRenderSurfaceAsDefault() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    final View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    final FlutterView flutterView = attach(jni, platformViewsController);

    jni.onFirstFrame();

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);

    // Produce a frame that displays a platform view and an overlay surface.
    platformViewsController.onBeginFrame();
    platformViewsController.onDisplayPlatformView(
        platformViewId,
        /* x=*/ 0,
        /* y=*/ 0,
        /* width=*/ 10,
        /* height=*/ 10,
        /* viewWidth=*/ 10,
        /* viewHeight=*/ 10,
        /* mutatorsStack=*/ new FlutterMutatorsStack());

    assertEquals(flutterView.getChildCount(), 3);

    final View view = flutterView.getChildAt(1);
    assertTrue(view instanceof FlutterImageView);

    // Simulate dispose call from the framework.
    disposePlatformView(jni, platformViewsController, platformViewId);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void dontConverRenderSurfaceWhenFlagIsTrue() {
    final PlatformViewsController platformViewsController = new PlatformViewsController();

    final int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    final PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    final PlatformView platformView = mock(PlatformView.class);
    final View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);

    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    final FlutterJNI jni = new FlutterJNI();
    jni.attachToNative();
    final FlutterView flutterView = attach(jni, platformViewsController);

    jni.onFirstFrame();

    // Simulate setting render surface conversion flag.
    synchronizeToNativeViewHierarchy(jni, platformViewsController, false);

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ true);

    // Produce a frame that displays a platform view and an overlay surface.
    platformViewsController.onBeginFrame();
    platformViewsController.onDisplayPlatformView(
        platformViewId,
        /* x=*/ 0,
        /* y=*/ 0,
        /* width=*/ 10,
        /* height=*/ 10,
        /* viewWidth=*/ 10,
        /* viewHeight=*/ 10,
        /* mutatorsStack=*/ new FlutterMutatorsStack());

    assertEquals(flutterView.getChildCount(), 2);
    assertTrue(!(flutterView.getChildAt(0) instanceof FlutterImageView));
    assertTrue(flutterView.getChildAt(1) instanceof FlutterMutatorView);

    // Simulate dispose call from the framework.
    disposePlatformView(jni, platformViewsController, platformViewId);
  }

  @Test
  @Config(shadows = {ShadowFlutterJNI.class, ShadowPlatformTaskQueue.class})
  public void reattachToFlutterView() {
    PlatformViewsController platformViewsController = new PlatformViewsController();
    platformViewsController.setSoftwareRendering(true);

    int platformViewId = 0;
    assertNull(platformViewsController.getPlatformViewById(platformViewId));

    PlatformViewFactory viewFactory = mock(PlatformViewFactory.class);
    PlatformView platformView = mock(PlatformView.class);
    View androidView = mock(View.class);
    when(platformView.getView()).thenReturn(androidView);
    when(viewFactory.create(any(), eq(platformViewId), any())).thenReturn(platformView);
    platformViewsController.getRegistry().registerViewFactory("testType", viewFactory);

    FlutterJNI jni = new FlutterJNI();
    FlutterView initFlutterView = mock(FlutterView.class);
    attachToFlutterView(jni, platformViewsController, initFlutterView);

    createPlatformView(
        jni, platformViewsController, platformViewId, "testType", /* hybrid=*/ false);
    verify(initFlutterView, times(1)).addView(any(PlatformViewWrapper.class));

    platformViewsController.detachFromView();
    verify(initFlutterView, times(1)).removeView(any(PlatformViewWrapper.class));

    FlutterView newFlutterView = mock(FlutterView.class);
    platformViewsController.attachToView(newFlutterView);
    verify(newFlutterView, times(1)).addView(any(PlatformViewWrapper.class));
  }

  private static ByteBuffer encodeMethodCall(MethodCall call) {
    final ByteBuffer buffer = StandardMethodCodec.INSTANCE.encodeMethodCall(call);
    buffer.rewind();
    return buffer;
  }

  private static void createPlatformView(
      FlutterJNI jni,
      PlatformViewsController platformViewsController,
      int platformViewId,
      String viewType,
      boolean hybrid) {
    final Map<String, Object> platformViewCreateArguments = new HashMap<>();
    platformViewCreateArguments.put("hybrid", hybrid);
    platformViewCreateArguments.put("id", platformViewId);
    platformViewCreateArguments.put("viewType", viewType);
    platformViewCreateArguments.put("direction", 0);
    platformViewCreateArguments.put("width", 1.0);
    platformViewCreateArguments.put("height", 1.0);

    final MethodCall platformCreateMethodCall =
        new MethodCall("create", platformViewCreateArguments);

    jni.handlePlatformMessage(
        "flutter/platform_views",
        encodeMethodCall(platformCreateMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static void setLayoutDirection(
      FlutterJNI jni,
      PlatformViewsController platformViewsController,
      int platformViewId,
      int direction) {
    final Map<String, Object> platformViewCreateArguments = new HashMap<>();
    platformViewCreateArguments.put("id", platformViewId);
    platformViewCreateArguments.put("direction", direction);

    final MethodCall platformCreateMethodCall =
        new MethodCall("setDirection", platformViewCreateArguments);

    jni.handlePlatformMessage(
        "flutter/platform_views",
        encodeMethodCall(platformCreateMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static void disposePlatformView(
      FlutterJNI jni, PlatformViewsController platformViewsController, int platformViewId) {

    final Map<String, Object> platformViewDisposeArguments = new HashMap<>();
    platformViewDisposeArguments.put("hybrid", true);
    platformViewDisposeArguments.put("id", platformViewId);

    final MethodCall platformDisposeMethodCall =
        new MethodCall("dispose", platformViewDisposeArguments);

    jni.handlePlatformMessage(
        "flutter/platform_views",
        encodeMethodCall(platformDisposeMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static void synchronizeToNativeViewHierarchy(
      FlutterJNI jni, PlatformViewsController platformViewsController, boolean yes) {

    final MethodCall convertMethodCall = new MethodCall("synchronizeToNativeViewHierarchy", yes);

    jni.handlePlatformMessage(
        "flutter/platform_views",
        encodeMethodCall(convertMethodCall),
        /*replyId=*/ 0,
        /*messageData=*/ 0);
  }

  private static FlutterView attach(
      FlutterJNI jni, PlatformViewsController platformViewsController) {
    final Context context = RuntimeEnvironment.application.getApplicationContext();
    final FlutterView flutterView =
        new FlutterView(context, RenderMode.surface) {
          @Override
          public FlutterImageView createImageView() {
            final FlutterImageView view = mock(FlutterImageView.class);
            when(view.acquireLatestImage()).thenReturn(true);
            return mock(FlutterImageView.class);
          }
        };
    attachToFlutterView(jni, platformViewsController, flutterView);
    return flutterView;
  }

  private static void attachToFlutterView(
      FlutterJNI jni, PlatformViewsController platformViewsController, FlutterView flutterView) {
    final DartExecutor executor = new DartExecutor(jni, mock(AssetManager.class));
    executor.onAttachedToJNI();

    final Context context = RuntimeEnvironment.application.getApplicationContext();
    final TextureRegistry registry =
        new TextureRegistry() {
          public void TextureRegistry() {}

          @Override
          public SurfaceTextureEntry createSurfaceTexture() {
            return registerSurfaceTexture(mock(SurfaceTexture.class));
          }

          @Override
          public SurfaceTextureEntry registerSurfaceTexture(SurfaceTexture surfaceTexture) {
            return new SurfaceTextureEntry() {
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
        };

    platformViewsController.attach(context, registry, executor);

    final FlutterEngine engine = mock(FlutterEngine.class);
    when(engine.getRenderer()).thenReturn(new FlutterRenderer(jni));
    when(engine.getMouseCursorChannel()).thenReturn(mock(MouseCursorChannel.class));
    when(engine.getTextInputChannel()).thenReturn(mock(TextInputChannel.class));
    when(engine.getSettingsChannel()).thenReturn(new SettingsChannel(executor));
    when(engine.getPlatformViewsController()).thenReturn(platformViewsController);
    when(engine.getLocalizationPlugin()).thenReturn(mock(LocalizationPlugin.class));
    when(engine.getKeyEventChannel()).thenReturn(mock(KeyEventChannel.class));
    when(engine.getAccessibilityChannel()).thenReturn(mock(AccessibilityChannel.class));

    flutterView.attachToFlutterEngine(engine);
    platformViewsController.attachToView(flutterView);
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

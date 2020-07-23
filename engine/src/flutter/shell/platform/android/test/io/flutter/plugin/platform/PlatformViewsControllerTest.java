package io.flutter.plugin.platform;

import static io.flutter.embedding.engine.systemchannels.PlatformViewsChannel.PlatformViewTouch;
import static org.junit.Assert.*;
import static org.mockito.Matchers.*;
import static org.mockito.Mockito.*;

import android.content.Context;
import android.content.res.AssetManager;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewParent;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.MotionEventTracker;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.mutatorsstack.FlutterMutatorView;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.StandardMethodCodec;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class PlatformViewsControllerTest {

  @Ignore
  @Test
  public void itNotifiesVirtualDisplayControllersOfViewAttachmentAndDetachment() {
    // Setup test structure.
    // Create a fake View that represents the View that renders a Flutter UI.
    View fakeFlutterView = new View(RuntimeEnvironment.systemContext);

    // Create fake VirtualDisplayControllers. This requires internal knowledge of
    // PlatformViewsController. We know that all PlatformViewsController does is
    // forward view attachment/detachment calls to it's VirtualDisplayControllers.
    //
    // TODO(mattcarroll): once PlatformViewsController is refactored into testable
    // pieces, remove this test and avoid verifying private behavior.
    VirtualDisplayController fakeVdController1 = mock(VirtualDisplayController.class);
    VirtualDisplayController fakeVdController2 = mock(VirtualDisplayController.class);

    // Create the PlatformViewsController that is under test.
    PlatformViewsController platformViewsController = new PlatformViewsController();

    // Manually inject fake VirtualDisplayControllers into the PlatformViewsController.
    platformViewsController.vdControllers.put(0, fakeVdController1);
    platformViewsController.vdControllers.put(1, fakeVdController1);

    // Execute test & verify results.
    // Attach PlatformViewsController to the fake Flutter View.
    platformViewsController.attachToView(fakeFlutterView);

    // Verify that all virtual display controllers were notified of View attachment.
    verify(fakeVdController1, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController1, never()).onFlutterViewDetached();
    verify(fakeVdController2, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController2, never()).onFlutterViewDetached();

    // Detach PlatformViewsController from the fake Flutter View.
    platformViewsController.detachFromView();

    // Verify that all virtual display controllers were notified of the View detachment.
    verify(fakeVdController1, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController1, times(1)).onFlutterViewDetached();
    verify(fakeVdController2, times(1)).onFlutterViewAttached(eq(fakeFlutterView));
    verify(fakeVdController2, times(1)).onFlutterViewDetached();
  }

  @Ignore
  @Test
  public void itCancelsOldPresentationOnResize() {
    // Setup test structure.
    // Create a fake View that represents the View that renders a Flutter UI.
    View fakeFlutterView = new View(RuntimeEnvironment.systemContext);

    // Create fake VirtualDisplayControllers. This requires internal knowledge of
    // PlatformViewsController. We know that all PlatformViewsController does is
    // forward view attachment/detachment calls to it's VirtualDisplayControllers.
    //
    // TODO(mattcarroll): once PlatformViewsController is refactored into testable
    // pieces, remove this test and avoid verifying private behavior.
    VirtualDisplayController fakeVdController1 = mock(VirtualDisplayController.class);

    SingleViewPresentation presentation = fakeVdController1.presentation;

    fakeVdController1.resize(10, 10, null);

    assertEquals(fakeVdController1.presentation != presentation, true);
    assertEquals(presentation.isShowing(), false);
  }

  @Test
  public void itUsesActionEventTypeFromFrameworkEventForVirtualDisplays() {
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
        platformViewsController.toMotionEvent(
            1, // density
            frameWorkTouch,
            true // usingVirtualDisplays
            );

    assertEquals(resolvedEvent.getAction(), frameWorkTouch.action);
    assertNotEquals(resolvedEvent.getAction(), original.getAction());
  }

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
        platformViewsController.toMotionEvent(
            1, // density
            frameWorkTouch,
            false // usingVirtualDisplays
            );

    assertNotEquals(resolvedEvent.getAction(), frameWorkTouch.action);
    assertEquals(resolvedEvent.getAction(), original.getAction());
  }

  @Test
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
    createPlatformView(jni, platformViewsController, platformViewId, "testType");

    platformViewsController.initializePlatformViewIfNeeded(platformViewId);

    View resultAndroidView = platformViewsController.getPlatformViewById(platformViewId);
    assertNotNull(resultAndroidView);
    assertEquals(resultAndroidView, androidView);
  }

  @Test
  public void initializePlatformViewIfNeeded__throwsIfViewIsNull() {
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
    createPlatformView(jni, platformViewsController, platformViewId, "testType");

    try {
      platformViewsController.initializePlatformViewIfNeeded(platformViewId);
    } catch (Exception exception) {
      assertTrue(exception instanceof IllegalStateException);
      assertEquals(
          exception.getMessage(),
          "PlatformView#getView() returned null, but an Android view reference was expected.");
      return;
    }
    assertTrue(false);
  }

  @Test
  public void initializePlatformViewIfNeeded__throwsIfViewHasParent() {
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
    createPlatformView(jni, platformViewsController, platformViewId, "testType");
    try {
      platformViewsController.initializePlatformViewIfNeeded(platformViewId);
    } catch (Exception exception) {
      assertTrue(exception instanceof IllegalStateException);
      assertEquals(
          exception.getMessage(),
          "The Android view returned from PlatformView#getView() was already added to a parent view.");
      return;
    }
    assertTrue(false);
  }

  @Test
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
    createPlatformView(jni, platformViewsController, platformViewId, "testType");
    platformViewsController.initializePlatformViewIfNeeded(platformViewId);

    assertNotNull(androidView.getParent());
    assertTrue(androidView.getParent() instanceof FlutterMutatorView);

    // Simulate dispose call from the framework.
    disposePlatformView(jni, platformViewsController, platformViewId);
    assertNull(androidView.getParent());

    // Simulate create call from the framework.
    createPlatformView(jni, platformViewsController, platformViewId, "testType");
    platformViewsController.initializePlatformViewIfNeeded(platformViewId);

    assertNotNull(androidView.getParent());
    assertTrue(androidView.getParent() instanceof FlutterMutatorView);
  }

  private static byte[] encodeMethodCall(MethodCall call) {
    ByteBuffer buffer = StandardMethodCodec.INSTANCE.encodeMethodCall(call);
    buffer.rewind();
    byte[] dest = new byte[buffer.remaining()];
    buffer.get(dest);
    return dest;
  }

  private static void createPlatformView(
      FlutterJNI jni,
      PlatformViewsController platformViewsController,
      int platformViewId,
      String viewType) {
    Map<String, Object> platformViewCreateArguments = new HashMap<>();
    platformViewCreateArguments.put("hybrid", true);
    platformViewCreateArguments.put("id", platformViewId);
    platformViewCreateArguments.put("viewType", viewType);
    platformViewCreateArguments.put("direction", 0);
    MethodCall platformCreateMethodCall = new MethodCall("create", platformViewCreateArguments);

    jni.handlePlatformMessage(
        "flutter/platform_views", encodeMethodCall(platformCreateMethodCall), /*replyId=*/ 0);
  }

  private static void disposePlatformView(
      FlutterJNI jni, PlatformViewsController platformViewsController, int platformViewId) {
    Map<String, Object> platformViewDisposeArguments = new HashMap<>();
    platformViewDisposeArguments.put("hybrid", true);
    platformViewDisposeArguments.put("id", platformViewId);
    MethodCall platformDisposeMethodCall = new MethodCall("dispose", platformViewDisposeArguments);

    jni.handlePlatformMessage(
        "flutter/platform_views", encodeMethodCall(platformDisposeMethodCall), /*replyId=*/ 0);
  }

  private void attach(FlutterJNI jni, PlatformViewsController platformViewsController) {
    DartExecutor executor = new DartExecutor(jni, mock(AssetManager.class));
    executor.onAttachedToJNI();

    Context context = RuntimeEnvironment.application.getApplicationContext();
    platformViewsController.attach(context, null, executor);

    platformViewsController.attachToView(mock(FlutterView.class));
  }
}

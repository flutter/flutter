package io.flutter.embedding.android;

import static junit.framework.TestCase.assertEquals;
import static junit.framework.TestCase.assertFalse;
import static junit.framework.TestCase.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Insets;
import android.graphics.Rect;
import android.graphics.Region;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.Image.Plane;
import android.media.ImageReader;
import android.os.Build;
import android.view.DisplayCutout;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.widget.FrameLayout;
import androidx.core.util.Consumer;
import androidx.window.layout.FoldingFeature;
import androidx.window.layout.WindowLayoutInfo;
import io.flutter.TestUtils;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.plugin.platform.PlatformViewsController;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadows.ShadowDisplay;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
@TargetApi(30)
public class FlutterViewTest {
  @Mock FlutterJNI mockFlutterJni;
  @Mock FlutterLoader mockFlutterLoader;
  @Spy PlatformViewsController platformViewsController;

  @Before
  public void setUp() {
    MockitoAnnotations.openMocks(this);
    when(mockFlutterJni.isAttached()).thenReturn(true);
  }

  @Test
  public void attachToFlutterEngine_alertsPlatformViews() {
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    when(flutterEngine.getPlatformViewsController()).thenReturn(platformViewsController);

    flutterView.attachToFlutterEngine(flutterEngine);

    verify(platformViewsController, times(1)).attachToView(flutterView);
  }

  @Test
  public void detachFromFlutterEngine_alertsPlatformViews() {
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    when(flutterEngine.getPlatformViewsController()).thenReturn(platformViewsController);

    flutterView.attachToFlutterEngine(flutterEngine);
    flutterView.detachFromFlutterEngine();

    verify(platformViewsController, times(1)).detachFromView();
  }

  @Test
  public void detachFromFlutterEngine_turnsOffA11y() {
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    flutterView.attachToFlutterEngine(flutterEngine);
    flutterView.detachFromFlutterEngine();

    verify(flutterRenderer, times(1)).setSemanticsEnabled(false);
  }

  @Test
  public void detachFromFlutterEngine_revertImageView() {
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));

    flutterView.attachToFlutterEngine(flutterEngine);
    assertFalse(flutterView.renderSurface instanceof FlutterImageView);

    flutterView.convertToImageView();
    assertTrue(flutterView.renderSurface instanceof FlutterImageView);

    flutterView.detachFromFlutterEngine();
    assertFalse(flutterView.renderSurface instanceof FlutterImageView);
  }

  @Test
  public void detachFromFlutterEngine_closesImageView() {
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));

    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    FlutterImageView imageViewMock = mock(FlutterImageView.class);
    when(imageViewMock.getAttachedRenderer()).thenReturn(flutterRenderer);

    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.application));
    when(flutterView.createImageView()).thenReturn(imageViewMock);

    flutterView.attachToFlutterEngine(flutterEngine);

    assertFalse(flutterView.renderSurface == imageViewMock);

    flutterView.convertToImageView();
    assertTrue(flutterView.renderSurface == imageViewMock);

    flutterView.detachFromFlutterEngine();
    assertFalse(flutterView.renderSurface == imageViewMock);
    verify(imageViewMock, times(1)).closeImageReader();
  }

  @Test
  public void onConfigurationChanged_fizzlesWhenNullEngine() {
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));

    Configuration configuration = RuntimeEnvironment.application.getResources().getConfiguration();
    // 1 invocation of channels.
    flutterView.attachToFlutterEngine(flutterEngine);
    flutterView.onConfigurationChanged(configuration);
    flutterView.detachFromFlutterEngine();

    // Should fizzle.
    flutterView.onConfigurationChanged(configuration);

    verify(flutterEngine, times(1)).getLocalizationPlugin();
    verify(flutterEngine, times(2)).getSettingsChannel();
  }

  // TODO(mattcarroll): turn this into an e2e test. GitHub #42990
  @Test
  public void itSendsLightPlatformBrightnessToFlutter() {
    // Setup test.
    AtomicReference<SettingsChannel.PlatformBrightness> reportedBrightness =
        new AtomicReference<>();

    // FYI - The default brightness is LIGHT, which is why we don't need to configure it.
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));

    SettingsChannel fakeSettingsChannel = mock(SettingsChannel.class);
    SettingsChannel.MessageBuilder fakeMessageBuilder = mock(SettingsChannel.MessageBuilder.class);
    when(fakeMessageBuilder.setTextScaleFactor(any(Float.class))).thenReturn(fakeMessageBuilder);
    when(fakeMessageBuilder.setUse24HourFormat(any(Boolean.class))).thenReturn(fakeMessageBuilder);
    when(fakeMessageBuilder.setPlatformBrightness(any(SettingsChannel.PlatformBrightness.class)))
        .thenAnswer(
            new Answer<SettingsChannel.MessageBuilder>() {
              @Override
              public SettingsChannel.MessageBuilder answer(InvocationOnMock invocation)
                  throws Throwable {
                reportedBrightness.set(
                    (SettingsChannel.PlatformBrightness) invocation.getArguments()[0]);
                return fakeMessageBuilder;
              }
            });
    when(fakeSettingsChannel.startMessage()).thenReturn(fakeMessageBuilder);
    when(flutterEngine.getSettingsChannel()).thenReturn(fakeSettingsChannel);

    flutterView.attachToFlutterEngine(flutterEngine);

    // Execute behavior under test.
    flutterView.sendUserSettingsToFlutter();

    // Verify results.
    assertEquals(SettingsChannel.PlatformBrightness.light, reportedBrightness.get());
  }

  // TODO(mattcarroll): turn this into an e2e test. GitHub #42990
  @Test
  public void itSendsDarkPlatformBrightnessToFlutter() {
    // Setup test.
    AtomicReference<SettingsChannel.PlatformBrightness> reportedBrightness =
        new AtomicReference<>();

    Context spiedContext = spy(Robolectric.setupActivity(Activity.class));

    Resources spiedResources = spy(spiedContext.getResources());
    when(spiedContext.getResources()).thenReturn(spiedResources);

    Configuration spiedConfiguration = spy(spiedResources.getConfiguration());
    spiedConfiguration.uiMode =
        (spiedResources.getConfiguration().uiMode | Configuration.UI_MODE_NIGHT_YES)
            & ~Configuration.UI_MODE_NIGHT_NO;
    when(spiedResources.getConfiguration()).thenReturn(spiedConfiguration);

    FlutterView flutterView = new FlutterView(spiedContext);
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));

    SettingsChannel fakeSettingsChannel = mock(SettingsChannel.class);
    SettingsChannel.MessageBuilder fakeMessageBuilder = mock(SettingsChannel.MessageBuilder.class);
    when(fakeMessageBuilder.setTextScaleFactor(any(Float.class))).thenReturn(fakeMessageBuilder);
    when(fakeMessageBuilder.setUse24HourFormat(any(Boolean.class))).thenReturn(fakeMessageBuilder);
    when(fakeMessageBuilder.setPlatformBrightness(any(SettingsChannel.PlatformBrightness.class)))
        .thenAnswer(
            new Answer<SettingsChannel.MessageBuilder>() {
              @Override
              public SettingsChannel.MessageBuilder answer(InvocationOnMock invocation)
                  throws Throwable {
                reportedBrightness.set(
                    (SettingsChannel.PlatformBrightness) invocation.getArguments()[0]);
                return fakeMessageBuilder;
              }
            });
    when(fakeSettingsChannel.startMessage()).thenReturn(fakeMessageBuilder);
    when(flutterEngine.getSettingsChannel()).thenReturn(fakeSettingsChannel);

    // Execute behavior under test.
    flutterView.attachToFlutterEngine(flutterEngine);
    flutterView.sendUserSettingsToFlutter();

    // Verify results.
    assertEquals(SettingsChannel.PlatformBrightness.dark, reportedBrightness.get());
  }

  // This test uses the API 30+ Algorithm for window insets. The legacy algorithm is
  // set to -1 values, so it is clear if the wrong algorithm is used.
  @Test
  @TargetApi(30)
  @Config(
      sdk = 30,
      shadows = {
        FlutterViewTest.ShadowFullscreenView.class,
        FlutterViewTest.ShadowFullscreenViewGroup.class
      })
  public void setPaddingTopToZeroForFullscreenMode() {
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets, the viewport
    // metrics
    // default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets =
        new WindowInsets.Builder()
            .setInsets(
                android.view.WindowInsets.Type.navigationBars()
                    | android.view.WindowInsets.Type.statusBars(),
                Insets.of(100, 100, 100, 100))
            .build();
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(3)).setViewportMetrics(viewportMetricsCaptor.capture());
    validateViewportMetricPadding(viewportMetricsCaptor, 100, 100, 100, 100);
  }

  // This test uses the pre-API 30 Algorithm for window insets.
  @Test
  @TargetApi(28)
  @Config(
      sdk = 28,
      shadows = {
        FlutterViewTest.ShadowFullscreenView.class,
        FlutterViewTest.ShadowFullscreenViewGroup.class
      })
  public void setPaddingTopToZeroForFullscreenModeLegacy() {
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets, the viewport
    // metrics
    // default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    mockSystemWindowInsets(windowInsets, 100, 100, 100, 100);
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    validateViewportMetricPadding(viewportMetricsCaptor, 100, 0, 100, 0);
  }

  // This test uses the API 30+ Algorithm for window insets. The legacy algorithm is
  // set to -1 values, so it is clear if the wrong algorithm is used.
  @Test
  @TargetApi(30)
  @Config(sdk = 30)
  public void reportSystemInsetWhenNotFullscreen() {
    // Without custom shadows, the default system ui visibility flags is 0.
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    assertEquals(0, flutterView.getSystemUiVisibility());

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets, the viewport
    // metrics
    // default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets =
        new WindowInsets.Builder()
            .setInsets(
                android.view.WindowInsets.Type.navigationBars()
                    | android.view.WindowInsets.Type.statusBars(),
                Insets.of(100, 100, 100, 100))
            .build();
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(3)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is reported as-is.
    validateViewportMetricPadding(viewportMetricsCaptor, 100, 100, 100, 100);
  }

  // This test uses the pre-API 30 Algorithm for window insets.
  @Test
  @TargetApi(28)
  @Config(sdk = 28)
  public void reportSystemInsetWhenNotFullscreenLegacy() {
    // Without custom shadows, the default system ui visibility flags is 0.
    FlutterView flutterView = new FlutterView(Robolectric.setupActivity(Activity.class));
    assertEquals(0, flutterView.getSystemUiVisibility());

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets, the viewport
    // metrics
    // default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    mockSystemWindowInsets(windowInsets, 100, 100, 100, 100);
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is reported as-is.
    validateViewportMetricPadding(viewportMetricsCaptor, 100, 100, 100, 0);
  }

  @Test
  @Config(minSdk = 23, maxSdk = 29)
  public void systemInsetHandlesFullscreenNavbarRight() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    setExpectedDisplayRotation(Surface.ROTATION_90);
    assertEquals(0, flutterView.getSystemUiVisibility());
    when(flutterView.getWindowSystemUiVisibility())
        .thenReturn(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
    when(flutterView.getContext()).thenReturn(RuntimeEnvironment.systemContext);

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets,
    // the viewport metrics default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    mockSystemWindowInsets(windowInsets, 100, 100, 100, 100);
    mockSystemGestureInsetsIfNeed(windowInsets);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is removed due to full screen.
    // Right padding is zero because the rotation is 90deg
    // Bottom padding is removed due to hide navigation.
    validateViewportMetricPadding(viewportMetricsCaptor, 100, 0, 0, 0);
  }

  @Test
  @Config(minSdk = 20, maxSdk = 22)
  public void systemInsetHandlesFullscreenNavbarRightBelowSDK23() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    setExpectedDisplayRotation(Surface.ROTATION_270);
    assertEquals(0, flutterView.getSystemUiVisibility());
    when(flutterView.getWindowSystemUiVisibility())
        .thenReturn(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
    when(flutterView.getContext()).thenReturn(RuntimeEnvironment.systemContext);

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets,
    // the viewport metrics default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    mockSystemWindowInsets(windowInsets, 100, 100, 100, 100);
    mockSystemGestureInsetsIfNeed(windowInsets);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is removed due to full screen.
    // Right padding is zero because the rotation is 270deg under SDK 23
    // Bottom padding is removed due to hide navigation.
    validateViewportMetricPadding(viewportMetricsCaptor, 100, 0, 0, 0);
  }

  @Test
  @Config(minSdk = 23, maxSdk = 29)
  public void systemInsetHandlesFullscreenNavbarLeft() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    setExpectedDisplayRotation(Surface.ROTATION_270);
    assertEquals(0, flutterView.getSystemUiVisibility());
    when(flutterView.getWindowSystemUiVisibility())
        .thenReturn(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
    when(flutterView.getContext()).thenReturn(RuntimeEnvironment.systemContext);

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets,
    // the viewport metrics default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    mockSystemWindowInsets(windowInsets, 100, 100, 100, 100);
    mockSystemGestureInsetsIfNeed(windowInsets);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Left padding is zero because the rotation is 270deg
    // Top padding is removed due to full screen.
    // Bottom padding is removed due to hide navigation.
    validateViewportMetricPadding(viewportMetricsCaptor, 0, 0, 100, 0);
  }

  // This test uses the API 30+ Algorithm for window insets. The legacy algorithm is
  // set to -1 values, so it is clear if the wrong algorithm is used.
  @Test
  @TargetApi(30)
  @Config(sdk = 30)
  public void systemInsetGetInsetsFullscreen() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    setExpectedDisplayRotation(Surface.ROTATION_270);
    assertEquals(0, flutterView.getSystemUiVisibility());
    when(flutterView.getWindowSystemUiVisibility())
        .thenReturn(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
    when(flutterView.getContext()).thenReturn(RuntimeEnvironment.systemContext);

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets,
    // the viewport metrics default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    Insets insets = Insets.of(10, 20, 30, 40);
    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    mockSystemWindowInsets(windowInsets, -1, -1, -1, -1);
    when(windowInsets.getInsets(anyInt())).thenReturn(insets);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    validateViewportMetricPadding(viewportMetricsCaptor, 10, 20, 30, 40);
  }

  // This test uses the pre-API 30 Algorithm for window insets.
  @Test
  @TargetApi(28)
  @Config(sdk = 28)
  public void systemInsetGetInsetsFullscreenLegacy() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    setExpectedDisplayRotation(Surface.ROTATION_270);
    assertEquals(0, flutterView.getSystemUiVisibility());
    when(flutterView.getWindowSystemUiVisibility())
        .thenReturn(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
    when(flutterView.getContext()).thenReturn(RuntimeEnvironment.systemContext);

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets,
    // the viewport metrics default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    mockSystemWindowInsets(windowInsets, 102, 100, 103, 101);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Left padding is zero because the rotation is 270deg
    // Top padding is removed due to full screen.
    // Bottom padding is removed due to hide navigation.
    validateViewportMetricPadding(viewportMetricsCaptor, 0, 0, 103, 0);
  }

  // This test uses the API 30+ Algorithm for window insets. The legacy algorithm is
  // set to -1 values, so it is clear if the wrong algorithm is used.
  @Test
  @TargetApi(30)
  @Config(sdk = 30)
  public void systemInsetDisplayCutoutSimple() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    assertEquals(0, flutterView.getSystemUiVisibility());
    when(flutterView.getWindowSystemUiVisibility()).thenReturn(0);
    when(flutterView.getContext()).thenReturn(RuntimeEnvironment.systemContext);

    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    // When we attach a new FlutterView to the engine without any system insets,
    // the viewport metrics default to 0.
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().viewPaddingTop);

    Insets insets = Insets.of(100, 100, 100, 100);
    Insets systemGestureInsets = Insets.of(110, 110, 110, 110);
    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    DisplayCutout displayCutout = mock(DisplayCutout.class);
    mockSystemWindowInsets(windowInsets, -1, -1, -1, -1);
    when(windowInsets.getInsets(anyInt())).thenReturn(insets);
    when(windowInsets.getSystemGestureInsets()).thenReturn(systemGestureInsets);
    when(windowInsets.getDisplayCutout()).thenReturn(displayCutout);

    Insets waterfallInsets = Insets.of(200, 0, 200, 0);
    when(displayCutout.getWaterfallInsets()).thenReturn(waterfallInsets);
    when(displayCutout.getSafeInsetTop()).thenReturn(150);
    when(displayCutout.getSafeInsetBottom()).thenReturn(150);
    when(displayCutout.getSafeInsetLeft()).thenReturn(150);
    when(displayCutout.getSafeInsetRight()).thenReturn(150);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    validateViewportMetricPadding(viewportMetricsCaptor, 200, 150, 200, 150);

    assertEquals(100, viewportMetricsCaptor.getValue().viewInsetTop);
  }

  @Test
  public void itRegistersAndUnregistersToWindowManager() {
    Context context = Robolectric.setupActivity(Activity.class);
    FlutterView flutterView = spy(new FlutterView(context));
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
    WindowInfoRepositoryCallbackAdapterWrapper windowInfoRepo =
        mock(WindowInfoRepositoryCallbackAdapterWrapper.class);
    // For reasoning behing using doReturn instead of when, read "Important gotcha" at
    // https://www.javadoc.io/doc/org.mockito/mockito-core/1.10.19/org/mockito/Mockito.html#13
    doReturn(windowInfoRepo).when(flutterView).createWindowInfoRepo();

    // When a new FlutterView is attached to the window
    flutterView.onAttachedToWindow();

    // Then the WindowManager callback is registered
    verify(windowInfoRepo, times(1)).addWindowLayoutInfoListener(any(), any(), any());

    // When the FlutterView is detached from the window
    flutterView.onDetachedFromWindow();

    // Then the WindowManager callback is unregistered
    verify(windowInfoRepo, times(1)).removeWindowLayoutInfoListener(any());
  }

  @Test
  public void itSendsHingeDisplayFeatureToFlutter() {
    Context context = Robolectric.setupActivity(Activity.class);
    FlutterView flutterView = spy(new FlutterView(context));
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
    when(flutterView.getContext()).thenReturn(context);
    WindowInfoRepositoryCallbackAdapterWrapper windowInfoRepo =
        mock(WindowInfoRepositoryCallbackAdapterWrapper.class);
    doReturn(windowInfoRepo).when(flutterView).createWindowInfoRepo();
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    FoldingFeature displayFeature = mock(FoldingFeature.class);
    when(displayFeature.getBounds()).thenReturn(new Rect(0, 0, 100, 100));
    when(displayFeature.getOcclusionType()).thenReturn(FoldingFeature.OcclusionType.FULL);
    when(displayFeature.getState()).thenReturn(FoldingFeature.State.FLAT);

    WindowLayoutInfo testWindowLayout = new WindowLayoutInfo(Arrays.asList(displayFeature));

    // When FlutterView is attached to the engine and window, and a hinge display feature exists
    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(Arrays.asList(), viewportMetricsCaptor.getValue().displayFeatures);
    flutterView.onAttachedToWindow();
    ArgumentCaptor<Consumer<WindowLayoutInfo>> wmConsumerCaptor =
        ArgumentCaptor.forClass((Class) Consumer.class);
    verify(windowInfoRepo).addWindowLayoutInfoListener(any(), any(), wmConsumerCaptor.capture());
    Consumer<WindowLayoutInfo> wmConsumer = wmConsumerCaptor.getValue();
    wmConsumer.accept(testWindowLayout);

    // Then the Renderer receives the display feature
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(
        FlutterRenderer.DisplayFeatureType.HINGE,
        viewportMetricsCaptor.getValue().displayFeatures.get(0).type);
    assertEquals(
        FlutterRenderer.DisplayFeatureState.POSTURE_FLAT,
        viewportMetricsCaptor.getValue().displayFeatures.get(0).state);
    assertEquals(
        new Rect(0, 0, 100, 100), viewportMetricsCaptor.getValue().displayFeatures.get(0).bounds);
  }

  @Test
  public void flutterImageView_acquiresImageAndInvalidates() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(2);

    final FlutterImageView imageView =
        spy(
            new FlutterImageView(
                RuntimeEnvironment.application,
                mockReader,
                FlutterImageView.SurfaceKind.background));

    final FlutterJNI jni = mock(FlutterJNI.class);
    imageView.attachToRenderer(new FlutterRenderer(jni));

    final Image mockImage = mock(Image.class);
    when(mockReader.acquireLatestImage()).thenReturn(mockImage);

    assertTrue(imageView.acquireLatestImage());
    verify(mockReader, times(1)).acquireLatestImage();
    verify(imageView, times(1)).invalidate();
  }

  @Test
  @SuppressLint("WrongCall") /*View#onDraw*/
  public void flutterImageView_acquiresImageClosesPreviousImageUnlessNoNewImage() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(3);

    final Image mockImage = mock(Image.class);
    when(mockImage.getPlanes()).thenReturn(new Plane[0]);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      final HardwareBuffer mockHardwareBuffer = mock(HardwareBuffer.class);
      when(mockHardwareBuffer.getUsage()).thenReturn(HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE);
      when(mockImage.getHardwareBuffer()).thenReturn(mockHardwareBuffer);
    }
    // Mock no latest image on the second time
    when(mockReader.acquireLatestImage())
        .thenReturn(mockImage)
        .thenReturn(null)
        .thenReturn(mockImage);

    final FlutterImageView imageView =
        spy(
            new FlutterImageView(
                RuntimeEnvironment.application,
                mockReader,
                FlutterImageView.SurfaceKind.background));

    final FlutterJNI jni = mock(FlutterJNI.class);
    imageView.attachToRenderer(new FlutterRenderer(jni));
    doNothing().when(imageView).invalidate();

    assertTrue(imageView.acquireLatestImage()); // No previous, acquire latest image
    assertFalse(
        imageView.acquireLatestImage()); // Mock no image when acquire, don't close, and assertFalse
    assertTrue(imageView.acquireLatestImage()); // Acquire latest image and close previous
    assertTrue(imageView.acquireLatestImage()); // Acquire latest image and close previous
    assertTrue(imageView.acquireLatestImage()); // Acquire latest image and close previous
    verify(mockImage, times(3)).close(); // Close 3 times

    imageView.onDraw(mock(Canvas.class)); // Draw latest image

    assertTrue(imageView.acquireLatestImage()); // acquire latest image and close previous

    imageView.onDraw(mock(Canvas.class)); // Draw latest image
    imageView.onDraw(mock(Canvas.class)); // Draw latest image
    imageView.onDraw(mock(Canvas.class)); // Draw latest image

    verify(mockReader, times(6)).acquireLatestImage();
  }

  @Test
  public void flutterImageView_detachFromRendererClosesPreviousImage() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(2);

    final Image mockImage = mock(Image.class);
    when(mockReader.acquireLatestImage()).thenReturn(mockImage);

    final FlutterImageView imageView =
        spy(
            new FlutterImageView(
                RuntimeEnvironment.application,
                mockReader,
                FlutterImageView.SurfaceKind.background));

    final FlutterJNI jni = mock(FlutterJNI.class);
    imageView.attachToRenderer(new FlutterRenderer(jni));

    doNothing().when(imageView).invalidate();
    imageView.acquireLatestImage();
    imageView.acquireLatestImage();
    verify(mockImage, times(1)).close();

    imageView.detachFromRenderer();
    // There's an acquireLatestImage() in detachFromRenderer(),
    // so it will be 2 times called close() inside detachFromRenderer()
    verify(mockImage, times(3)).close();
  }

  @Test
  public void flutterImageView_workaroundWithOnePixelWhenResizeWithZero() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(2);

    final FlutterImageView imageView =
        spy(
            new FlutterImageView(
                RuntimeEnvironment.application,
                mockReader,
                FlutterImageView.SurfaceKind.background));

    final FlutterJNI jni = mock(FlutterJNI.class);
    imageView.attachToRenderer(new FlutterRenderer(jni));

    final Image mockImage = mock(Image.class);
    when(mockReader.acquireLatestImage()).thenReturn(mockImage);

    final int incorrectWidth = 0;
    final int incorrectHeight = -100;
    imageView.resizeIfNeeded(incorrectWidth, incorrectHeight);
    assertEquals(1, imageView.getImageReader().getWidth());
    assertEquals(1, imageView.getImageReader().getHeight());
  }

  @Test
  public void flutterImageView_closesReader() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(1);

    final FlutterImageView imageView =
        spy(
            new FlutterImageView(
                RuntimeEnvironment.application,
                mockReader,
                FlutterImageView.SurfaceKind.background));

    imageView.closeImageReader();
    verify(mockReader, times(1)).close();
  }

  @Test
  public void flutterSurfaceView_GathersTransparentRegion() {
    final Region mockRegion = mock(Region.class);
    final FlutterSurfaceView surfaceView = new FlutterSurfaceView(RuntimeEnvironment.application);

    surfaceView.setAlpha(0.0f);
    assertFalse(surfaceView.gatherTransparentRegion(mockRegion));
    verify(mockRegion, times(0)).op(anyInt(), anyInt(), anyInt(), anyInt(), any());

    surfaceView.setAlpha(1.0f);
    assertTrue(surfaceView.gatherTransparentRegion(mockRegion));
    verify(mockRegion, times(1)).op(0, 0, 0, 0, Region.Op.DIFFERENCE);
  }

  @Test
  @SuppressLint("PrivateApi")
  public void findViewByAccessibilityIdTraversal_returnsRootViewOnAndroid28() throws Exception {
    TestUtils.setApiVersion(28);

    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);

    Method getAccessibilityViewIdMethod = View.class.getDeclaredMethod("getAccessibilityViewId");
    Integer accessibilityViewId = (Integer) getAccessibilityViewIdMethod.invoke(flutterView);

    assertEquals(flutterView, flutterView.findViewByAccessibilityIdTraversal(accessibilityViewId));
  }

  @Test
  @SuppressLint("PrivateApi")
  public void findViewByAccessibilityIdTraversal_returnsChildViewOnAndroid28() throws Exception {
    TestUtils.setApiVersion(28);

    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
    FrameLayout childView1 = new FrameLayout(RuntimeEnvironment.application);
    flutterView.addView(childView1);

    FrameLayout childView2 = new FrameLayout(RuntimeEnvironment.application);
    childView1.addView(childView2);

    Method getAccessibilityViewIdMethod = View.class.getDeclaredMethod("getAccessibilityViewId");
    Integer accessibilityViewId = (Integer) getAccessibilityViewIdMethod.invoke(childView2);

    assertEquals(childView2, flutterView.findViewByAccessibilityIdTraversal(accessibilityViewId));
  }

  @Test
  @SuppressLint("PrivateApi")
  public void findViewByAccessibilityIdTraversal_returnsRootViewOnAndroid29() throws Exception {
    TestUtils.setApiVersion(29);

    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);

    Method getAccessibilityViewIdMethod = View.class.getDeclaredMethod("getAccessibilityViewId");
    Integer accessibilityViewId = (Integer) getAccessibilityViewIdMethod.invoke(flutterView);

    assertEquals(null, flutterView.findViewByAccessibilityIdTraversal(accessibilityViewId));
  }

  public void ViewportMetrics_initializedPhysicalTouchSlop() {
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    flutterView.attachToFlutterEngine(flutterEngine);
    ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor =
        ArgumentCaptor.forClass(FlutterRenderer.ViewportMetrics.class);
    verify(flutterRenderer).setViewportMetrics(viewportMetricsCaptor.capture());

    assertFalse(-1 == viewportMetricsCaptor.getValue().physicalTouchSlop);
  }

  private void setExpectedDisplayRotation(int rotation) {
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
    display.setRotation(rotation);
  }

  private void validateViewportMetricPadding(
      ArgumentCaptor<FlutterRenderer.ViewportMetrics> viewportMetricsCaptor,
      int left,
      int top,
      int right,
      int bottom) {
    assertEquals(left, viewportMetricsCaptor.getValue().viewPaddingLeft);
    assertEquals(top, viewportMetricsCaptor.getValue().viewPaddingTop);
    assertEquals(right, viewportMetricsCaptor.getValue().viewPaddingRight);
    assertEquals(bottom, viewportMetricsCaptor.getValue().viewPaddingBottom);
  }

  private void mockSystemWindowInsets(
      WindowInsets windowInsets, int left, int top, int right, int bottom) {
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(left);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(top);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(right);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(bottom);
  }

  private void mockSystemGestureInsetsIfNeed(WindowInsets windowInsets) {
    if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
      when(windowInsets.getSystemGestureInsets()).thenReturn(Insets.NONE);
    }
  }

  /*
   * A custom shadow that reports fullscreen flag for system UI visibility
   */
  @Implements(View.class)
  public static class ShadowFullscreenView {
    @Implementation
    public int getWindowSystemUiVisibility() {
      return View.SYSTEM_UI_FLAG_FULLSCREEN;
    }
  }

  // ViewGroup is the first shadow in the type hierarchy for FlutterView. Shadows need to mimic
  // production classes' view hierarchy.
  @Implements(ViewGroup.class)
  public static class ShadowFullscreenViewGroup extends ShadowFullscreenView {}
}

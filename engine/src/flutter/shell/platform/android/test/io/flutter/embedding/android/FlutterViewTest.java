package io.flutter.embedding.android;

import static junit.framework.TestCase.assertEquals;
import static junit.framework.TestCase.assertFalse;
import static junit.framework.TestCase.assertTrue;
import static org.mockito.Matchers.any;
import static org.mockito.Matchers.anyInt;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Insets;
import android.media.Image;
import android.media.Image.Plane;
import android.media.ImageReader;
import android.view.DisplayCutout;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.view.WindowManager;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.plugin.platform.PlatformViewsController;
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
    MockitoAnnotations.initMocks(this);
    when(mockFlutterJni.isAttached()).thenReturn(true);
  }

  @Test
  public void attachToFlutterEngine_alertsPlatformViews() {
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    when(flutterEngine.getPlatformViewsController()).thenReturn(platformViewsController);

    flutterView.attachToFlutterEngine(flutterEngine);

    verify(platformViewsController, times(1)).attachToView(flutterView);
  }

  @Test
  public void detachFromFlutterEngine_alertsPlatformViews() {
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    when(flutterEngine.getPlatformViewsController()).thenReturn(platformViewsController);

    flutterView.attachToFlutterEngine(flutterEngine);
    flutterView.detachFromFlutterEngine();

    verify(platformViewsController, times(1)).detachFromView();
  }

  @Test
  public void detachFromFlutterEngine_turnsOffA11y() {
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
    FlutterEngine flutterEngine =
        spy(new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni));
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(mockFlutterJni));
    when(flutterEngine.getRenderer()).thenReturn(flutterRenderer);

    flutterView.attachToFlutterEngine(flutterEngine);
    flutterView.detachFromFlutterEngine();

    verify(flutterRenderer, times(1)).setSemanticsEnabled(false);
  }

  @Test
  public void onConfigurationChanged_fizzlesWhenNullEngine() {
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
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
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
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

    Context spiedContext = spy(RuntimeEnvironment.application);

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
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(100);
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);
    // Padding bottom is always 0.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingBottom);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingRight);
  }

  // This test uses the pre-API 30 Algorithm for window insets.
  @Test
  @TargetApi(29)
  @Config(
      sdk = 29,
      shadows = {
        FlutterViewTest.ShadowFullscreenView.class,
        FlutterViewTest.ShadowFullscreenViewGroup.class
      })
  public void setPaddingTopToZeroForFullscreenModeLegacy() {
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(100);
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingBottom);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingRight);
  }

  // This test uses the API 30+ Algorithm for window insets. The legacy algorithm is
  // set to -1 values, so it is clear if the wrong algorithm is used.
  @Test
  @TargetApi(30)
  @Config(sdk = 30)
  public void reportSystemInsetWhenNotFullscreen() {
    // Without custom shadows, the default system ui visibility flags is 0.
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(100);
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is reported as-is.
    assertEquals(100, viewportMetricsCaptor.getValue().paddingTop);
    // Padding bottom is always 0.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingBottom);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingRight);
  }

  // This test uses the pre-API 30 Algorithm for window insets.
  @Test
  @TargetApi(29)
  @Config(sdk = 29)
  public void reportSystemInsetWhenNotFullscreenLegacy() {
    // Without custom shadows, the default system ui visibility flags is 0.
    FlutterView flutterView = new FlutterView(RuntimeEnvironment.application);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(100);
    flutterView.onApplyWindowInsets(windowInsets);

    // Verify.
    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is reported as-is.
    assertEquals(100, viewportMetricsCaptor.getValue().paddingTop);
    assertEquals(0, viewportMetricsCaptor.getValue().paddingBottom);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingRight);
  }

  @Test
  public void systemInsetHandlesFullscreenNavbarRight() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
    display.setRotation(1);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(100);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is removed due to full screen.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);
    // Bottom padding is removed due to hide navigation.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingBottom);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingLeft);
    // Right padding is zero because the rotation is 90deg
    assertEquals(0, viewportMetricsCaptor.getValue().paddingRight);
  }

  @Test
  public void systemInsetHandlesFullscreenNavbarLeft() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
    display.setRotation(3);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(100);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is removed due to full screen.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);
    // Bottom padding is removed due to hide navigation.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingBottom);
    // Left padding is zero because the rotation is 270deg
    assertEquals(0, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingRight);
  }

  // This test uses the API 30+ Algorithm for window insets. The legacy algorithm is
  // set to -1 values, so it is clear if the wrong algorithm is used.
  @Test
  @TargetApi(30)
  @Config(sdk = 30)
  public void systemInsetGetInsetsFullscreen() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
    display.setRotation(3);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    Insets insets = Insets.of(100, 100, 100, 100);
    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(-1);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(-1);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(-1);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(-1);
    when(windowInsets.getInsets(anyInt())).thenReturn(insets);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is removed due to full screen.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);
    // Padding bottom is always 0.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingBottom);
    // Left padding is zero because the rotation is 270deg
    assertEquals(0, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(100, viewportMetricsCaptor.getValue().paddingRight);
  }

  // This test uses the pre-API 30 Algorithm for window insets.
  @Test
  @TargetApi(29)
  @Config(sdk = 29)
  public void systemInsetGetInsetsFullscreenLegacy() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
    display.setRotation(3);
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(100);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(101);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(102);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(103);

    flutterView.onApplyWindowInsets(windowInsets);

    verify(flutterRenderer, times(2)).setViewportMetrics(viewportMetricsCaptor.capture());
    // Top padding is removed due to full screen.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);
    // Bottom padding is removed due to hide navigation.
    assertEquals(0, viewportMetricsCaptor.getValue().paddingBottom);
    // Left padding is zero because the rotation is 270deg
    assertEquals(0, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(103, viewportMetricsCaptor.getValue().paddingRight);
  }

  // This test uses the API 30+ Algorithm for window insets. The legacy algorithm is
  // set to -1 values, so it is clear if the wrong algorithm is used.
  @Test
  @TargetApi(30)
  @Config(sdk = 30)
  public void systemInsetDisplayCutoutSimple() {
    RuntimeEnvironment.setQualifiers("+land");
    FlutterView flutterView = spy(new FlutterView(RuntimeEnvironment.systemContext));
    ShadowDisplay display =
        Shadows.shadowOf(
            ((WindowManager)
                    RuntimeEnvironment.systemContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay());
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
    assertEquals(0, viewportMetricsCaptor.getValue().paddingTop);

    Insets insets = Insets.of(100, 100, 100, 100);
    Insets systemGestureInsets = Insets.of(110, 110, 110, 110);
    // Then we simulate the system applying a window inset.
    WindowInsets windowInsets = mock(WindowInsets.class);
    DisplayCutout displayCutout = mock(DisplayCutout.class);
    when(windowInsets.getSystemWindowInsetTop()).thenReturn(-1);
    when(windowInsets.getSystemWindowInsetBottom()).thenReturn(-1);
    when(windowInsets.getSystemWindowInsetLeft()).thenReturn(-1);
    when(windowInsets.getSystemWindowInsetRight()).thenReturn(-1);
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
    assertEquals(150, viewportMetricsCaptor.getValue().paddingTop);
    assertEquals(150, viewportMetricsCaptor.getValue().paddingBottom);
    assertEquals(200, viewportMetricsCaptor.getValue().paddingLeft);
    assertEquals(200, viewportMetricsCaptor.getValue().paddingRight);

    assertEquals(100, viewportMetricsCaptor.getValue().viewInsetTop);
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
  public void flutterImageView_acquireLatestImageReturnsFalse() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(2);

    final FlutterImageView imageView =
        spy(
            new FlutterImageView(
                RuntimeEnvironment.application,
                mockReader,
                FlutterImageView.SurfaceKind.background));

    assertFalse(imageView.acquireLatestImage());

    final FlutterJNI jni = mock(FlutterJNI.class);
    imageView.attachToRenderer(new FlutterRenderer(jni));

    when(mockReader.acquireLatestImage()).thenReturn(null);
    assertFalse(imageView.acquireLatestImage());
  }

  @Test
  @SuppressLint("WrongCall") /*View#onDraw*/
  public void flutterImageView_acquiresMaxImagesAtMost() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(3);

    final Image mockImage = mock(Image.class);
    when(mockImage.getPlanes()).thenReturn(new Plane[0]);
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

    assertTrue(imageView.acquireLatestImage()); // 1 image
    assertTrue(imageView.acquireLatestImage()); // 2 images
    assertTrue(imageView.acquireLatestImage()); // 3 images
    assertTrue(imageView.acquireLatestImage()); // 3 images
    verify(mockReader, times(3)).acquireLatestImage();

    imageView.onDraw(mock(Canvas.class)); // 3 images
    assertTrue(imageView.acquireLatestImage()); // 3 images
    verify(mockReader, times(3)).acquireLatestImage();

    imageView.onDraw(mock(Canvas.class)); // 2 images
    assertTrue(imageView.acquireLatestImage()); // 3 images
    verify(mockReader, times(4)).acquireLatestImage();

    imageView.onDraw(mock(Canvas.class)); // 2 images
    imageView.onDraw(mock(Canvas.class)); // 1 image
    imageView.onDraw(mock(Canvas.class)); // 1 image

    assertTrue(imageView.acquireLatestImage()); // 2 images
    assertTrue(imageView.acquireLatestImage()); // 3 images
    assertTrue(imageView.acquireLatestImage()); // 3 images
    assertTrue(imageView.acquireLatestImage()); // 3 images
    verify(mockReader, times(6)).acquireLatestImage();
  }

  @Test
  public void flutterImageView_detachFromRendererClosesAllImages() {
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
    imageView.detachFromRenderer();

    verify(mockImage, times(2)).close();
  }

  @Test
  @SuppressLint("WrongCall") /*View#onDraw*/
  public void flutterImageView_onDrawClosesAllImages() {
    final ImageReader mockReader = mock(ImageReader.class);
    when(mockReader.getMaxImages()).thenReturn(2);

    final Image mockImage = mock(Image.class);
    when(mockImage.getPlanes()).thenReturn(new Plane[0]);
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

    imageView.onDraw(mock(Canvas.class));
    imageView.onDraw(mock(Canvas.class));

    // 1 image is closed and 1 is active.
    verify(mockImage, times(1)).close();
    verify(mockReader, times(2)).acquireLatestImage();

    // This call doesn't do anything because there isn't
    // an image in the queue.
    imageView.onDraw(mock(Canvas.class));
    verify(mockImage, times(1)).close();

    // Aquire another image and push it to the queue.
    imageView.acquireLatestImage();
    verify(mockReader, times(3)).acquireLatestImage();

    // Then, the second image is closed.
    imageView.onDraw(mock(Canvas.class));
    verify(mockImage, times(2)).close();
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

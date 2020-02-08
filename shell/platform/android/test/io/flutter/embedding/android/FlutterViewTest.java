package io.flutter.embedding.android;

import static junit.framework.TestCase.assertEquals;
import static org.mockito.Matchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
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
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
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
    // 2 invocations of channels.
    flutterView.onConfigurationChanged(configuration);
    flutterView.detachFromFlutterEngine();

    // Should fizzle.
    flutterView.onConfigurationChanged(configuration);

    verify(flutterEngine, times(2)).getLocalizationChannel();
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
}

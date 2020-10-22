package test.io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyInt;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.pm.PackageManager.NameNotFoundException;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.plugins.GeneratedPluginRegistrant;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterEngineTest {
  @Mock FlutterJNI flutterJNI;

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
    when(flutterJNI.isAttached()).thenReturn(true);
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @After
  public void tearDown() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @Test
  public void itAutomaticallyRegistersPluginsByDefault() {
    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
    FlutterEngine flutterEngine =
        new FlutterEngine(RuntimeEnvironment.application, mock(FlutterLoader.class), flutterJNI);

    List<FlutterEngine> registeredEngines = GeneratedPluginRegistrant.getRegisteredEngines();
    assertEquals(1, registeredEngines.size());
    assertEquals(flutterEngine, registeredEngines.get(0));
  }

  @Test
  public void itCanBeConfiguredToNotAutomaticallyRegisterPlugins() {
    new FlutterEngine(
        RuntimeEnvironment.application,
        mock(FlutterLoader.class),
        flutterJNI,
        /*dartVmArgs=*/ new String[] {},
        /*automaticallyRegisterPlugins=*/ false);

    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
  }

  @Test
  public void itNotifiesPlatformViewsControllerWhenDevHotRestart() {
    // Setup test.
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    when(mockFlutterJNI.isAttached()).thenReturn(true);

    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);

    ArgumentCaptor<FlutterEngine.EngineLifecycleListener> engineLifecycleListenerArgumentCaptor =
        ArgumentCaptor.forClass(FlutterEngine.EngineLifecycleListener.class);

    // Execute behavior under test.
    new FlutterEngine(
        RuntimeEnvironment.application,
        mock(FlutterLoader.class),
        mockFlutterJNI,
        platformViewsController,
        /*dartVmArgs=*/ new String[] {},
        /*automaticallyRegisterPlugins=*/ false);

    // Obtain the EngineLifecycleListener within FlutterEngine that was given to FlutterJNI.
    verify(mockFlutterJNI)
        .addEngineLifecycleListener(engineLifecycleListenerArgumentCaptor.capture());
    FlutterEngine.EngineLifecycleListener engineLifecycleListener =
        engineLifecycleListenerArgumentCaptor.getValue();
    assertNotNull(engineLifecycleListener);

    // Simulate a pre-engine restart, AKA hot restart.
    engineLifecycleListener.onPreEngineRestart();

    // Verify that FlutterEngine notified PlatformViewsController of the pre-engine restart,
    // AKA hot restart.
    verify(platformViewsController, times(1)).onPreEngineRestart();
  }

  @Test
  public void itNotifiesPlatformViewsControllerAboutJNILifecycle() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    when(mockFlutterJNI.isAttached()).thenReturn(true);

    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);

    // Execute behavior under test.
    FlutterEngine engine =
        new FlutterEngine(
            RuntimeEnvironment.application,
            mock(FlutterLoader.class),
            mockFlutterJNI,
            platformViewsController,
            /*dartVmArgs=*/ new String[] {},
            /*automaticallyRegisterPlugins=*/ false);
    verify(platformViewsController, times(1)).onAttachedToJNI();

    engine.destroy();
    verify(platformViewsController, times(1)).onDetachedFromJNI();
  }

  @Test
  public void itUsesApplicationContext() throws NameNotFoundException {
    Context context = mock(Context.class);
    Context packageContext = mock(Context.class);

    when(context.createPackageContext(any(), anyInt())).thenReturn(packageContext);

    new FlutterEngine(
        context,
        mock(FlutterLoader.class),
        flutterJNI,
        /*dartVmArgs=*/ new String[] {},
        /*automaticallyRegisterPlugins=*/ false);

    verify(context, atLeast(1)).getApplicationContext();
  }

  @Test
  public void itUsesPackageContextForAssetManager() throws NameNotFoundException {
    Context context = mock(Context.class);
    Context packageContext = mock(Context.class);
    when(context.createPackageContext(any(), anyInt())).thenReturn(packageContext);

    new FlutterEngine(
        context,
        mock(FlutterLoader.class),
        flutterJNI,
        /*dartVmArgs=*/ new String[] {},
        /*automaticallyRegisterPlugins=*/ false);

    verify(packageContext, atLeast(1)).getAssets();
    verify(context, times(0)).getAssets();
  }

  @Test
  public void itCanUseFlutterLoaderInjectionViaFlutterInjector() throws NameNotFoundException {
    FlutterInjector.reset();
    FlutterLoader mockFlutterLoader = mock(FlutterLoader.class);
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterLoader(mockFlutterLoader).build());
    Context mockContext = mock(Context.class);
    Context packageContext = mock(Context.class);

    when(mockContext.createPackageContext(any(), anyInt())).thenReturn(packageContext);

    new FlutterEngine(mockContext, null, flutterJNI);

    verify(mockFlutterLoader, times(1)).startInitialization(any());
    verify(mockFlutterLoader, times(1)).ensureInitializationComplete(any(), any());
  }
}

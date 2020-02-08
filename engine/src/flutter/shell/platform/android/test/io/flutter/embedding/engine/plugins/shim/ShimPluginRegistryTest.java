package io.flutter.embedding.engine.plugins.shim;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.Context;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.embedding.engine.plugins.PluginRegistry;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class ShimPluginRegistryTest {

  @Mock private FlutterEngine mockFlutterEngine;
  @Mock private FlutterPluginBinding mockFlutterPluginBinding;
  @Mock private ActivityPluginBinding mockActivityPluginBinding;
  @Mock private PluginRegistry mockPluginRegistry;
  @Mock private Context mockApplicationContext;
  @Mock private Activity mockActivity;

  @Before
  public void setup() {
    MockitoAnnotations.initMocks(this);
    when(mockFlutterEngine.getPlugins()).thenReturn(mockPluginRegistry);
    when(mockFlutterPluginBinding.getApplicationContext()).thenReturn(mockApplicationContext);
    when(mockActivityPluginBinding.getActivity()).thenReturn(mockActivity);
  }

  @Test
  public void itSuppliesOldAPIsViaTheNewFlutterPluginBinding() {
    ShimPluginRegistry registryUnderTest = new ShimPluginRegistry(mockFlutterEngine);
    // This is the consumption side of the old plugins.
    Registrar registrarUnderTest = registryUnderTest.registrarFor("test");

    ArgumentCaptor<FlutterPlugin> shimAggregateCaptor =
        ArgumentCaptor.forClass(FlutterPlugin.class);
    // A single shim aggregate was added as a new plugin to the FlutterEngine's PluginRegistry.
    verify(mockPluginRegistry).add(shimAggregateCaptor.capture());
    // This is really a ShimRegistrarAggregate acting as a FlutterPlugin which is the
    // intermediate consumption side of the new plugin inside the shim.
    FlutterPlugin shimAggregateUnderTest = shimAggregateCaptor.getValue();
    // The FlutterPluginBinding is the supply side of the new plugin.
    shimAggregateUnderTest.onAttachedToEngine(mockFlutterPluginBinding);

    // Consume something from the old plugin API.
    assertEquals(mockApplicationContext, registrarUnderTest.context());
    // Check that the value comes from the supply side of the new plugin.
    verify(mockFlutterPluginBinding).getApplicationContext();
  }

  @Test
  public void itSuppliesMultipleOldPlugins() {
    ShimPluginRegistry registryUnderTest = new ShimPluginRegistry(mockFlutterEngine);
    Registrar registrarUnderTest1 = registryUnderTest.registrarFor("test1");
    Registrar registrarUnderTest2 = registryUnderTest.registrarFor("test2");

    ArgumentCaptor<FlutterPlugin> shimAggregateCaptor =
        ArgumentCaptor.forClass(FlutterPlugin.class);
    verify(mockPluginRegistry).add(shimAggregateCaptor.capture());
    // There's only one aggregate for many old plugins.
    FlutterPlugin shimAggregateUnderTest = shimAggregateCaptor.getValue();

    // The FlutterPluginBinding is the supply side of the new plugin.
    shimAggregateUnderTest.onAttachedToEngine(mockFlutterPluginBinding);

    // Since the 2 old plugins are supplied by the same intermediate FlutterPlugin, they should
    // get the same value.
    assertEquals(registrarUnderTest1.context(), registrarUnderTest2.context());
    verify(mockFlutterPluginBinding, times(2)).getApplicationContext();
  }

  @Test
  public void itCanOnlySupplyActivityBindingWhenUpstreamActivityIsAttached() {
    ShimPluginRegistry registryUnderTest = new ShimPluginRegistry(mockFlutterEngine);
    Registrar registrarUnderTest = registryUnderTest.registrarFor("test");

    ArgumentCaptor<FlutterPlugin> shimAggregateCaptor =
        ArgumentCaptor.forClass(FlutterPlugin.class);
    verify(mockPluginRegistry).add(shimAggregateCaptor.capture());
    FlutterPlugin shimAggregateAsPlugin = shimAggregateCaptor.getValue();
    ActivityAware shimAggregateAsActivityAware = (ActivityAware) shimAggregateCaptor.getValue();

    // Nothing is retrievable when nothing is attached.
    assertNull(registrarUnderTest.context());
    assertNull(registrarUnderTest.activity());

    shimAggregateAsPlugin.onAttachedToEngine(mockFlutterPluginBinding);

    assertEquals(mockApplicationContext, registrarUnderTest.context());
    assertNull(registrarUnderTest.activity());

    shimAggregateAsActivityAware.onAttachedToActivity(mockActivityPluginBinding);

    // Now context is the activity context.
    assertEquals(mockActivity, registrarUnderTest.activeContext());
    assertEquals(mockActivity, registrarUnderTest.activity());

    shimAggregateAsActivityAware.onDetachedFromActivityForConfigChanges();

    assertEquals(mockApplicationContext, registrarUnderTest.activeContext());
    assertNull(registrarUnderTest.activity());

    shimAggregateAsActivityAware.onReattachedToActivityForConfigChanges(mockActivityPluginBinding);
    assertEquals(mockActivity, registrarUnderTest.activeContext());
    assertEquals(mockActivity, registrarUnderTest.activity());

    shimAggregateAsActivityAware.onDetachedFromActivity();

    assertEquals(mockApplicationContext, registrarUnderTest.activeContext());
    assertNull(registrarUnderTest.activity());

    // Attach an activity again.
    shimAggregateAsActivityAware.onAttachedToActivity(mockActivityPluginBinding);

    assertEquals(mockActivity, registrarUnderTest.activeContext());
    assertEquals(mockActivity, registrarUnderTest.activity());

    // Now rip out the whole engine.
    shimAggregateAsPlugin.onDetachedFromEngine(mockFlutterPluginBinding);

    // And everything should have been made unavailable.
    assertNull(registrarUnderTest.activeContext());
    assertNull(registrarUnderTest.activity());
  }
}

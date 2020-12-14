package io.flutter.embedding.engine.systemchannels;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.content.res.AssetManager;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dynamicfeatures.DynamicFeatureManager;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

class TestDynamicFeatureManager implements DynamicFeatureManager {
  DynamicFeatureChannel channel;
  String moduleName;

  public void setJNI(FlutterJNI flutterJNI) {}

  public void setDynamicFeatureChannel(DynamicFeatureChannel channel) {
    this.channel = channel;
  }

  public void installDynamicFeature(int loadingUnitId, String moduleName) {
    this.moduleName = moduleName;
  }

  public void completeInstall() {
    channel.completeInstallSuccess(moduleName);
  }

  public String getDynamicFeatureInstallState(int loadingUnitId, String moduleName) {
    return "installed";
  }

  public void loadAssets(int loadingUnitId, String moduleName) {}

  public void loadDartLibrary(int loadingUnitId, String moduleName) {}

  public void uninstallFeature(int loadingUnitId, String moduleName) {}

  public void destroy() {}
}

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class DynamicFeatureChannelTest {
  @Test
  public void dynamicFeatureChannel_installCompletesResults() {
    MethodChannel rawChannel = mock(MethodChannel.class);
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    TestDynamicFeatureManager testDynamicFeatureManager = new TestDynamicFeatureManager();
    DynamicFeatureChannel fakeDynamicFeatureChannel = new DynamicFeatureChannel(dartExecutor);
    fakeDynamicFeatureChannel.setDynamicFeatureManager(testDynamicFeatureManager);

    Map<String, Object> args = new HashMap<>();
    args.put("loadingUnitId", -1);
    args.put("moduleName", "hello");
    MethodCall methodCall = new MethodCall("installDynamicFeature", args);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakeDynamicFeatureChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);

    testDynamicFeatureManager.completeInstall();
    verify(mockResult).success(null);
  }

  @Test
  public void dynamicFeatureChannel_installCompletesMultipleResults() {
    MethodChannel rawChannel = mock(MethodChannel.class);
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    TestDynamicFeatureManager testDynamicFeatureManager = new TestDynamicFeatureManager();
    DynamicFeatureChannel fakeDynamicFeatureChannel = new DynamicFeatureChannel(dartExecutor);
    fakeDynamicFeatureChannel.setDynamicFeatureManager(testDynamicFeatureManager);

    Map<String, Object> args = new HashMap<>();
    args.put("loadingUnitId", -1);
    args.put("moduleName", "hello");
    MethodCall methodCall = new MethodCall("installDynamicFeature", args);
    MethodChannel.Result mockResult1 = mock(MethodChannel.Result.class);
    MethodChannel.Result mockResult2 = mock(MethodChannel.Result.class);
    fakeDynamicFeatureChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult1);
    fakeDynamicFeatureChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult2);

    testDynamicFeatureManager.completeInstall();
    verify(mockResult1).success(null);
    verify(mockResult2).success(null);
  }

  @Test
  public void dynamicFeatureChannel_getInstallState() {
    MethodChannel rawChannel = mock(MethodChannel.class);
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    TestDynamicFeatureManager testDynamicFeatureManager = new TestDynamicFeatureManager();
    DynamicFeatureChannel fakeDynamicFeatureChannel = new DynamicFeatureChannel(dartExecutor);
    fakeDynamicFeatureChannel.setDynamicFeatureManager(testDynamicFeatureManager);

    Map<String, Object> args = new HashMap<>();
    args.put("loadingUnitId", -1);
    args.put("moduleName", "hello");
    MethodCall methodCall = new MethodCall("getDynamicFeatureInstallState", args);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakeDynamicFeatureChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);

    testDynamicFeatureManager.completeInstall();
    verify(mockResult).success("installed");
  }
}

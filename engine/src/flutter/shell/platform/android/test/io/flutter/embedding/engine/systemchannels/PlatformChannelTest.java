package io.flutter.embedding.engine.systemchannels;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.AssetManager;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Matchers;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class PlatformChannelTest {
  @Test
  public void platformChannel_hasStringsMessage() {
    MethodChannel rawChannel = mock(MethodChannel.class);
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);
    PlatformChannel.PlatformMessageHandler mockMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(mockMessageHandler);
    Boolean returnValue = true;
    when(mockMessageHandler.clipboardHasStrings()).thenReturn(returnValue);
    MethodCall methodCall = new MethodCall("Clipboard.hasStrings", null);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(methodCall, mockResult);

    JSONObject expected = new JSONObject();
    try {
      expected.put("value", returnValue);
    } catch (JSONException e) {
    }
    verify(mockResult).success(Matchers.refEq(expected));
  }
}

package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyZeroInteractions;

import android.annotation.TargetApi;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;
import org.json.JSONException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(
    manifest = Config.NONE,
    shadows = {})
@RunWith(RobolectricTestRunner.class)
@TargetApi(24)
public class RestorationChannelTest {
  @Test
  public void itDoesNotDoAnythingWhenRestorationDataIsSetBeforeFrameworkAsks()
      throws JSONException {
    MethodChannel rawChannel = mock(MethodChannel.class);
    RestorationChannel restorationChannel =
        new RestorationChannel(rawChannel, /*waitForRestorationData=*/ false);
    restorationChannel.setRestorationData("Any String you want".getBytes());
    verify(rawChannel, times(0)).invokeMethod(any(), any());
  }

  @Test
  public void itSendsDataOverWhenRequestIsPending() throws JSONException {
    byte[] data = "Any String you want".getBytes();

    MethodChannel rawChannel = mock(MethodChannel.class);
    RestorationChannel restorationChannel =
        new RestorationChannel(rawChannel, /*waitForRestorationData=*/ true);
    ArgumentCaptor<MethodChannel.MethodCallHandler> argumentCaptor =
        ArgumentCaptor.forClass(MethodChannel.MethodCallHandler.class);
    verify(rawChannel).setMethodCallHandler(argumentCaptor.capture());

    MethodChannel.Result result = mock(MethodChannel.Result.class);
    argumentCaptor.getValue().onMethodCall(new MethodCall("get", null), result);
    verifyZeroInteractions(result);

    restorationChannel.setRestorationData(data);
    verify(rawChannel, times(0)).invokeMethod(any(), any());
    Map<String, Object> expected = new HashMap<>();
    expected.put("enabled", true);
    expected.put("data", data);
    verify(result).success(expected);

    // Next get request is answered right away.
    MethodChannel.Result result2 = mock(MethodChannel.Result.class);
    argumentCaptor.getValue().onMethodCall(new MethodCall("get", null), result2);
    verify(result2).success(expected);
  }

  @Test
  public void itPushesNewData() throws JSONException {
    byte[] data = "Any String you want".getBytes();

    MethodChannel rawChannel = mock(MethodChannel.class);
    RestorationChannel restorationChannel =
        new RestorationChannel(rawChannel, /*waitForRestorationData=*/ false);
    ArgumentCaptor<MethodChannel.MethodCallHandler> argumentCaptor =
        ArgumentCaptor.forClass(MethodChannel.MethodCallHandler.class);
    verify(rawChannel).setMethodCallHandler(argumentCaptor.capture());

    MethodChannel.Result result = mock(MethodChannel.Result.class);
    argumentCaptor.getValue().onMethodCall(new MethodCall("get", null), result);
    Map<String, Object> expected = new HashMap<>();
    expected.put("enabled", true);
    expected.put("data", null);
    verify(result).success(expected);

    restorationChannel.setRestorationData(data);
    assertEquals(restorationChannel.getRestorationData(), null);

    ArgumentCaptor<MethodChannel.Result> resultCapture =
        ArgumentCaptor.forClass(MethodChannel.Result.class);
    Map<String, Object> expected2 = new HashMap<>();
    expected2.put("enabled", true);
    expected2.put("data", data);
    verify(rawChannel).invokeMethod(eq("push"), eq(expected2), resultCapture.capture());
    resultCapture.getValue().success(null);
    assertEquals(restorationChannel.getRestorationData(), data);
  }

  @Test
  public void itHoldsOnToDataFromFramework() throws JSONException {
    byte[] data = "Any String you want".getBytes();

    MethodChannel rawChannel = mock(MethodChannel.class);
    RestorationChannel restorationChannel =
        new RestorationChannel(rawChannel, /*waitForRestorationData=*/ false);
    ArgumentCaptor<MethodChannel.MethodCallHandler> argumentCaptor =
        ArgumentCaptor.forClass(MethodChannel.MethodCallHandler.class);
    verify(rawChannel).setMethodCallHandler(argumentCaptor.capture());

    MethodChannel.Result result = mock(MethodChannel.Result.class);
    argumentCaptor.getValue().onMethodCall(new MethodCall("put", data), result);
    assertEquals(restorationChannel.getRestorationData(), data);
  }
}

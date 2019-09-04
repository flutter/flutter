package io.flutter.embedding.engine.systemchannels;

import android.graphics.Rect;

import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.PlatformMessageHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class PlatformChannelTest {
    @Test
    public void setSystemExclusionRectsSendsSuccessMessageToFramework() throws JSONException {
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);

        int top = 0;
        int right = 500;
        int bottom = 250;
        int left = 0;

        ResultsMock resultsMock = mock(ResultsMock.class);
        JSONObject JsonRect = new JSONObject();
        JsonRect.put("top", top);
        JsonRect.put("right", right);
        JsonRect.put("bottom", bottom);
        JsonRect.put("left", left);
        JSONArray inputRects = new JSONArray();
        inputRects.put(JsonRect);

        ArrayList<Rect> expectedDecodedRects = new ArrayList<Rect>();
        Rect gestureRect = new Rect(left, top, right, bottom);
        expectedDecodedRects.add(gestureRect);

        MethodCall callSetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.setSystemGestureExclusionRects",
            inputRects
        );

        platformChannel.parsingMethodCallHandler.onMethodCall(callSetSystemGestureExclusionRects, resultsMock);
        verify(platformMessageHandler, times(1)).setSystemGestureExclusionRects(expectedDecodedRects);
        verify(resultsMock, times(1)).success(null);
    }

    @Test
    public void setSystemExclusionRectsRequiresJSONArrayInput() {
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);

        ResultsMock resultsMock = mock(ResultsMock.class);
        String nonJsonInput = "Non-JSON";
        MethodCall callSetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.setSystemGestureExclusionRects",
            nonJsonInput
        );
        platformChannel.parsingMethodCallHandler.onMethodCall(callSetSystemGestureExclusionRects, resultsMock);

        String inputTypeError = "Input type is incorrect. Ensure that a List<Map<String, int>> is passed as the input for SystemGestureExclusionRects.setSystemGestureExclusionRects.";
        verify(resultsMock, times(1)).error(
            "inputTypeError",
            inputTypeError,
            null
        );
    }

    @Test
    public void setSystemExclusionRectsSendsJSONExceptionOnIncorrectDataShape() throws JSONException {
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);

        int top = 0;
        int right = 500;

        ResultsMock resultsMock = mock(ResultsMock.class);
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("arg1", top);
        jsonObject.put("arg2", right);
        JSONArray inputArray = new JSONArray();
        inputArray.put(jsonObject);

        MethodCall callSetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.setSystemGestureExclusionRects",
            inputArray
        );
        platformChannel.parsingMethodCallHandler.onMethodCall(callSetSystemGestureExclusionRects, resultsMock);
        verify(resultsMock, times(1)).error(
            "error",
            "JSON error: Incorrect JSON data shape. To set system gesture exclusion rects, \n" +
            "a JSONObject with top, right, bottom and left values need to be set to int values.",
            null
        );
    }

    @Test
    public void itSendsSuccessMessageToFrameworkWhenGettingSystemGestureExclusionRects() throws JSONException {
        // --- Test Setup ---
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);
        Result result = mock(Result.class);

        // Fake API output setup
        ArrayList<Rect> fakeExclusionRects = new ArrayList<Rect>();
        Rect gestureRect = new Rect(0, 0, 500, 250);
        fakeExclusionRects.add(gestureRect);
        when(platformMessageHandler.getSystemGestureExclusionRects()).thenReturn(fakeExclusionRects);

        // Parsed API output that should be passed to result.success()
        ArrayList<HashMap<String, Integer>> expectedEncodedOutputRects = new ArrayList<HashMap<String, Integer>>();
        HashMap<String, Integer> rectMap = new HashMap<String, Integer>();
        rectMap.put("top", 0);
        rectMap.put("right", 500);
        rectMap.put("bottom", 250);
        rectMap.put("left", 0);
        expectedEncodedOutputRects.add(rectMap);
        MethodCall callGetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.getSystemGestureExclusionRects",
            null
        );

        // --- Execute Test ---
        platformChannel.parsingMethodCallHandler.onMethodCall(callGetSystemGestureExclusionRects, result);

        // --- Verify Results ---
        verify(result, times(1)).success(expectedEncodedOutputRects);
    }

    @Test
    public void itSendsAPILevelErrorWhenAndroidVersionIsTooLowWhenGettingSystemGestureExclusionRects() {
        // --- Test Setup ---
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);
        when(platformMessageHandler.getSystemGestureExclusionRects()).thenReturn(null);
        Result result = mock(Result.class);

        MethodCall callGetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.getSystemGestureExclusionRects",
            null
        );

        // --- Execute Test ---
        platformChannel.parsingMethodCallHandler.onMethodCall(callGetSystemGestureExclusionRects, result);

        // --- Verify Results ---
        verify(result, times(1)).error(
            "error",
            "Exclusion rects only exist for Android API 29+.",
            null
        );
    }

    private class ResultsMock implements Result {
        @Override
        public void success(Object result) {}

        @Override
        public void error(String errorCode, String errorMessage, Object errorDetails) {}

        @Override
        public void notImplemented() {}
    }
}

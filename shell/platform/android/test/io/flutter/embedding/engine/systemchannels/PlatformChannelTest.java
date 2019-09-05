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

    @Test
    public void itSendsSuccessMessageToFrameworkWhenSettingSystemGestureExclusionRects() throws JSONException {
        // --- Test Setup ---
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);
        Result result = mock(Result.class);

        JSONObject jsonRect = new JSONObject();
        jsonRect.put("top", 0);
        jsonRect.put("right", 500);
        jsonRect.put("bottom", 250);
        jsonRect.put("left", 0);
        JSONArray jsonExclusionRectsFromPlatform = new JSONArray();
        jsonExclusionRectsFromPlatform.put(jsonRect);

        MethodCall callSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.setSystemGestureExclusionRects",
            jsonExclusionRectsFromPlatform
        );

        // --- Execute Test ---
        platformChannel.parsingMethodCallHandler.onMethodCall(callSystemGestureExclusionRects, result);

        // --- Verify Results ---
        verify(result, times(1)).success(null);
    }

    @Test
    public void itProperlyDecodesGestureRectsWhenSettingSystemGestureExclusionRects() throws JSONException {
        // --- Test Setup ---
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);
        Result result = mock(Result.class);

        JSONObject jsonRect = new JSONObject();
        jsonRect.put("top", 0);
        jsonRect.put("right", 500);
        jsonRect.put("bottom", 250);
        jsonRect.put("left", 0);
        JSONArray jsonExclusionRectsFromPlatform = new JSONArray();
        jsonExclusionRectsFromPlatform.put(jsonRect);

        ArrayList<Rect> expectedDecodedRects = new ArrayList<Rect>();
        Rect gestureRect = new Rect(0, 0, 500, 250);
        expectedDecodedRects.add(gestureRect);

        MethodCall callSetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.setSystemGestureExclusionRects",
            jsonExclusionRectsFromPlatform
        );

        // --- Execute Test ---
        platformChannel.parsingMethodCallHandler.onMethodCall(callSetSystemGestureExclusionRects, result);

        // --- Verify Results ---
        verify(platformMessageHandler, times(1)).setSystemGestureExclusionRects(expectedDecodedRects);
    }

    @Test
    public void itSendsJSONInputErrorWhenNonJSONInputIsUsedWhenSettingSystemGestureExclusionRects() {
        // --- Test Setup ---
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);
        Result result = mock(Result.class);

    String nonJsonInput = "Non-JSON";
        MethodCall callSetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.setSystemGestureExclusionRects",
            nonJsonInput
        );

        // --- Execute Test ---
        platformChannel.parsingMethodCallHandler.onMethodCall(callSetSystemGestureExclusionRects, result);

        // --- Verify Results ---
        String inputTypeError = "Input type is incorrect. Ensure that a List<Map<String, int>> is passed as the input for SystemGestureExclusionRects.setSystemGestureExclusionRects.";
        verify(result, times(1)).error(
            "inputTypeError",
            inputTypeError,
            null
        );
    }

    @Test
    public void itSendsJSONErrorWhenIncorrectJSONShapeIsUsedWhenSettingSystemGestureExclusionRects() throws JSONException {
        // --- Test Setup ---
        DartExecutor dartExecutor = mock(DartExecutor.class);
        PlatformChannel platformChannel = new PlatformChannel(dartExecutor);
        PlatformMessageHandler platformMessageHandler = mock(PlatformMessageHandler.class);
        platformChannel.setPlatformMessageHandler(platformMessageHandler);
        Result result = mock(Result.class);

        // Add key/value pairs that aren't needed by exclusion rects to simulate incorrect JSON shape
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("arg1", 0);
        jsonObject.put("arg2", 500);
        JSONArray inputArray = new JSONArray();
        inputArray.put(jsonObject);

        MethodCall callSetSystemGestureExclusionRects = new MethodCall(
            "SystemGestures.setSystemGestureExclusionRects",
            inputArray
        );

        // --- Execute Test ---
        platformChannel.parsingMethodCallHandler.onMethodCall(callSetSystemGestureExclusionRects, result);

        // --- Verify Results ---
        verify(result, times(1)).error(
            "error",
            "JSON error: Incorrect JSON data shape. To set system gesture exclusion rects, \n" +
            "a JSONObject with top, right, bottom and left values need to be set to int values.",
            null
        );
    }
}

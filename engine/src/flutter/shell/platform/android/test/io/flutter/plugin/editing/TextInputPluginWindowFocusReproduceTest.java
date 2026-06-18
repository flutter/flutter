package io.flutter.plugin.editing;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.view.autofill.AutofillManager;
import androidx.test.core.app.ActivityScenario;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.ScribeChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.plugin.platform.PlatformViewsController2;
import java.nio.ByteBuffer;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;
import org.robolectric.shadow.api.Shadow;

@Config(shadows = {TextInputPluginTest.TestImm.class, TextInputPluginTest.TestAfm.class})
@RunWith(AndroidJUnit4.class)
public class TextInputPluginWindowFocusReproduceTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @SuppressWarnings("deprecation") // setMessageHandler is deprecated.
  @Config(minSdk = API_LEVELS.API_26)
  @Test
  public void onWindowFocusChanged_notifiesAutofillManager() {
    if (Build.VERSION.SDK_INT < API_LEVELS.API_26) {
      return;
    }

    TextInputPluginTest.TestAfm testAfm =
        Shadow.extract(ctx.getSystemService(AutofillManager.class));
    try (ActivityScenario<Activity> scenario = ActivityScenario.launch(Activity.class)) {
      scenario.onActivity(
          activity -> {
            FlutterView testView = new FlutterView(activity);
            DartExecutor mockDartExecutor = mock(DartExecutor.class);
            TextInputChannel textInputChannel = new TextInputChannel(mockDartExecutor);
            ScribeChannel scribeChannel = new ScribeChannel(mock(DartExecutor.class));
            TextInputPlugin textInputPlugin =
                new TextInputPlugin(
                    testView,
                    textInputChannel,
                    scribeChannel,
                    mock(PlatformViewsController.class),
                    mock(PlatformViewsController2.class));

            // Set up a simple autofill scenario.
            final TextInputChannel.Configuration.Autofill autofill =
                new TextInputChannel.Configuration.Autofill(
                    "uniqueId123",
                    new String[] {"HINT"},
                    "placeholder",
                    new TextInputChannel.TextEditState("initial text", 0, 0, -1, -1));

            final TextInputChannel.Configuration config =
                new TextInputChannel.Configuration(
                    false,
                    false,
                    true,
                    true,
                    false,
                    TextInputChannel.TextCapitalization.NONE,
                    null,
                    null,
                    null,
                    autofill,
                    null,
                    null,
                    null);

            textInputPlugin.setTextInputClient(0, config);

            // Initialize lastClientRect to avoid NullPointerException in notifyViewEntered.
            try {
              final JSONObject setEditableSizeAndTransformArgs = new JSONObject();
              setEditableSizeAndTransformArgs.put("width", 100.0);
              setEditableSizeAndTransformArgs.put("height", 50.0);
              final JSONArray matrix = new JSONArray();
              for (int i = 0; i < 16; i++) {
                matrix.put(i == 0 || i == 5 || i == 10 || i == 15 ? 1.0 : 0.0);
              }
              setEditableSizeAndTransformArgs.put("transform", matrix);

              // Capture the binary message handler registered on DartExecutor.
              ArgumentCaptor<BinaryMessenger.BinaryMessageHandler> handlerCaptor =
                  ArgumentCaptor.forClass(BinaryMessenger.BinaryMessageHandler.class);
              verify(mockDartExecutor)
                  .setMessageHandler(eq("flutter/textinput"), handlerCaptor.capture());
              BinaryMessenger.BinaryMessageHandler handler = handlerCaptor.getValue();

              MethodCall methodCall =
                  new MethodCall(
                      "TextInput.setEditableSizeAndTransform", setEditableSizeAndTransformArgs);
              ByteBuffer encodedMethodCall = JSONMethodCodec.INSTANCE.encodeMethodCall(methodCall);
              handler.onMessage(
                  (ByteBuffer) encodedMethodCall.flip(), mock(BinaryMessenger.BinaryReply.class));
            } catch (JSONException e) {
              throw new RuntimeException(e);
            }

            // Verify that we haven't exited the view initially.
            assertEquals(TextInputPluginTest.TestAfm.empty, testAfm.exitId);

            // Simulate window focus loss (e.g. switching to another app).
            textInputPlugin.onWindowFocusChanged(false);

            // Verify that notifyViewExited was called for the virtual ID "uniqueId123".
            assertEquals("uniqueId123".hashCode(), testAfm.exitId);

            // Reset AFM state.
            testAfm.resetStates();

            // Simulate window focus gain (e.g. switching back to the app).
            textInputPlugin.onWindowFocusChanged(true);

            // Verify that notifyViewEntered was called.
            assertEquals("uniqueId123".hashCode(), testAfm.enterId);
          });
    }
  }

  @SuppressWarnings("deprecation") // setMessageHandler is deprecated.
  @Config(minSdk = API_LEVELS.API_26)
  @Test
  public void onWindowFocusChanged_doesNotCrashWhenLastClientRectIsNull() {
    if (Build.VERSION.SDK_INT < API_LEVELS.API_26) {
      return;
    }

    TextInputPluginTest.TestAfm testAfm =
        Shadow.extract(ctx.getSystemService(AutofillManager.class));
    try (ActivityScenario<Activity> scenario = ActivityScenario.launch(Activity.class)) {
      scenario.onActivity(
          activity -> {
            FlutterView testView = new FlutterView(activity);
            DartExecutor mockDartExecutor = mock(DartExecutor.class);
            TextInputChannel textInputChannel = new TextInputChannel(mockDartExecutor);
            ScribeChannel scribeChannel = new ScribeChannel(mock(DartExecutor.class));
            TextInputPlugin textInputPlugin =
                new TextInputPlugin(
                    testView,
                    textInputChannel,
                    scribeChannel,
                    mock(PlatformViewsController.class),
                    mock(PlatformViewsController2.class));

            // Set up a simple autofill scenario.
            final TextInputChannel.Configuration.Autofill autofill =
                new TextInputChannel.Configuration.Autofill(
                    "uniqueId123",
                    new String[] {"HINT"},
                    "placeholder",
                    new TextInputChannel.TextEditState("initial text", 0, 0, -1, -1));

            final TextInputChannel.Configuration config =
                new TextInputChannel.Configuration(
                    false,
                    false,
                    true,
                    true,
                    false,
                    TextInputChannel.TextCapitalization.NONE,
                    null,
                    null,
                    null,
                    autofill,
                    null,
                    null,
                    null);

            textInputPlugin.setTextInputClient(0, config);

            // We do NOT set setEditableSizeAndTransform here, so lastClientRect remains null.
            testAfm.resetStates();

            // Simulate window focus gain.
            textInputPlugin.onWindowFocusChanged(true);

            // Verify that notifyViewEntered was NOT called since lastClientRect was null.
            assertEquals(TextInputPluginTest.TestAfm.empty, testAfm.enterId);
          });
    }
  }
}

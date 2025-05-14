package io.flutter.plugin.mouse;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.annotation.TargetApi;
import android.app.Activity;
import android.view.PointerIcon;
import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.MouseCursorChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import org.json.JSONException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(
    minSdk = API_LEVELS.API_24,
    shadows = {})
@RunWith(AndroidJUnit4.class)
@TargetApi(API_LEVELS.API_24)
public class MouseCursorPluginTest {

  @Test
  public void mouseCursorPlugin_SetsSystemCursorOnRequest() throws JSONException {
    try (ActivityScenario<Activity> scenario = ActivityScenario.launch(Activity.class)) {
      scenario.onActivity(
          activity -> {
            FlutterView testView = spy(new FlutterView(activity));
            MouseCursorChannel mouseCursorChannel =
                new MouseCursorChannel(mock(DartExecutor.class));

            MouseCursorPlugin mouseCursorPlugin =
                new MouseCursorPlugin(testView, mouseCursorChannel);

            final StoredResult methodResult = new StoredResult();
            mouseCursorChannel.synthesizeMethodCall(
                new MethodCall(
                    "activateSystemCursor",
                    new HashMap<String, Object>() {
                      private static final long serialVersionUID = 1L;

                      {
                        put("device", 1);
                        put("kind", "text");
                      }
                    }),
                methodResult);
            verify(testView, times(1)).getSystemPointerIcon(PointerIcon.TYPE_TEXT);
            verify(testView, times(1)).setPointerIcon(any(PointerIcon.class));
            assertEquals(methodResult.result, Boolean.TRUE);
          });
    }
  }
}

class StoredResult implements MethodChannel.Result {
  Object result;

  @Override
  public void success(Object result) {
    this.result = result;
  }

  @Override
  public void error(String errorCode, String errorMessage, Object errorDetails) {}

  @Override
  public void notImplemented() {}
}

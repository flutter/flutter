package io.flutter.embedding.engine.systemchannels;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.annotation.TargetApi;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(
    manifest = Config.NONE,
    shadows = {})
@RunWith(RobolectricTestRunner.class)
@TargetApi(24)
public class AccessibilityChannelTest {
  @Test
  public void repliesWhenNoAccessibilityHandler() throws JSONException {
    AccessibilityChannel accessibilityChannel =
        new AccessibilityChannel(mock(DartExecutor.class), mock(FlutterJNI.class));
    JSONObject arguments = new JSONObject();
    arguments.put("type", "announce");
    BasicMessageChannel.Reply reply = mock(BasicMessageChannel.Reply.class);
    accessibilityChannel.parsingMessageHandler.onMessage(arguments, reply);
    verify(reply).reply(null);
  }
}

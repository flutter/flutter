package io.flutter.plugin.platform;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.view.View;
import android.view.Window;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.ClipboardContentFormat;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class PlatformPluginTest {
  @Config(sdk = 16)
  @Test
  public void itIgnoresNewHapticEventsOnOldAndroidPlatforms() {
    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

    // HEAVY_IMPACT haptic response is only available on "M" (23) and later.
    platformPlugin.vibrateHapticFeedback(PlatformChannel.HapticFeedbackType.HEAVY_IMPACT);

    // SELECTION_CLICK haptic response is only available on "LOLLIPOP" (21) and later.
    platformPlugin.vibrateHapticFeedback(PlatformChannel.HapticFeedbackType.SELECTION_CLICK);
  }

  @Test
  public void platformPlugin_getClipboardData() {
    ClipboardManager clipboardManager =
        RuntimeEnvironment.application.getSystemService(ClipboardManager.class);

    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    when(fakeActivity.getSystemService(Context.CLIPBOARD_SERVICE)).thenReturn(clipboardManager);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

    ClipboardContentFormat clipboardFormat = ClipboardContentFormat.PLAIN_TEXT;
    assertNull(platformPlugin.mPlatformMessageHandler.getClipboardData(clipboardFormat));
    ClipData clip = ClipData.newPlainText("label", "Text");
    clipboardManager.setPrimaryClip(clip);
    assertNotNull(platformPlugin.mPlatformMessageHandler.getClipboardData(clipboardFormat));
  }

  @Test
  public void platformPlugin_hasStrings() {
    ClipboardManager clipboardManager =
        RuntimeEnvironment.application.getSystemService(ClipboardManager.class);

    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    when(fakeActivity.getSystemService(Context.CLIPBOARD_SERVICE)).thenReturn(clipboardManager);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

    ClipData clip = ClipData.newPlainText("label", "Text");
    clipboardManager.setPrimaryClip(clip);
    assertTrue(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());

    clip = ClipData.newPlainText("", "");
    clipboardManager.setPrimaryClip(clip);
    assertFalse(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());
  }
}

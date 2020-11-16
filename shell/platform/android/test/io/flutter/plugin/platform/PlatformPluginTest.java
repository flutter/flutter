package io.flutter.plugin.platform;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentResolver;
import android.content.Context;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.view.View;
import android.view.Window;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.ClipboardContentFormat;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.SystemChromeStyle;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
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

  @Config(sdk = 29)
  @Test
  public void platformPlugin_getClipboardData() throws IOException {
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

    ContentResolver contentResolver = RuntimeEnvironment.application.getContentResolver();
    Uri uri = Uri.parse("content://media/external_primary/images/media/");
    clip = ClipData.newUri(contentResolver, "URI", uri);
    clipboardManager.setPrimaryClip(clip);
    assertNull(platformPlugin.mPlatformMessageHandler.getClipboardData(clipboardFormat));

    uri =
        RingtoneManager.getActualDefaultRingtoneUri(
            RuntimeEnvironment.application.getApplicationContext(), RingtoneManager.TYPE_RINGTONE);
    clip = ClipData.newUri(contentResolver, "URI", uri);
    clipboardManager.setPrimaryClip(clip);
    String uriData =
        platformPlugin.mPlatformMessageHandler.getClipboardData(clipboardFormat).toString();
    InputStream uriInputStream = contentResolver.openInputStream(uri);
    InputStream dataInputStream = new ByteArrayInputStream(uriData.getBytes());
    assertEquals(dataInputStream.read(), uriInputStream.read());
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

  @Config(sdk = 29)
  @Test
  public void setNavigationBarDividerColor() {
    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);
    SystemChromeStyle style = new SystemChromeStyle(0XFF000000, null, 0XFFC70039, null, 0XFF006DB3);

    if (Build.VERSION.SDK_INT >= 28) {
      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      assertEquals(0XFF006DB3, fakeActivity.getWindow().getNavigationBarDividerColor());
      assertEquals(0XFFC70039, fakeActivity.getWindow().getStatusBarColor());
      assertEquals(0XFF000000, fakeActivity.getWindow().getNavigationBarColor());
    }
  }
}

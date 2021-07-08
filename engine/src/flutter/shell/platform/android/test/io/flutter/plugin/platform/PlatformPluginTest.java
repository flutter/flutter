package io.flutter.plugin.platform;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
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
import androidx.activity.OnBackPressedDispatcher;
import androidx.fragment.app.FragmentActivity;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.ClipboardContentFormat;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.SystemChromeStyle;
import io.flutter.plugin.platform.PlatformPlugin.PlatformPluginDelegate;
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

  @Config(sdk = 28)
  @Test
  public void platformPlugin_hasStrings() {
    ClipboardManager clipboardManager =
        spy(RuntimeEnvironment.application.getSystemService(ClipboardManager.class));

    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    when(fakeActivity.getSystemService(Context.CLIPBOARD_SERVICE)).thenReturn(clipboardManager);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

    // Plain text
    ClipData clip = ClipData.newPlainText("label", "Text");
    clipboardManager.setPrimaryClip(clip);
    assertTrue(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());

    // Empty plain text
    clip = ClipData.newPlainText("", "");
    clipboardManager.setPrimaryClip(clip);
    // Without actually accessing clipboard data (preferred behavior), it is not possible to
    // distinguish between empty and non-empty string contents.
    assertTrue(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());

    // HTML text
    clip = ClipData.newHtmlText("motto", "Don't be evil", "<b>Don't</b> be evil");
    clipboardManager.setPrimaryClip(clip);
    assertTrue(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());

    // Text MIME type
    clip = new ClipData("label", new String[] {"text/something"}, new ClipData.Item("content"));
    clipboardManager.setPrimaryClip(clip);
    assertTrue(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());

    // Other MIME type
    clip =
        new ClipData(
            "label", new String[] {"application/octet-stream"}, new ClipData.Item("content"));
    clipboardManager.setPrimaryClip(clip);
    assertFalse(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());

    if (Build.VERSION.SDK_INT >= 28) {
      // Empty clipboard
      clipboardManager.clearPrimaryClip();
      assertFalse(platformPlugin.mPlatformMessageHandler.clipboardHasStrings());
    }

    // Verify that the clipboard contents are never accessed.
    verify(clipboardManager, never()).getPrimaryClip();
    verify(clipboardManager, never()).getText();
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
    SystemChromeStyle style =
        new SystemChromeStyle(0XFF000000, null, true, 0XFFC70039, null, 0XFF006DB3, true);

    if (Build.VERSION.SDK_INT >= 28) {
      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      assertEquals(0XFF006DB3, fakeActivity.getWindow().getNavigationBarDividerColor());
      assertEquals(0XFFC70039, fakeActivity.getWindow().getStatusBarColor());
      assertEquals(0XFF000000, fakeActivity.getWindow().getNavigationBarColor());
    }
  }

  @Config(sdk = 29)
  @Test
  public void setSystemUiMode() {
    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

    if (Build.VERSION.SDK_INT >= 28) {
      platformPlugin.mPlatformMessageHandler.showSystemUiMode(
          PlatformChannel.SystemUiMode.LEAN_BACK);
      assertEquals(
          View.SYSTEM_UI_FLAG_LAYOUT_STABLE
              | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
              | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
              | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
              | View.SYSTEM_UI_FLAG_FULLSCREEN,
          fakeActivity.getWindow().getDecorView().getSystemUiVisibility());

      platformPlugin.mPlatformMessageHandler.showSystemUiMode(
          PlatformChannel.SystemUiMode.IMMERSIVE);
      assertEquals(
          View.SYSTEM_UI_FLAG_IMMERSIVE
              | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
              | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
              | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
              | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
              | View.SYSTEM_UI_FLAG_FULLSCREEN,
          fakeActivity.getWindow().getDecorView().getSystemUiVisibility());

      platformPlugin.mPlatformMessageHandler.showSystemUiMode(
          PlatformChannel.SystemUiMode.IMMERSIVE_STICKY);
      assertEquals(
          View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
              | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
              | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
              | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
              | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
              | View.SYSTEM_UI_FLAG_FULLSCREEN,
          fakeActivity.getWindow().getDecorView().getSystemUiVisibility());

      platformPlugin.mPlatformMessageHandler.showSystemUiMode(
          PlatformChannel.SystemUiMode.EDGE_TO_EDGE);
      assertEquals(
          View.SYSTEM_UI_FLAG_LAYOUT_STABLE
              | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
              | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN,
          fakeActivity.getWindow().getDecorView().getSystemUiVisibility());
    }
  }

  @Test
  public void popSystemNavigatorFlutterActivity() {
    Activity mockActivity = mock(Activity.class);
    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPluginDelegate mockPlatformPluginDelegate = mock(PlatformPluginDelegate.class);
    when(mockPlatformPluginDelegate.popSystemNavigator()).thenReturn(false);
    PlatformPlugin platformPlugin =
        new PlatformPlugin(mockActivity, mockPlatformChannel, mockPlatformPluginDelegate);

    platformPlugin.mPlatformMessageHandler.popSystemNavigator();

    verify(mockPlatformPluginDelegate, times(1)).popSystemNavigator();
    verify(mockActivity, times(1)).finish();
  }

  @Test
  public void doesNotDoAnythingByDefaultIfPopSystemNavigatorOverridden() {
    Activity mockActivity = mock(Activity.class);
    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPluginDelegate mockPlatformPluginDelegate = mock(PlatformPluginDelegate.class);
    when(mockPlatformPluginDelegate.popSystemNavigator()).thenReturn(true);
    PlatformPlugin platformPlugin =
        new PlatformPlugin(mockActivity, mockPlatformChannel, mockPlatformPluginDelegate);

    platformPlugin.mPlatformMessageHandler.popSystemNavigator();

    verify(mockPlatformPluginDelegate, times(1)).popSystemNavigator();
    // No longer perform the default action when overridden.
    verify(mockActivity, never()).finish();
  }

  @Test
  public void popSystemNavigatorFlutterFragment() {
    FragmentActivity mockFragmentActivity = mock(FragmentActivity.class);
    OnBackPressedDispatcher onBackPressedDispatcher = mock(OnBackPressedDispatcher.class);
    when(mockFragmentActivity.getOnBackPressedDispatcher()).thenReturn(onBackPressedDispatcher);
    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPluginDelegate mockPlatformPluginDelegate = mock(PlatformPluginDelegate.class);
    when(mockPlatformPluginDelegate.popSystemNavigator()).thenReturn(false);
    PlatformPlugin platformPlugin =
        new PlatformPlugin(mockFragmentActivity, mockPlatformChannel, mockPlatformPluginDelegate);

    platformPlugin.mPlatformMessageHandler.popSystemNavigator();

    verify(mockFragmentActivity, never()).finish();
    verify(mockPlatformPluginDelegate, times(1)).popSystemNavigator();
    verify(mockFragmentActivity, times(1)).getOnBackPressedDispatcher();
    verify(onBackPressedDispatcher, times(1)).onBackPressed();
  }

  @Test
  public void doesNotDoAnythingByDefaultIfFragmentPopSystemNavigatorOverridden() {
    FragmentActivity mockFragmentActivity = mock(FragmentActivity.class);
    OnBackPressedDispatcher onBackPressedDispatcher = mock(OnBackPressedDispatcher.class);
    when(mockFragmentActivity.getOnBackPressedDispatcher()).thenReturn(onBackPressedDispatcher);
    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPluginDelegate mockPlatformPluginDelegate = mock(PlatformPluginDelegate.class);
    when(mockPlatformPluginDelegate.popSystemNavigator()).thenReturn(true);
    PlatformPlugin platformPlugin =
        new PlatformPlugin(mockFragmentActivity, mockPlatformChannel, mockPlatformPluginDelegate);

    platformPlugin.mPlatformMessageHandler.popSystemNavigator();

    verify(mockPlatformPluginDelegate, times(1)).popSystemNavigator();
    // No longer perform the default action when overridden.
    verify(mockFragmentActivity, never()).finish();
    verify(mockFragmentActivity, never()).getOnBackPressedDispatcher();
  }

  @Test
  public void setRequestedOrientationFlutterFragment() {
    FragmentActivity mockFragmentActivity = mock(FragmentActivity.class);
    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPluginDelegate mockPlatformPluginDelegate = mock(PlatformPluginDelegate.class);
    when(mockPlatformPluginDelegate.popSystemNavigator()).thenReturn(false);
    PlatformPlugin platformPlugin =
        new PlatformPlugin(mockFragmentActivity, mockPlatformChannel, mockPlatformPluginDelegate);

    platformPlugin.mPlatformMessageHandler.setPreferredOrientations(0);

    verify(mockFragmentActivity, times(1)).setRequestedOrientation(0);
  }

  @Test
  public void performsDefaultBehaviorWhenNoDelegateProvided() {
    Activity mockActivity = mock(Activity.class);
    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(mockActivity, mockPlatformChannel);

    platformPlugin.mPlatformMessageHandler.popSystemNavigator();

    verify(mockActivity, times(1)).finish();
  }
}

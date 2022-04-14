package io.flutter.plugin.platform;

import static android.view.WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS;
import static android.view.WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS;
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
import android.net.Uri;
import android.os.Build;
import android.view.View;
import android.view.Window;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import androidx.activity.OnBackPressedCallback;
import androidx.fragment.app.FragmentActivity;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.Brightness;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.ClipboardContentFormat;
import io.flutter.embedding.engine.systemchannels.PlatformChannel.SystemChromeStyle;
import io.flutter.plugin.platform.PlatformPlugin.PlatformPluginDelegate;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class PlatformPluginTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

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
    ClipboardManager clipboardManager = ctx.getSystemService(ClipboardManager.class);

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

    ContentResolver contentResolver = ctx.getContentResolver();
    when(fakeActivity.getContentResolver()).thenReturn(contentResolver);
    Uri uri = Uri.parse("content://media/external_primary/images/media/");
    clip = ClipData.newUri(contentResolver, "URI", uri);
    clipboardManager.setPrimaryClip(clip);
    assertNull(platformPlugin.mPlatformMessageHandler.getClipboardData(clipboardFormat));
  }

  @Config(sdk = 28)
  @Test
  public void platformPlugin_hasStrings() {
    ClipboardManager clipboardManager = spy(ctx.getSystemService(ClipboardManager.class));

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

    if (Build.VERSION.SDK_INT >= 28) {
      // Default style test
      SystemChromeStyle style =
          new SystemChromeStyle(
              0XFF000000, // statusBarColor
              Brightness.LIGHT, // statusBarIconBrightness
              true, // systemStatusBarContrastEnforced
              0XFFC70039, // systemNavigationBarColor
              Brightness.LIGHT, // systemNavigationBarIconBrightness
              0XFF006DB3, // systemNavigationBarDividerColor
              true); // systemNavigationBarContrastEnforced

      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      verify(fakeWindow).setStatusBarColor(0xFF000000);
      verify(fakeWindow).setNavigationBarColor(0XFFC70039);
      verify(fakeWindow).setNavigationBarDividerColor(0XFF006DB3);
      verify(fakeWindow).setStatusBarContrastEnforced(true);
      verify(fakeWindow).setNavigationBarContrastEnforced(true);

      // Regression test for https://github.com/flutter/flutter/issues/88431
      // A null brightness should not affect changing color settings.
      style =
          new SystemChromeStyle(
              0XFF006DB3, // statusBarColor
              null, // statusBarIconBrightness
              false, // systemStatusBarContrastEnforced
              0XFF000000, // systemNavigationBarColor
              null, // systemNavigationBarIconBrightness
              0XFF006DB3, // systemNavigationBarDividerColor
              false); // systemNavigationBarContrastEnforced

      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      verify(fakeWindow).setStatusBarColor(0XFF006DB3);
      verify(fakeWindow).setNavigationBarColor(0XFF000000);
      verify(fakeWindow, times(2)).setNavigationBarDividerColor(0XFF006DB3);
      verify(fakeWindow).setStatusBarContrastEnforced(false);
      verify(fakeWindow).setNavigationBarContrastEnforced(false);

      // Null contrasts values should be allowed.
      style =
          new SystemChromeStyle(
              0XFF006DB3, // statusBarColor
              null, // statusBarIconBrightness
              null, // systemStatusBarContrastEnforced
              0XFF000000, // systemNavigationBarColor
              null, // systemNavigationBarIconBrightness
              0XFF006DB3, // systemNavigationBarDividerColor
              null); // systemNavigationBarContrastEnforced

      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      verify(fakeWindow, times(2)).setStatusBarColor(0XFF006DB3);
      verify(fakeWindow, times(2)).setNavigationBarColor(0XFF000000);
      verify(fakeWindow, times(3)).setNavigationBarDividerColor(0XFF006DB3);
      // Count is 1 each from earlier calls
      verify(fakeWindow, times(1)).setStatusBarContrastEnforced(true);
      verify(fakeWindow, times(1)).setNavigationBarContrastEnforced(true);
      verify(fakeWindow, times(1)).setStatusBarContrastEnforced(false);
      verify(fakeWindow, times(1)).setNavigationBarContrastEnforced(false);
    }
  }

  @Config(sdk = 30)
  @Test
  public void setNavigationBarIconBrightness() {
    if (Build.VERSION.SDK_INT >= 30) {
      View fakeDecorView = mock(View.class);
      WindowInsetsController fakeWindowInsetsController = mock(WindowInsetsController.class);
      Window fakeWindow = mock(Window.class);
      when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
      when(fakeWindow.getInsetsController()).thenReturn(fakeWindowInsetsController);
      Activity fakeActivity = mock(Activity.class);
      when(fakeActivity.getWindow()).thenReturn(fakeWindow);
      PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
      PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

      SystemChromeStyle style =
          new SystemChromeStyle(
              null, // statusBarColor
              null, // statusBarIconBrightness
              null, // systemStatusBarContrastEnforced
              null, // systemNavigationBarColor
              Brightness.LIGHT, // systemNavigationBarIconBrightness
              null, // systemNavigationBarDividerColor
              null); // systemNavigationBarContrastEnforced

      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      verify(fakeWindowInsetsController)
          .setSystemBarsAppearance(0, APPEARANCE_LIGHT_NAVIGATION_BARS);

      style =
          new SystemChromeStyle(
              null, // statusBarColor
              null, // statusBarIconBrightness
              null, // systemStatusBarContrastEnforced
              null, // systemNavigationBarColor
              Brightness.DARK, // systemNavigationBarIconBrightness
              null, // systemNavigationBarDividerColor
              null); // systemNavigationBarContrastEnforced

      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      verify(fakeWindowInsetsController)
          .setSystemBarsAppearance(
              APPEARANCE_LIGHT_NAVIGATION_BARS, APPEARANCE_LIGHT_NAVIGATION_BARS);
    }
  }

  @Config(sdk = 30)
  @Test
  public void setStatusBarIconBrightness() {
    if (Build.VERSION.SDK_INT >= 30) {
      View fakeDecorView = mock(View.class);
      WindowInsetsController fakeWindowInsetsController = mock(WindowInsetsController.class);
      Window fakeWindow = mock(Window.class);
      when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
      when(fakeWindow.getInsetsController()).thenReturn(fakeWindowInsetsController);
      Activity fakeActivity = mock(Activity.class);
      when(fakeActivity.getWindow()).thenReturn(fakeWindow);
      PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
      PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

      SystemChromeStyle style =
          new SystemChromeStyle(
              null, // statusBarColor
              Brightness.LIGHT, // statusBarIconBrightness
              null, // systemStatusBarContrastEnforced
              null, // systemNavigationBarColor
              null, // systemNavigationBarIconBrightness
              null, // systemNavigationBarDividerColor
              null); // systemNavigationBarContrastEnforced

      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      verify(fakeWindowInsetsController).setSystemBarsAppearance(0, APPEARANCE_LIGHT_STATUS_BARS);

      style =
          new SystemChromeStyle(
              null, // statusBarColor
              Brightness.DARK, // statusBarIconBrightness
              null, // systemStatusBarContrastEnforced
              null, // systemNavigationBarColor
              null, // systemNavigationBarIconBrightness
              null, // systemNavigationBarDividerColor
              null); // systemNavigationBarContrastEnforced

      platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);

      verify(fakeWindowInsetsController)
          .setSystemBarsAppearance(APPEARANCE_LIGHT_STATUS_BARS, APPEARANCE_LIGHT_STATUS_BARS);
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
      verify(fakeDecorView)
          .setSystemUiVisibility(
              View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                  | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                  | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                  | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                  | View.SYSTEM_UI_FLAG_FULLSCREEN);

      platformPlugin.mPlatformMessageHandler.showSystemUiMode(
          PlatformChannel.SystemUiMode.IMMERSIVE);
      verify(fakeDecorView)
          .setSystemUiVisibility(
              View.SYSTEM_UI_FLAG_IMMERSIVE
                  | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                  | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                  | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                  | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                  | View.SYSTEM_UI_FLAG_FULLSCREEN);

      platformPlugin.mPlatformMessageHandler.showSystemUiMode(
          PlatformChannel.SystemUiMode.IMMERSIVE_STICKY);
      verify(fakeDecorView)
          .setSystemUiVisibility(
              View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                  | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                  | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                  | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                  | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                  | View.SYSTEM_UI_FLAG_FULLSCREEN);
    }

    if (Build.VERSION.SDK_INT >= 29) {
      platformPlugin.mPlatformMessageHandler.showSystemUiMode(
          PlatformChannel.SystemUiMode.EDGE_TO_EDGE);
      verify(fakeDecorView)
          .setSystemUiVisibility(
              View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                  | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                  | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
    }
  }

  @Config(sdk = 28)
  @Test
  public void doNotEnableEdgeToEdgeOnOlderSdk() {
    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

    platformPlugin.mPlatformMessageHandler.showSystemUiMode(
        PlatformChannel.SystemUiMode.EDGE_TO_EDGE);
    verify(fakeDecorView, never())
        .setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
  }

  @Config(sdk = 29)
  @Test
  public void verifyWindowFlagsSetToStyleOverlays() {
    View fakeDecorView = mock(View.class);
    Window fakeWindow = mock(Window.class);
    when(fakeWindow.getDecorView()).thenReturn(fakeDecorView);
    Activity fakeActivity = mock(Activity.class);
    when(fakeActivity.getWindow()).thenReturn(fakeWindow);
    PlatformChannel fakePlatformChannel = mock(PlatformChannel.class);
    PlatformPlugin platformPlugin = new PlatformPlugin(fakeActivity, fakePlatformChannel);

    SystemChromeStyle style =
        new SystemChromeStyle(
            0XFF000000, Brightness.LIGHT, true, 0XFFC70039, Brightness.LIGHT, 0XFF006DB3, true);

    platformPlugin.mPlatformMessageHandler.setSystemUiOverlayStyle(style);
    verify(fakeWindow).addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
    verify(fakeWindow)
        .clearFlags(
            WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS
                | WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION);
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
    FragmentActivity activity = spy(Robolectric.setupActivity(FragmentActivity.class));
    final AtomicBoolean onBackPressedCalled = new AtomicBoolean(false);
    OnBackPressedCallback backCallback =
        new OnBackPressedCallback(true) {
          @Override
          public void handleOnBackPressed() {
            onBackPressedCalled.set(true);
          }
        };
    activity.getOnBackPressedDispatcher().addCallback(backCallback);

    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPluginDelegate mockPlatformPluginDelegate = mock(PlatformPluginDelegate.class);
    when(mockPlatformPluginDelegate.popSystemNavigator()).thenReturn(false);
    PlatformPlugin platformPlugin =
        new PlatformPlugin(activity, mockPlatformChannel, mockPlatformPluginDelegate);

    platformPlugin.mPlatformMessageHandler.popSystemNavigator();

    verify(activity, never()).finish();
    verify(mockPlatformPluginDelegate, times(1)).popSystemNavigator();
    assertTrue(onBackPressedCalled.get());
  }

  @Test
  public void doesNotDoAnythingByDefaultIfFragmentPopSystemNavigatorOverridden() {
    FragmentActivity activity = spy(Robolectric.setupActivity(FragmentActivity.class));
    PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
    PlatformPluginDelegate mockPlatformPluginDelegate = mock(PlatformPluginDelegate.class);
    when(mockPlatformPluginDelegate.popSystemNavigator()).thenReturn(true);
    PlatformPlugin platformPlugin =
        new PlatformPlugin(activity, mockPlatformChannel, mockPlatformPluginDelegate);

    platformPlugin.mPlatformMessageHandler.popSystemNavigator();

    verify(mockPlatformPluginDelegate, times(1)).popSystemNavigator();
    // No longer perform the default action when overridden.
    verify(activity, never()).finish();
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

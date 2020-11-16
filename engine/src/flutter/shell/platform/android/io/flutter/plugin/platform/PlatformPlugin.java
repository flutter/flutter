// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.app.Activity;
import android.app.ActivityManager.TaskDescription;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.os.Build;
import android.view.HapticFeedbackConstants;
import android.view.SoundEffectConstants;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import java.io.FileNotFoundException;
import java.util.List;

/** Android implementation of the platform plugin. */
public class PlatformPlugin {
  public static final int DEFAULT_SYSTEM_UI =
      View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;

  private final Activity activity;
  private final PlatformChannel platformChannel;
  private PlatformChannel.SystemChromeStyle currentTheme;
  private int mEnabledOverlays;
  private static final String TAG = "PlatformPlugin";

  @VisibleForTesting
  final PlatformChannel.PlatformMessageHandler mPlatformMessageHandler =
      new PlatformChannel.PlatformMessageHandler() {
        @Override
        public void playSystemSound(@NonNull PlatformChannel.SoundType soundType) {
          PlatformPlugin.this.playSystemSound(soundType);
        }

        @Override
        public void vibrateHapticFeedback(
            @NonNull PlatformChannel.HapticFeedbackType feedbackType) {
          PlatformPlugin.this.vibrateHapticFeedback(feedbackType);
        }

        @Override
        public void setPreferredOrientations(int androidOrientation) {
          setSystemChromePreferredOrientations(androidOrientation);
        }

        @Override
        public void setApplicationSwitcherDescription(
            @NonNull PlatformChannel.AppSwitcherDescription description) {
          setSystemChromeApplicationSwitcherDescription(description);
        }

        @Override
        public void showSystemOverlays(@NonNull List<PlatformChannel.SystemUiOverlay> overlays) {
          setSystemChromeEnabledSystemUIOverlays(overlays);
        }

        @Override
        public void restoreSystemUiOverlays() {
          restoreSystemChromeSystemUIOverlays();
        }

        @Override
        public void setSystemUiOverlayStyle(
            @NonNull PlatformChannel.SystemChromeStyle systemUiOverlayStyle) {
          setSystemChromeSystemUIOverlayStyle(systemUiOverlayStyle);
        }

        @Override
        public void popSystemNavigator() {
          PlatformPlugin.this.popSystemNavigator();
        }

        @Override
        public CharSequence getClipboardData(
            @Nullable PlatformChannel.ClipboardContentFormat format) {
          return PlatformPlugin.this.getClipboardData(format);
        }

        @Override
        public void setClipboardData(@NonNull String text) {
          PlatformPlugin.this.setClipboardData(text);
        }

        @Override
        public boolean clipboardHasStrings() {
          CharSequence data =
              PlatformPlugin.this.getClipboardData(
                  PlatformChannel.ClipboardContentFormat.PLAIN_TEXT);
          return data != null && data.length() > 0;
        }
      };

  public PlatformPlugin(Activity activity, PlatformChannel platformChannel) {
    this.activity = activity;
    this.platformChannel = platformChannel;
    this.platformChannel.setPlatformMessageHandler(mPlatformMessageHandler);

    mEnabledOverlays = DEFAULT_SYSTEM_UI;
  }

  /**
   * Releases all resources held by this {@code PlatformPlugin}.
   *
   * <p>Do not invoke any methods on a {@code PlatformPlugin} after invoking this method.
   */
  public void destroy() {
    this.platformChannel.setPlatformMessageHandler(null);
  }

  private void playSystemSound(PlatformChannel.SoundType soundType) {
    if (soundType == PlatformChannel.SoundType.CLICK) {
      View view = activity.getWindow().getDecorView();
      view.playSoundEffect(SoundEffectConstants.CLICK);
    }
  }

  @VisibleForTesting
  /* package */ void vibrateHapticFeedback(PlatformChannel.HapticFeedbackType feedbackType) {
    View view = activity.getWindow().getDecorView();
    switch (feedbackType) {
      case STANDARD:
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
        break;
      case LIGHT_IMPACT:
        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);
        break;
      case MEDIUM_IMPACT:
        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP);
        break;
      case HEAVY_IMPACT:
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK);
        }
        break;
      case SELECTION_CLICK:
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK);
        }
        break;
    }
  }

  private void setSystemChromePreferredOrientations(int androidOrientation) {
    activity.setRequestedOrientation(androidOrientation);
  }

  @SuppressWarnings("deprecation")
  private void setSystemChromeApplicationSwitcherDescription(
      PlatformChannel.AppSwitcherDescription description) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
      return;
    }

    // Linter refuses to believe we're only executing this code in API 28 unless we use distinct if
    // blocks and
    // hardcode the API 28 constant.
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P
        && Build.VERSION.SDK_INT > Build.VERSION_CODES.LOLLIPOP) {
      activity.setTaskDescription(
          new TaskDescription(description.label, /*icon=*/ null, description.color));
    }
    if (Build.VERSION.SDK_INT >= 28) {
      TaskDescription taskDescription =
          new TaskDescription(description.label, 0, description.color);
      activity.setTaskDescription(taskDescription);
    }
  }

  private void setSystemChromeEnabledSystemUIOverlays(
      List<PlatformChannel.SystemUiOverlay> overlaysToShow) {
    // Start by assuming we want to hide all system overlays (like an immersive game).
    int enabledOverlays =
        DEFAULT_SYSTEM_UI
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;

    // The SYSTEM_UI_FLAG_IMMERSIVE_STICKY flag was introduced in API 19, so we apply it
    // if desired, and if the current Android version is 19 or greater.
    if (overlaysToShow.size() == 0 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      enabledOverlays |= View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
    }

    // Re-add any desired system overlays.
    for (int i = 0; i < overlaysToShow.size(); ++i) {
      PlatformChannel.SystemUiOverlay overlayToShow = overlaysToShow.get(i);
      switch (overlayToShow) {
        case TOP_OVERLAYS:
          enabledOverlays &= ~View.SYSTEM_UI_FLAG_FULLSCREEN;
          break;
        case BOTTOM_OVERLAYS:
          enabledOverlays &= ~View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION;
          enabledOverlays &= ~View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
          break;
      }
    }

    mEnabledOverlays = enabledOverlays;
    updateSystemUiOverlays();
  }

  /**
   * Refreshes Android's window system UI (AKA system chrome) to match Flutter's desired {@link
   * PlatformChannel.SystemChromeStyle}.
   *
   * <p>Updating the system UI Overlays is accomplished by altering the decor view of the {@link
   * Window} associated with the {@link Activity} that was provided to this {@code PlatformPlugin}.
   */
  public void updateSystemUiOverlays() {
    activity.getWindow().getDecorView().setSystemUiVisibility(mEnabledOverlays);
    if (currentTheme != null) {
      setSystemChromeSystemUIOverlayStyle(currentTheme);
    }
  }

  private void restoreSystemChromeSystemUIOverlays() {
    updateSystemUiOverlays();
  }

  private void setSystemChromeSystemUIOverlayStyle(
      PlatformChannel.SystemChromeStyle systemChromeStyle) {
    Window window = activity.getWindow();
    View view = window.getDecorView();
    int flags = view.getSystemUiVisibility();
    // You can change the navigation bar color (including translucent colors)
    // in Android, but you can't change the color of the navigation buttons until Android O.
    // LIGHT vs DARK effectively isn't supported until then.
    // Build.VERSION_CODES.O
    if (Build.VERSION.SDK_INT >= 26) {
      if (systemChromeStyle.systemNavigationBarIconBrightness != null) {
        switch (systemChromeStyle.systemNavigationBarIconBrightness) {
          case DARK:
            // View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
            flags |= 0x10;
            break;
          case LIGHT:
            flags &= ~0x10;
            break;
        }
      }
      if (systemChromeStyle.systemNavigationBarColor != null) {
        window.setNavigationBarColor(systemChromeStyle.systemNavigationBarColor);
      }
    }
    // Build.VERSION_CODES.M
    if (Build.VERSION.SDK_INT >= 23) {
      if (systemChromeStyle.statusBarIconBrightness != null) {
        switch (systemChromeStyle.statusBarIconBrightness) {
          case DARK:
            // View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            flags |= 0x2000;
            break;
          case LIGHT:
            flags &= ~0x2000;
            break;
        }
      }
      if (systemChromeStyle.statusBarColor != null) {
        window.setStatusBarColor(systemChromeStyle.statusBarColor);
      }
    }
    if (systemChromeStyle.systemNavigationBarDividerColor != null && Build.VERSION.SDK_INT >= 28) {
      window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
      window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION);
      window.setNavigationBarDividerColor(systemChromeStyle.systemNavigationBarDividerColor);
    }
    view.setSystemUiVisibility(flags);
    currentTheme = systemChromeStyle;
  }

  private void popSystemNavigator() {
    activity.finish();
  }

  private CharSequence getClipboardData(PlatformChannel.ClipboardContentFormat format) {
    ClipboardManager clipboard =
        (ClipboardManager) activity.getSystemService(Context.CLIPBOARD_SERVICE);

    if (!clipboard.hasPrimaryClip()) return null;

    try {
      ClipData clip = clipboard.getPrimaryClip();
      if (clip == null) return null;
      if (format == null || format == PlatformChannel.ClipboardContentFormat.PLAIN_TEXT) {
        ClipData.Item item = clip.getItemAt(0);
        if (item.getUri() != null)
          activity.getContentResolver().openTypedAssetFileDescriptor(item.getUri(), "text/*", null);
        return item.coerceToText(activity);
      }
    } catch (SecurityException e) {
      Log.w(
          TAG,
          "Attempted to get clipboard data that requires additional permission(s).\n"
              + "See the exception details for which permission(s) are required, and consider adding them to your Android Manifest as described in:\n"
              + "https://developer.android.com/guide/topics/permissions/overview",
          e);
      return null;
    } catch (FileNotFoundException e) {
      return null;
    }

    return null;
  }

  private void setClipboardData(String text) {
    ClipboardManager clipboard =
        (ClipboardManager) activity.getSystemService(Context.CLIPBOARD_SERVICE);
    ClipData clip = ClipData.newPlainText("text label?", text);
    clipboard.setPrimaryClip(clip);
  }
}

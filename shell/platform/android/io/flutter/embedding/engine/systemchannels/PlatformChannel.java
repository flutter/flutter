// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.content.pm.ActivityInfo;
import android.graphics.Rect;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.annotation.VisibleForTesting;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * System channel that receives requests for host platform behavior, e.g., haptic and sound
 * effects, system chrome configurations, and clipboard interaction.
 */
public class PlatformChannel {
  private static final String TAG = "PlatformChannel";

  @NonNull
  public final MethodChannel channel;
  @Nullable
  private PlatformMessageHandler platformMessageHandler;
  @NonNull
  @VisibleForTesting
  protected final MethodChannel.MethodCallHandler parsingMethodCallHandler = new MethodChannel.MethodCallHandler() {
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
      if (platformMessageHandler == null) {
        // If no explicit PlatformMessageHandler has been registered then we don't
        // need to forward this call to an API. Return.
        return;
      }

      String method = call.method;
      Object arguments = call.arguments;
      Log.v(TAG, "Received '" + method + "' message.");
      try {
        switch (method) {
          case "SystemSound.play":
            try {
              SoundType soundType = SoundType.fromValue((String) arguments);
              platformMessageHandler.playSystemSound(soundType);
              result.success(null);
            } catch (NoSuchFieldException exception) {
              // The desired sound type does not exist.
              result.error("error", exception.getMessage(), null);
            }
            break;
          case "HapticFeedback.vibrate":
            try {
              HapticFeedbackType feedbackType = HapticFeedbackType.fromValue((String) arguments);
              platformMessageHandler.vibrateHapticFeedback(feedbackType);
              result.success(null);
            } catch (NoSuchFieldException exception) {
              // The desired feedback type does not exist.
              result.error("error", exception.getMessage(), null);
            }
            break;
          case "SystemChrome.setPreferredOrientations":
            try {
              int androidOrientation = decodeOrientations((JSONArray) arguments);
              platformMessageHandler.setPreferredOrientations(androidOrientation);
              result.success(null);
            } catch (JSONException | NoSuchFieldException exception) {
              // JSONException: One or more expected fields were either omitted or referenced an invalid type.
              // NoSuchFieldException: One or more expected fields were either omitted or referenced an invalid type.
              result.error("error", exception.getMessage(), null);
            }
            break;
          case "SystemChrome.setApplicationSwitcherDescription":
            try {
              AppSwitcherDescription description = decodeAppSwitcherDescription((JSONObject) arguments);
              platformMessageHandler.setApplicationSwitcherDescription(description);
              result.success(null);
            } catch (JSONException exception) {
              // One or more expected fields were either omitted or referenced an invalid type.
              result.error("error", exception.getMessage(), null);
            }
            break;
          case "SystemChrome.setEnabledSystemUIOverlays":
            try {
              List<SystemUiOverlay> overlays = decodeSystemUiOverlays((JSONArray) arguments);
              platformMessageHandler.showSystemOverlays(overlays);
              result.success(null);
            } catch (JSONException | NoSuchFieldException exception) {
              // JSONException: One or more expected fields were either omitted or referenced an invalid type.
              // NoSuchFieldException: One or more of the overlay names are invalid.
              result.error("error", exception.getMessage(), null);
            }
            break;
          case "SystemChrome.restoreSystemUIOverlays":
            platformMessageHandler.restoreSystemUiOverlays();
            result.success(null);
            break;
          case "SystemChrome.setSystemUIOverlayStyle":
            try {
              SystemChromeStyle systemChromeStyle = decodeSystemChromeStyle((JSONObject) arguments);
              platformMessageHandler.setSystemUiOverlayStyle(systemChromeStyle);
              result.success(null);
            } catch (JSONException | NoSuchFieldException exception) {
              // JSONException: One or more expected fields were either omitted or referenced an invalid type.
              // NoSuchFieldException: One or more of the brightness names are invalid.
              result.error("error", exception.getMessage(), null);
            }
            break;
          case "SystemNavigator.pop":
            platformMessageHandler.popSystemNavigator();
            result.success(null);
            break;
          case "SystemGestures.getSystemGestureExclusionRects":
            List<Rect> exclusionRects = platformMessageHandler.getSystemGestureExclusionRects();
            if (exclusionRects == null) {
              String incorrectApiLevel = "Exclusion rects only exist for Android API 29+.";
              result.error("error", incorrectApiLevel, null);
              break;
            }

            ArrayList<HashMap<String, Integer>> encodedExclusionRects = encodeExclusionRects(exclusionRects);
            result.success(encodedExclusionRects);
            break;
          case "SystemGestures.setSystemGestureExclusionRects":
            if (!(arguments instanceof JSONArray)) {
              String inputTypeError = "Input type is incorrect. Ensure that a List<Map<String, int>> is passed as the input for SystemGestureExclusionRects.setSystemGestureExclusionRects.";
              result.error("inputTypeError", inputTypeError, null);
              break;
            }

            JSONArray inputRects = (JSONArray) arguments;
            ArrayList<Rect> decodedRects = decodeExclusionRects(inputRects);
            platformMessageHandler.setSystemGestureExclusionRects(decodedRects);
            result.success(null);
            break;
          case "Clipboard.getData": {
            String contentFormatName = (String) arguments;
            ClipboardContentFormat clipboardFormat = null;
            if (contentFormatName != null) {
              try {
                clipboardFormat = ClipboardContentFormat.fromValue(contentFormatName);
              } catch (NoSuchFieldException exception) {
                // An unsupported content format was requested. Return failure.
                result.error("error", "No such clipboard content format: " + contentFormatName, null);
              }
            }

            CharSequence clipboardContent = platformMessageHandler.getClipboardData(clipboardFormat);
            if (clipboardContent != null) {
              JSONObject response = new JSONObject();
              response.put("text", clipboardContent);
              result.success(response);
            } else {
              result.success(null);
            }
            break;
          }
          case "Clipboard.setData": {
            String clipboardContent = ((JSONObject) arguments).getString("text");
            platformMessageHandler.setClipboardData(clipboardContent);
            result.success(null);
            break;
          }
          default:
            result.notImplemented();
            break;
        }
      } catch (JSONException e) {
        result.error("error", "JSON error: " + e.getMessage(), null);
      }
    }
  };

  /**
   * Constructs a {@code PlatformChannel} that connects Android to the Dart code
   * running in {@code dartExecutor}.
   *
   * The given {@code dartExecutor} is permitted to be idle or executing code.
   *
   * See {@link DartExecutor}.
   */
  public PlatformChannel(@NonNull DartExecutor dartExecutor) {
    channel = new MethodChannel(dartExecutor, "flutter/platform", JSONMethodCodec.INSTANCE);
    channel.setMethodCallHandler(parsingMethodCallHandler);
  }

  /**
   * Sets the {@link PlatformMessageHandler} which receives all events and requests
   * that are parsed from the underlying platform channel.
   */
  public void setPlatformMessageHandler(@Nullable PlatformMessageHandler platformMessageHandler) {
    this.platformMessageHandler = platformMessageHandler;
  }

  // TODO(mattcarroll): add support for IntDef annotations, then add @ScreenOrientation

  /**
   * Decodes a series of orientations to an aggregate desired orientation.
   *
   * @throws JSONException if {@code encodedOrientations} does not contain expected keys and value types.
   * @throws NoSuchFieldException if any given encoded orientation is not a valid orientation name.
   */
  private int decodeOrientations(@NonNull JSONArray encodedOrientations) throws JSONException, NoSuchFieldException {
    int requestedOrientation = 0x00;
    int firstRequestedOrientation = 0x00;
    for (int index = 0; index < encodedOrientations.length(); index += 1) {
      String encodedOrientation = encodedOrientations.getString(index);
      DeviceOrientation orientation = DeviceOrientation.fromValue(encodedOrientation);

      switch (orientation) {
        case PORTRAIT_UP:
          requestedOrientation |= 0x01;
          break;
        case PORTRAIT_DOWN:
          requestedOrientation |= 0x04;
          break;
        case LANDSCAPE_LEFT:
          requestedOrientation |= 0x02;
          break;
        case LANDSCAPE_RIGHT:
          requestedOrientation |= 0x08;
          break;
      }

      if (firstRequestedOrientation == 0x00) {
        firstRequestedOrientation = requestedOrientation;
      }
    }

    switch (requestedOrientation) {
      case 0x00:
        return ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
      case 0x01:
        return ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
      case 0x02:
        return ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
      case 0x04:
        return ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
      case 0x05:
        return ActivityInfo.SCREEN_ORIENTATION_USER_PORTRAIT;
      case 0x08:
        return ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
      case 0x0a:
        return ActivityInfo.SCREEN_ORIENTATION_USER_LANDSCAPE;
      case 0x0b:
        return ActivityInfo.SCREEN_ORIENTATION_USER;
      case 0x0f:
        return ActivityInfo.SCREEN_ORIENTATION_FULL_USER;
      case 0x03: // portraitUp and landscapeLeft
      case 0x06: // portraitDown and landscapeLeft
      case 0x07: // portraitUp, portraitDown, and landscapeLeft
      case 0x09: // portraitUp and landscapeRight
      case 0x0c: // portraitDown and landscapeRight
      case 0x0d: // portraitUp, portraitDown, and landscapeRight
      case 0x0e: // portraitDown, landscapeLeft, and landscapeRight
        // Android can't describe these cases, so just default to whatever the first
        // specified value was.
        switch (firstRequestedOrientation) {
          case 0x01:
            return ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
          case 0x02:
            return ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
          case 0x04:
            return ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
          case 0x08:
            return ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
        }
    }

    // Execution should never get this far, but if it does then we default
    // to a portrait orientation.
    return ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
  }

  /**
   * Decodes a JSONArray of rectangle data into an ArrayList<Rect>.
   *
   * Since View.setSystemGestureExclusionRects receives a JSONArray containing
   * JSONObjects, these values need to be transformed into the expected input
   * of View.setSystemGestureExclusionRects, which is ArrayList<Rect>.
   *
   * This method is used by the SystemGestures.setSystemGestureExclusionRects
   * platform channel.
   *
   * @throws JSONException if {@code inputRects} does not contain expected keys and value types.
   */
  @NonNull
  private ArrayList<Rect> decodeExclusionRects(@NonNull JSONArray inputRects) throws JSONException {
    ArrayList<Rect> exclusionRects = new ArrayList<Rect>();
    for (int i = 0; i < inputRects.length(); i++) {
      JSONObject rect = inputRects.getJSONObject(i);
      int top;
      int right;
      int bottom;
      int left;

      try {
        top = rect.getInt("top");
        right = rect.getInt("right");
        bottom = rect.getInt("bottom");
        left = rect.getInt("left");
      } catch (JSONException exception) {
        throw new JSONException(
          "Incorrect JSON data shape. To set system gesture exclusion rects, \n" +
          "a JSONObject with top, right, bottom and left values need to be set to int values."
        );
      }

      Rect gestureRect = new Rect(left, top, right, bottom);
      exclusionRects.add(gestureRect);
    }

    return exclusionRects;
  }

  /**
   * Encodes a List<Rect> provided by the Android host into an
   * ArrayList<HashMap<String, Integer>>.
   *
   * Since View.getSystemGestureExclusionRects returns a list of Rects, these
   * Rects need to be transformed into UTF-8 encoded JSON messages to be
   * properly decoded by the Flutter framework.
   *
   * This method is used by the SystemGestures.getSystemGestureExclusionRects
   * platform channel.
   */
  private ArrayList<HashMap<String, Integer>> encodeExclusionRects(List<Rect> exclusionRects) {
    ArrayList<HashMap<String, Integer>> encodedExclusionRects = new ArrayList<HashMap<String, Integer>>();
    for (Rect rect : exclusionRects) {
      HashMap<String, Integer> rectMap = new HashMap<String, Integer>();
      rectMap.put("top", rect.top);
      rectMap.put("right", rect.right);
      rectMap.put("bottom", rect.bottom);
      rectMap.put("left", rect.left);
      encodedExclusionRects.add(rectMap);
    }

    return encodedExclusionRects;
  }

  @NonNull
  private AppSwitcherDescription decodeAppSwitcherDescription(@NonNull JSONObject encodedDescription) throws JSONException {
    int color = encodedDescription.getInt("primaryColor");
    if (color != 0) { // 0 means color isn't set, use system default
      color = color | 0xFF000000; // color must be opaque if set
    }
    String label = encodedDescription.getString("label");
    return new AppSwitcherDescription(color, label);
  }

  /**
   * Decodes a list of JSON-encoded overlays to a list of {@link SystemUiOverlay}.
   *
   * @throws JSONException if {@code encodedSystemUiOverlay} does not contain expected keys and value types.
   * @throws NoSuchFieldException if any of the given encoded overlay names are invalid.
   */
  @NonNull
  private List<SystemUiOverlay> decodeSystemUiOverlays(@NonNull JSONArray encodedSystemUiOverlay) throws JSONException, NoSuchFieldException {
    List<SystemUiOverlay> overlays = new ArrayList<>();
    for (int i = 0; i < encodedSystemUiOverlay.length(); ++i) {
      String encodedOverlay = encodedSystemUiOverlay.getString(i);
      SystemUiOverlay overlay = SystemUiOverlay.fromValue(encodedOverlay);
      switch(overlay) {
        case TOP_OVERLAYS:
          overlays.add(SystemUiOverlay.TOP_OVERLAYS);
          break;
        case BOTTOM_OVERLAYS:
          overlays.add(SystemUiOverlay.BOTTOM_OVERLAYS);
          break;
      }
    }
    return overlays;
  }

  /**
   * Decodes a JSON-encoded {@code encodedStyle} to a {@link SystemChromeStyle}.
   *
   * @throws JSONException if {@code encodedStyle} does not contain expected keys and value types.
   * @throws NoSuchFieldException if any provided brightness name is invalid.
   */
  @NonNull
  private SystemChromeStyle decodeSystemChromeStyle(@NonNull JSONObject encodedStyle) throws JSONException, NoSuchFieldException {
    Brightness systemNavigationBarIconBrightness = null;
    // TODO(mattcarroll): add color annotation
    Integer systemNavigationBarColor = null;
    // TODO(mattcarroll): add color annotation
    Integer systemNavigationBarDividerColor = null;
    Brightness statusBarIconBrightness = null;
    // TODO(mattcarroll): add color annotation
    Integer statusBarColor = null;

    if (!encodedStyle.isNull("systemNavigationBarIconBrightness")) {
      systemNavigationBarIconBrightness = Brightness.fromValue(encodedStyle.getString("systemNavigationBarIconBrightness"));
    }

    if (!encodedStyle.isNull("systemNavigationBarColor")) {
      systemNavigationBarColor = encodedStyle.getInt("systemNavigationBarColor");
    }

    if (!encodedStyle.isNull("statusBarIconBrightness")) {
      statusBarIconBrightness = Brightness.fromValue(encodedStyle.getString("statusBarIconBrightness"));
    }

    if (!encodedStyle.isNull("statusBarColor")) {
      statusBarColor = encodedStyle.getInt("statusBarColor");
    }

    if (!encodedStyle.isNull("systemNavigationBarDividerColor")) {
      systemNavigationBarDividerColor = encodedStyle.getInt("systemNavigationBarDividerColor");
    }

    return new SystemChromeStyle(
      statusBarColor,
      statusBarIconBrightness,
      systemNavigationBarColor,
      systemNavigationBarIconBrightness,
      systemNavigationBarDividerColor
    );
  }

  /**
   * Handler that receives platform messages sent from Flutter to Android
   * through a given {@link PlatformChannel}.
   *
   * To register a {@code PlatformMessageHandler} with a {@link PlatformChannel},
   * see {@link PlatformChannel#setPlatformMessageHandler(PlatformMessageHandler)}.
   */
  public interface PlatformMessageHandler {
    /**
     * The Flutter application would like to play the given {@code soundType}.
     */
    void playSystemSound(@NonNull SoundType soundType);

    /**
     * The Flutter application would like to play the given haptic {@code feedbackType}.
     */
    void vibrateHapticFeedback(@NonNull HapticFeedbackType feedbackType);

    /**
     * The Flutter application would like to display in the given {@code androidOrientation}.
     */
    // TODO(mattcarroll): add @ScreenOrientation annotation
    void setPreferredOrientations(int androidOrientation);

    /**
     * The Flutter application would like to be displayed in Android's app switcher with
     * the visual representation described in the given {@code description}.
     * <p>
     * See the related Android documentation:
     * https://developer.android.com/guide/components/activities/recents
     */
    void setApplicationSwitcherDescription(@NonNull AppSwitcherDescription description);

    /**
     * The Flutter application would like the Android system to display the given
     * {@code overlays}.
     * <p>
     * {@link SystemUiOverlay#TOP_OVERLAYS} refers to system overlays such as the
     * status bar, while {@link SystemUiOverlay#BOTTOM_OVERLAYS} refers to system
     * overlays such as the back/home/recents navigation on the bottom of the screen.
     * <p>
     * An empty list of {@code overlays} should hide all system overlays.
     */
    void showSystemOverlays(@NonNull List<SystemUiOverlay> overlays);

    /**
     * The Flutter application would like to restore the visibility of system
     * overlays to the last set of overlays sent via {@link #showSystemOverlays(List)}.
     * <p>
     * If {@link #showSystemOverlays(List)} has yet to be called, then a default
     * system overlay appearance is desired:
     * <p>
     * {@code
     * View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
     * }
     */
    void restoreSystemUiOverlays();

    /**
     * The Flutter application would like the system chrome to present itself with
     * the given {@code systemUiOverlayStyle}, i.e., the given status bar and
     * navigation bar colors and brightness.
     */
    void setSystemUiOverlayStyle(@NonNull SystemChromeStyle systemUiOverlayStyle);

    /**
     * The Flutter application would like to pop the top item off of the Android
     * app's navigation back stack.
     */
    void popSystemNavigator();

    /**
     * The Flutter application would like to receive the current data in the
     * clipboard and have it returned in the given {@code format}.
     */
    @Nullable
    CharSequence getClipboardData(@Nullable ClipboardContentFormat format);

    /**
     * The Flutter application would like to set the current data in the
     * clipboard to the given {@code text}.
     */
    void setClipboardData(@NonNull String text);

    /**
     * The Flutter application would like to get the system gesture exclusion
     * rects.
     */
    List<Rect> getSystemGestureExclusionRects();

    /**
     * The Flutter application would like to set the system gesture exclusion
     * rects through the given {@code rects}.
     */
    void setSystemGestureExclusionRects(@NonNull ArrayList<Rect> rects);
  }

  /**
   * Types of sounds the Android OS can play on behalf of an application.
   */
  public enum SoundType {
    CLICK("SystemSoundType.click");

    @NonNull
    static SoundType fromValue(@NonNull String encodedName) throws NoSuchFieldException {
      for (SoundType soundType : SoundType.values()) {
        if (soundType.encodedName.equals(encodedName)) {
          return soundType;
        }
      }
      throw new NoSuchFieldException("No such SoundType: " + encodedName);
    }

    @NonNull
    private final String encodedName;

    SoundType(@NonNull String encodedName) {
      this.encodedName = encodedName;
    }
  }

  /**
   * The types of haptic feedback that the Android OS can generate on behalf
   * of an application.
   */
  public enum HapticFeedbackType {
    STANDARD(null),
    LIGHT_IMPACT("HapticFeedbackType.lightImpact"),
    MEDIUM_IMPACT("HapticFeedbackType.mediumImpact"),
    HEAVY_IMPACT("HapticFeedbackType.heavyImpact"),
    SELECTION_CLICK("HapticFeedbackType.selectionClick");

    @NonNull
    static HapticFeedbackType fromValue(@Nullable String encodedName) throws NoSuchFieldException {
      for (HapticFeedbackType feedbackType : HapticFeedbackType.values()) {
        if ((feedbackType.encodedName == null && encodedName == null)
            || (feedbackType.encodedName != null && feedbackType.encodedName.equals(encodedName))) {
          return feedbackType;
        }
      }
      throw new NoSuchFieldException("No such HapticFeedbackType: " + encodedName);
    }

    @Nullable
    private final String encodedName;

    HapticFeedbackType(@Nullable String encodedName) {
      this.encodedName = encodedName;
    }
  }

  /**
   * The possible desired orientations of a Flutter application.
   */
  public enum DeviceOrientation {
    PORTRAIT_UP("DeviceOrientation.portraitUp"),
    PORTRAIT_DOWN("DeviceOrientation.portraitDown"),
    LANDSCAPE_LEFT("DeviceOrientation.landscapeLeft"),
    LANDSCAPE_RIGHT("DeviceOrientation.landscapeRight");

    @NonNull
    static DeviceOrientation fromValue(@NonNull String encodedName) throws NoSuchFieldException {
      for (DeviceOrientation orientation : DeviceOrientation.values()) {
        if (orientation.encodedName.equals(encodedName)) {
          return orientation;
        }
      }
      throw new NoSuchFieldException("No such DeviceOrientation: " + encodedName);
    }

    @NonNull
    private String encodedName;

    DeviceOrientation(@NonNull String encodedName) {
      this.encodedName = encodedName;
    }
  }

  /**
   * The set of Android system UI overlays as perceived by the Flutter application.
   * <p>
   * Android includes many more overlay options and flags than what is provided by
   * {@code SystemUiOverlay}. Flutter only requires control over a subset of the
   * overlays and those overlays are represented by {@code SystemUiOverlay} values.
   */
  public enum SystemUiOverlay {
    TOP_OVERLAYS("SystemUiOverlay.top"),
    BOTTOM_OVERLAYS("SystemUiOverlay.bottom");

    @NonNull
    static SystemUiOverlay fromValue(@NonNull String encodedName) throws NoSuchFieldException {
      for (SystemUiOverlay overlay : SystemUiOverlay.values()) {
        if (overlay.encodedName.equals(encodedName)) {
          return overlay;
        }
      }
      throw new NoSuchFieldException("No such SystemUiOverlay: " + encodedName);
    }

    @NonNull
    private String encodedName;

    SystemUiOverlay(@NonNull String encodedName) {
      this.encodedName = encodedName;
    }
  }

  /**
   * The color and label of an application that appears in Android's app switcher, AKA
   * recents screen.
   */
  public static class AppSwitcherDescription {
    // TODO(mattcarroll): add color annotation
    public final int color;
    @NonNull
    public final String label;

    public AppSwitcherDescription(int color, @NonNull String label) {
      this.color = color;
      this.label = label;
    }
  }

  /**
   * The color and brightness of system chrome, e.g., status bar and system navigation bar.
   */
  public static class SystemChromeStyle {
    // TODO(mattcarroll): add color annotation
    @Nullable
    public final Integer statusBarColor;
    @Nullable
    public final Brightness statusBarIconBrightness;
    // TODO(mattcarroll): add color annotation
    @Nullable
    public final Integer systemNavigationBarColor;
    @Nullable
    public final Brightness systemNavigationBarIconBrightness;
    // TODO(mattcarroll): add color annotation
    @Nullable
    public final Integer systemNavigationBarDividerColor;

    public SystemChromeStyle(
        @Nullable Integer statusBarColor,
        @Nullable Brightness statusBarIconBrightness,
        @Nullable Integer systemNavigationBarColor,
        @Nullable Brightness systemNavigationBarIconBrightness,
        @Nullable Integer systemNavigationBarDividerColor
    ) {
      this.statusBarColor = statusBarColor;
      this.statusBarIconBrightness = statusBarIconBrightness;
      this.systemNavigationBarColor = systemNavigationBarColor;
      this.systemNavigationBarIconBrightness = systemNavigationBarIconBrightness;
      this.systemNavigationBarDividerColor = systemNavigationBarDividerColor;
    }
  }

  public enum Brightness {
    LIGHT("Brightness.light"),
    DARK("Brightness.dark");

    @NonNull
    static Brightness fromValue(@NonNull String encodedName) throws NoSuchFieldException {
      for (Brightness brightness : Brightness.values()) {
        if (brightness.encodedName.equals(encodedName)) {
          return brightness;
        }
      }
      throw new NoSuchFieldException("No such Brightness: " + encodedName);
    }

    @NonNull
    private String encodedName;

    Brightness(@NonNull String encodedName) {
      this.encodedName = encodedName;
    }
  }

  /**
   * Data formats of clipboard content.
   */
  public enum ClipboardContentFormat {
    PLAIN_TEXT("text/plain");

    @NonNull
    static ClipboardContentFormat fromValue(@NonNull String encodedName) throws NoSuchFieldException {
      for (ClipboardContentFormat format : ClipboardContentFormat.values()) {
        if (format.encodedName.equals(encodedName)) {
          return format;
        }
      }
      throw new NoSuchFieldException("No such ClipboardContentFormat: " + encodedName);
    }

    @NonNull
    private String encodedName;

    ClipboardContentFormat(@NonNull String encodedName) {
      this.encodedName = encodedName;
    }
  }
}

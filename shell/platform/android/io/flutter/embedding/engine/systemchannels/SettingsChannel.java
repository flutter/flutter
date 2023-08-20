package io.flutter.embedding.engine.systemchannels;

import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;
import java.util.HashMap;
import java.util.Map;

public class SettingsChannel {
  private static final String TAG = "SettingsChannel";

  public static final String CHANNEL_NAME = "flutter/settings";
  private static final String TEXT_SCALE_FACTOR = "textScaleFactor";
  private static final String NATIVE_SPELL_CHECK_SERVICE_DEFINED = "nativeSpellCheckServiceDefined";
  private static final String BRIEFLY_SHOW_PASSWORD = "brieflyShowPassword";
  private static final String ALWAYS_USE_24_HOUR_FORMAT = "alwaysUse24HourFormat";
  private static final String PLATFORM_BRIGHTNESS = "platformBrightness";

  @NonNull public final BasicMessageChannel<Object> channel;

  public SettingsChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new BasicMessageChannel<>(dartExecutor, CHANNEL_NAME, JSONMessageCodec.INSTANCE);
  }

  @NonNull
  public MessageBuilder startMessage() {
    return new MessageBuilder(channel);
  }

  public static class MessageBuilder {
    @NonNull private final BasicMessageChannel<Object> channel;
    @NonNull private Map<String, Object> message = new HashMap<>();

    MessageBuilder(@NonNull BasicMessageChannel<Object> channel) {
      this.channel = channel;
    }

    @NonNull
    public MessageBuilder setTextScaleFactor(float textScaleFactor) {
      message.put(TEXT_SCALE_FACTOR, textScaleFactor);
      return this;
    }

    @NonNull
    public MessageBuilder setNativeSpellCheckServiceDefined(
        boolean nativeSpellCheckServiceDefined) {
      message.put(NATIVE_SPELL_CHECK_SERVICE_DEFINED, nativeSpellCheckServiceDefined);
      return this;
    }

    @NonNull
    public MessageBuilder setBrieflyShowPassword(@NonNull boolean brieflyShowPassword) {
      message.put(BRIEFLY_SHOW_PASSWORD, brieflyShowPassword);
      return this;
    }

    @NonNull
    public MessageBuilder setUse24HourFormat(boolean use24HourFormat) {
      message.put(ALWAYS_USE_24_HOUR_FORMAT, use24HourFormat);
      return this;
    }

    @NonNull
    public MessageBuilder setPlatformBrightness(@NonNull PlatformBrightness brightness) {
      message.put(PLATFORM_BRIGHTNESS, brightness.name);
      return this;
    }

    public void send() {
      Log.v(
          TAG,
          "Sending message: \n"
              + "textScaleFactor: "
              + message.get(TEXT_SCALE_FACTOR)
              + "\n"
              + "alwaysUse24HourFormat: "
              + message.get(ALWAYS_USE_24_HOUR_FORMAT)
              + "\n"
              + "platformBrightness: "
              + message.get(PLATFORM_BRIGHTNESS));
      channel.send(message);
    }
  }

  /**
   * The brightness mode of the host platform.
   *
   * <p>The {@code name} property is the serialized representation of each brightness mode when
   * communicated via message channel.
   */
  public enum PlatformBrightness {
    light("light"),
    dark("dark");

    @NonNull public String name;

    PlatformBrightness(@NonNull String name) {
      this.name = name;
    }
  }
}

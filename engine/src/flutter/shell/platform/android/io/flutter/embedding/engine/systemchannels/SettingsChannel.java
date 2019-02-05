package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;

import java.util.HashMap;
import java.util.Map;

public class SettingsChannel {
  public static final String CHANNEL_NAME = "flutter/settings";
  
  public final BasicMessageChannel<Object> channel;
  
  public SettingsChannel(@NonNull DartExecutor dartExecutor) {
    this.channel = new BasicMessageChannel<>(dartExecutor, CHANNEL_NAME, JSONMessageCodec.INSTANCE);
  }
  
  public MessageBuilder startMessage() {
    return new MessageBuilder(channel);
  }
  
  public static class MessageBuilder {
    private final BasicMessageChannel<Object> channel;
    private Map<String, Object> message = new HashMap<>();
    
    MessageBuilder(@NonNull BasicMessageChannel<Object> channel) {
      this.channel = channel;
    }
    
    public MessageBuilder setTextScaleFactor(float textScaleFactor) {
      message.put("textScaleFactor", textScaleFactor);
      return this;
    }
    
    public MessageBuilder setUse24HourFormat(boolean use24HourFormat) {
      message.put("alwaysUse24HourFormat", use24HourFormat);
      return this;
    }
    
    public MessageBuilder setPlatformBrightness(@NonNull PlatformBrightness brightness) {
      message.put("platformBrightness", brightness.name);
      return this;
    }
    
    public void send() {
      channel.send(message);
    }
  }
  
  /**
   * The brightness mode of the host platform.
   *
   * The {@code name} property is the serialized representation of each
   * brightness mode when communicated via message channel.
   */
  public enum PlatformBrightness {
    light("light"),
    dark("dark");
    
    public String name;
    
    PlatformBrightness(@NonNull String name) {
      this.name = name;
    }
  }
}
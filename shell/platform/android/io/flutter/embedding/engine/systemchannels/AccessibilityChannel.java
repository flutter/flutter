package io.flutter.embedding.engine.systemchannels;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import java.util.HashMap;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StandardMessageCodec;

/**
 * System channel that sends accessibility requests and events from Flutter to Android.
 * <p>
 * See {@link AccessibilityMessageHandler}, which lists all accessibility requests and
 * events that might be sent from Flutter to the Android platform.
 */
public class AccessibilityChannel {
  @NonNull
  public BasicMessageChannel<Object> channel;
  @Nullable
  private AccessibilityMessageHandler handler;

  private final BasicMessageChannel.MessageHandler<Object> parsingMessageHandler = new BasicMessageChannel.MessageHandler<Object>() {
    @Override
    public void onMessage(Object message, BasicMessageChannel.Reply<Object> reply) {
      // If there is no handler to respond to this message then we don't need to
      // parse it. Return.
      if (handler == null) {
        return;
      }

      @SuppressWarnings("unchecked")
      final HashMap<String, Object> annotatedEvent = (HashMap<String, Object>) message;
      final String type = (String) annotatedEvent.get("type");
      @SuppressWarnings("unchecked")
      final HashMap<String, Object> data = (HashMap<String, Object>) annotatedEvent.get("data");

      switch (type) {
        case "announce":
          String announceMessage = (String) data.get("message");
          if (announceMessage != null) {
            handler.announce(announceMessage);
          }
          break;
        case "tap": {
          Integer nodeId = (Integer) annotatedEvent.get("nodeId");
          if (nodeId != null) {
            handler.onTap(nodeId);
          }
          break;
        }
        case "longPress": {
          Integer nodeId = (Integer) annotatedEvent.get("nodeId");
          if (nodeId != null) {
            handler.onLongPress(nodeId);
          }
          break;
        }
        case "tooltip": {
          String tooltipMessage = (String) data.get("message");
          if (tooltipMessage != null) {
            handler.onTooltip(tooltipMessage);
          }
          break;
        }
      }
    }
  };

  /**
   * Constructs an {@code AccessibilityChannel} that connects Android to the Dart code
   * running in {@code dartExecutor}.
   *
   * The given {@code dartExecutor} is permitted to be idle or executing code.
   *
   * See {@link DartExecutor}.
   */
  public AccessibilityChannel(@NonNull DartExecutor dartExecutor) {
    channel = new BasicMessageChannel<>(dartExecutor, "flutter/accessibility", StandardMessageCodec.INSTANCE);
    channel.setMessageHandler(parsingMessageHandler);
  }

  /**
   * Sets the {@link AccessibilityMessageHandler} which receives all events and requests
   * that are parsed from the underlying accessibility channel.
   */
  public void setAccessibilityMessageHandler(@Nullable AccessibilityMessageHandler handler) {
    this.handler = handler;
  }

  /**
   * Handler that receives accessibility messages sent from Flutter to Android
   * through a given {@link AccessibilityChannel}.
   *
   * To register an {@code AccessibilityMessageHandler} with a {@link AccessibilityChannel},
   * see {@link AccessibilityChannel#setAccessibilityMessageHandler(AccessibilityMessageHandler)}.
   */
  public interface AccessibilityMessageHandler {
    /**
     * The Dart application would like the given {@code message} to be announced.
     */
    void announce(@NonNull String message);

    /**
     * The user has tapped on the widget with the given {@code nodeId}.
     */
    void onTap(int nodeId);

    /**
     * The user has long pressed on the widget with the given {@code nodeId}.
     */
    void onLongPress(int nodeId);

    /**
     * The user has opened a tooltip.
     */
    void onTooltip(@NonNull String message);
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import android.os.Build;
import android.view.InputDevice;
import android.view.KeyEvent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import java.util.HashMap;
import java.util.Map;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Event message channel for key events to/from the Flutter framework.
 *
 * <p>Sends key up/down events to the framework, and receives asynchronous messages from the
 * framework about whether or not the key was handled.
 */
public class KeyEventChannel {
  private static final String TAG = "KeyEventChannel";

  /**
   * Sets the event response handler to be used to receive key event response messages from the
   * framework on this channel.
   */
  public void setEventResponseHandler(EventResponseHandler handler) {
    this.eventResponseHandler = handler;
  }

  private EventResponseHandler eventResponseHandler;

  /** A handler of incoming key handling messages. */
  public interface EventResponseHandler {

    /**
     * Called whenever the framework responds that a given key event was handled by the framework.
     *
     * @param event the event to be marked as being handled by the framework. Must not be null.
     */
    public void onKeyEventHandled(KeyEvent event);

    /**
     * Called whenever the framework responds that a given key event wasn't handled by the
     * framework.
     *
     * @param event the event to be marked as not being handled by the framework. Must not be null.
     */
    public void onKeyEventNotHandled(KeyEvent event);
  }

  /**
   * A constructor that creates a KeyEventChannel with the default message handler.
   *
   * @param binaryMessenger the binary messenger used to send messages on this channel.
   */
  public KeyEventChannel(@NonNull BinaryMessenger binaryMessenger) {
    this.channel =
        new BasicMessageChannel<>(binaryMessenger, "flutter/keyevent", JSONMessageCodec.INSTANCE);
  }

  /**
   * Creates a reply handler for the given key event.
   *
   * @param event the Android key event to create a reply for.
   */
  BasicMessageChannel.Reply<Object> createReplyHandler(KeyEvent event) {
    return message -> {
      if (eventResponseHandler == null) {
        return;
      }

      try {
        if (message == null) {
          eventResponseHandler.onKeyEventNotHandled(event);
          return;
        }
        final JSONObject annotatedEvent = (JSONObject) message;
        final boolean handled = annotatedEvent.getBoolean("handled");
        if (handled) {
          eventResponseHandler.onKeyEventHandled(event);
        } else {
          eventResponseHandler.onKeyEventNotHandled(event);
        }
      } catch (JSONException e) {
        Log.e(TAG, "Unable to unpack JSON message: " + e);
        eventResponseHandler.onKeyEventNotHandled(event);
      }
    };
  }

  @NonNull public final BasicMessageChannel<Object> channel;

  public void keyUp(@NonNull FlutterKeyEvent keyEvent) {
    Map<String, Object> message = new HashMap<>();
    message.put("type", "keyup");
    message.put("keymap", "android");
    encodeKeyEvent(keyEvent, message);

    channel.send(message, createReplyHandler(keyEvent.event));
  }

  public void keyDown(@NonNull FlutterKeyEvent keyEvent) {
    Map<String, Object> message = new HashMap<>();
    message.put("type", "keydown");
    message.put("keymap", "android");
    encodeKeyEvent(keyEvent, message);

    channel.send(message, createReplyHandler(keyEvent.event));
  }

  private void encodeKeyEvent(
      @NonNull FlutterKeyEvent keyEvent, @NonNull Map<String, Object> message) {
    message.put("flags", keyEvent.event.getFlags());
    message.put("plainCodePoint", keyEvent.event.getUnicodeChar(0x0));
    message.put("codePoint", keyEvent.event.getUnicodeChar());
    message.put("keyCode", keyEvent.event.getKeyCode());
    message.put("scanCode", keyEvent.event.getScanCode());
    message.put("metaState", keyEvent.event.getMetaState());
    if (keyEvent.complexCharacter != null) {
      message.put("character", keyEvent.complexCharacter.toString());
    }
    message.put("source", keyEvent.event.getSource());
    InputDevice device = InputDevice.getDevice(keyEvent.event.getDeviceId());
    int vendorId = 0;
    int productId = 0;
    if (device != null) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
        vendorId = device.getVendorId();
        productId = device.getProductId();
      }
    }
    message.put("vendorId", vendorId);
    message.put("productId", productId);
    message.put("deviceId", keyEvent.event.getDeviceId());
    message.put("repeatCount", keyEvent.event.getRepeatCount());
  }

  /** A key event as defined by Flutter. */
  public static class FlutterKeyEvent {
    /**
     * The Android key event that this Flutter key event was created from.
     *
     * <p>This event is used to identify pending events when results are received from the
     * framework.
     */
    public final KeyEvent event;
    /**
     * The character produced by this event, including any combining characters pressed before it.
     */
    @Nullable public final Character complexCharacter;

    public FlutterKeyEvent(@NonNull KeyEvent androidKeyEvent) {
      this(androidKeyEvent, null);
    }

    public FlutterKeyEvent(
        @NonNull KeyEvent androidKeyEvent, @Nullable Character complexCharacter) {
      this.event = androidKeyEvent;
      this.complexCharacter = complexCharacter;
    }
  }
}

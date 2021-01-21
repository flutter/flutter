// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.view.KeyCharacterMap;
import android.view.KeyEvent;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.Log;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.plugin.editing.TextInputPlugin;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;

/**
 * A class to process key events from Android, passing them to the framework as messages using
 * {@link KeyEventChannel}.
 *
 * <p>A class that sends Android key events to the framework, and re-dispatches those not handled by
 * the framework.
 *
 * <p>Flutter uses asynchronous event handling to avoid blocking the UI thread, but Android requires
 * that events are handled synchronously. So, when a key event is received by Flutter, it tells
 * Android synchronously that the key has been handled so that it won't propagate to other
 * components. Flutter then uses "delayed event synthesis", where it sends the event to the
 * framework, and if the framework responds that it has not handled the event, then this class
 * synthesizes a new event to send to Android, without handling it this time.
 */
public class AndroidKeyProcessor {
  private static final String TAG = "AndroidKeyProcessor";

  @NonNull private final KeyEventChannel keyEventChannel;
  @NonNull private final TextInputPlugin textInputPlugin;
  private int combiningCharacter;
  @NonNull private EventResponder eventResponder;

  /**
   * Constructor for AndroidKeyProcessor.
   *
   * <p>The view is used as the destination to send the synthesized key to. This means that the the
   * next thing in the focus chain will get the event when the framework returns false from
   * onKeyDown/onKeyUp
   *
   * <p>It is possible that that in the middle of the async round trip, the focus chain could
   * change, and instead of the native widget that was "next" when the event was fired getting the
   * event, it may be the next widget when the event is synthesized that gets it. In practice, this
   * shouldn't be a huge problem, as this is an unlikely occurrence to happen without user input,
   * and it may actually be desired behavior, but it is possible.
   *
   * @param view takes the activity to use for re-dispatching of events that were not handled by the
   *     framework.
   * @param keyEventChannel the event channel to listen to for new key events.
   * @param textInputPlugin a plugin, which, if set, is given key events before the framework is,
   *     and if it has a valid input connection and is accepting text, then it will handle the event
   *     and the framework will not receive it.
   */
  public AndroidKeyProcessor(
      @NonNull View view,
      @NonNull KeyEventChannel keyEventChannel,
      @NonNull TextInputPlugin textInputPlugin) {
    this.keyEventChannel = keyEventChannel;
    this.textInputPlugin = textInputPlugin;
    textInputPlugin.setKeyEventProcessor(this);
    this.eventResponder = new EventResponder(view, textInputPlugin);
    this.keyEventChannel.setEventResponseHandler(eventResponder);
  }

  /**
   * Detaches the key processor from the Flutter engine.
   *
   * <p>The AndroidKeyProcessor instance should not be used after calling this.
   */
  public void destroy() {
    keyEventChannel.setEventResponseHandler(null);
  }

  /**
   * Called when a key event is received by the {@link FlutterView} or the {@link
   * InputConnectionAdaptor}.
   *
   * @param keyEvent the Android key event to respond to.
   * @return true if the key event should not be propagated to other Android components. Delayed
   *     synthesis events will return false, so that other components may handle them.
   */
  public boolean onKeyEvent(@NonNull KeyEvent keyEvent) {
    int action = keyEvent.getAction();
    if (action != KeyEvent.ACTION_DOWN && action != KeyEvent.ACTION_UP) {
      // There is theoretically a KeyEvent.ACTION_MULTIPLE, but theoretically
      // that isn't sent by Android anymore, so this is just for protection in
      // case the theory is wrong.
      return false;
    }
    if (isPendingEvent(keyEvent)) {
      // If the keyEvent is in the queue of pending events we've seen, and has
      // the same id, then we know that this is a re-dispatched keyEvent, and we
      // shouldn't respond to it, but we should remove it from tracking now.
      eventResponder.removePendingEvent(keyEvent);
      return false;
    }

    Character complexCharacter = applyCombiningCharacterToBaseCharacter(keyEvent.getUnicodeChar());
    KeyEventChannel.FlutterKeyEvent flutterEvent =
        new KeyEventChannel.FlutterKeyEvent(keyEvent, complexCharacter);

    eventResponder.addEvent(keyEvent);
    if (action == KeyEvent.ACTION_DOWN) {
      keyEventChannel.keyDown(flutterEvent);
    } else {
      keyEventChannel.keyUp(flutterEvent);
    }
    return true;
  }

  /**
   * Returns whether or not the given event is currently being processed by this key processor. This
   * is used to determine if a new key event sent to the {@link InputConnectionAdaptor} originates
   * from a hardware key event, or a soft keyboard editing event.
   *
   * @param event the event to check for being the current event.
   * @return
   */
  public boolean isPendingEvent(@NonNull KeyEvent event) {
    return eventResponder.findPendingEvent(event) != null;
  }

  /**
   * Applies the given Unicode character in {@code newCharacterCodePoint} to a previously entered
   * Unicode combining character and returns the combination of these characters if a combination
   * exists.
   *
   * <p>This method mutates {@link #combiningCharacter} over time to combine characters.
   *
   * <p>One of the following things happens in this method:
   *
   * <ul>
   *   <li>If no previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint}
   *       is not a combining character, then {@code newCharacterCodePoint} is returned.
   *   <li>If no previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint}
   *       is a combining character, then {@code newCharacterCodePoint} is saved as the {@link
   *       #combiningCharacter} and null is returned.
   *   <li>If a previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint} is
   *       also a combining character, then the {@code newCharacterCodePoint} is combined with the
   *       existing {@link #combiningCharacter} and null is returned.
   *   <li>If a previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint} is
   *       not a combining character, then the {@link #combiningCharacter} is applied to the regular
   *       {@code newCharacterCodePoint} and the resulting complex character is returned. The {@link
   *       #combiningCharacter} is cleared.
   * </ul>
   *
   * <p>The following reference explains the concept of a "combining character":
   * https://en.wikipedia.org/wiki/Combining_character
   */
  @Nullable
  private Character applyCombiningCharacterToBaseCharacter(int newCharacterCodePoint) {
    if (newCharacterCodePoint == 0) {
      return null;
    }

    char complexCharacter = (char) newCharacterCodePoint;
    boolean isNewCodePointACombiningCharacter =
        (newCharacterCodePoint & KeyCharacterMap.COMBINING_ACCENT) != 0;
    if (isNewCodePointACombiningCharacter) {
      // If a combining character was entered before, combine this one with that one.
      int plainCodePoint = newCharacterCodePoint & KeyCharacterMap.COMBINING_ACCENT_MASK;
      if (combiningCharacter != 0) {
        combiningCharacter = KeyCharacterMap.getDeadChar(combiningCharacter, plainCodePoint);
      } else {
        combiningCharacter = plainCodePoint;
      }
    } else {
      // The new character is a regular character. Apply combiningCharacter to it, if
      // it exists.
      if (combiningCharacter != 0) {
        int combinedChar = KeyCharacterMap.getDeadChar(combiningCharacter, newCharacterCodePoint);
        if (combinedChar > 0) {
          complexCharacter = (char) combinedChar;
        }
        combiningCharacter = 0;
      }
    }

    return complexCharacter;
  }

  private static class EventResponder implements KeyEventChannel.EventResponseHandler {
    // The maximum number of pending events that are held before starting to
    // complain.
    private static final long MAX_PENDING_EVENTS = 1000;
    final Deque<KeyEvent> pendingEvents = new ArrayDeque<KeyEvent>();
    @NonNull private final View view;
    @NonNull private final TextInputPlugin textInputPlugin;

    public EventResponder(@NonNull View view, @NonNull TextInputPlugin textInputPlugin) {
      this.view = view;
      this.textInputPlugin = textInputPlugin;
    }

    /** Removes the first pending event from the cache of pending events. */
    private void removePendingEvent(KeyEvent event) {
      pendingEvents.remove(event);
    }

    private KeyEvent findPendingEvent(KeyEvent event) {
      Iterator<KeyEvent> iter = pendingEvents.iterator();
      while (iter.hasNext()) {
        KeyEvent item = iter.next();
        if (item == event) {
          return item;
        }
      }
      return null;
    }

    /**
     * Called whenever the framework responds that a given key event was handled by the framework.
     *
     * @param event the event to be marked as being handled by the framework. Must not be null.
     */
    @Override
    public void onKeyEventHandled(KeyEvent event) {
      removePendingEvent(event);
    }

    /**
     * Called whenever the framework responds that a given key event wasn't handled by the
     * framework.
     *
     * @param event the event to be marked as not being handled by the framework. Must not be null.
     */
    @Override
    public void onKeyEventNotHandled(KeyEvent event) {
      redispatchKeyEvent(findPendingEvent(event));
    }

    /** Adds an Android key event to the event responder to wait for a response. */
    public void addEvent(@NonNull KeyEvent event) {
      pendingEvents.addLast(event);
      if (pendingEvents.size() > MAX_PENDING_EVENTS) {
        Log.e(
            TAG,
            "There are "
                + pendingEvents.size()
                + " keyboard events that have not yet received a response. Are responses being "
                + "sent?");
      }
    }

    /**
     * Dispatches the event to the activity associated with the context.
     *
     * @param event the event to be dispatched to the activity.
     */
    private void redispatchKeyEvent(KeyEvent event) {
      // If the textInputPlugin is still valid and accepting text, then we'll try
      // and send the key event to it, assuming that if the event can be sent,
      // that it has been handled.
      if (textInputPlugin.getInputMethodManager().isAcceptingText()
          && textInputPlugin.getLastInputConnection() != null
          && textInputPlugin.getLastInputConnection().sendKeyEvent(event)) {
        // The event was handled, so we can remove it from the queue.
        removePendingEvent(event);
        return;
      }

      // Since the framework didn't handle it, dispatch the event again.
      if (view != null) {
        view.getRootView().dispatchKeyEvent(event);
      }
    }
  }
}

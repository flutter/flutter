// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.view.KeyEvent;
import android.view.View;
import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.android.KeyboardManager.Responder.OnKeyEventHandledCallback;
import io.flutter.plugin.editing.TextInputPlugin;
import java.util.HashSet;

/**
 * A class to process {@link KeyEvent}s dispatched to a {@link FlutterView}, either from a hardware
 * keyboard or an IME event.
 *
 * <p>A class that sends Android {@link KeyEvent} to the a list of {@link
 * KeyboardManager.Responder}s, and re-dispatches those not handled by the primary responders.
 *
 * <p>Flutter uses asynchronous event handling to avoid blocking the UI thread, but Android requires
 * that events are handled synchronously. So, when the Android system sends new @{link KeyEvent} to
 * Flutter, Flutter responds synchronously that the key has been handled so that it won't propagate
 * to other components. It then uses "delayed event synthesis", where it sends the event to the
 * framework, and if the framework responds that it has not handled the event, then this class
 * synthesizes a new event to send to Android, without handling it this time.
 *
 * <p>A new {@link KeyEvent} sent to a {@link KeyboardManager} can be propagated to 3 different
 * types of responders (in the listed order):
 *
 * <ul>
 *   <li>{@link KeyboardManager.Responder}s: An immutable list of key responders in a {@link
 *       KeyboardManager} that each implements the {@link KeyboardManager.Responder} interface. A
 *       {@link KeyboardManager.Responder} is a key responder that's capable of handling {@link
 *       KeyEvent}s asynchronously.
 *       <p>When a new {@link KeyEvent} is received, {@link KeyboardManager} calls the {@link
 *       KeyboardManager.Responder#handleEvent(KeyEvent, OnKeyEventHandledCallback)} method on its
 *       {@link KeyboardManager.Responder}s. Each {@link KeyboardManager.Responder} must call the
 *       supplied {@link OnKeyEventHandledCallback} exactly once, when it has decided whether to
 *       handle the key event callback. More than one {@link KeyboardManager.Responder} is allowed
 *       to reply true and handle the same {@link KeyEvent}.
 *       <p>Typically a {@link KeyboardManager} uses a {@link KeyChannelResponder} as its only
 *       {@link KeyboardManager.Responder}.
 *   <li>{@link TextInputPlugin}: if every {@link KeyboardManager.Responder} has replied false to a
 *       {@link KeyEvent}, or if the {@link KeyboardManager} has zero {@link
 *       KeyboardManager.Responder}s, the {@link KeyEvent} will be sent to the currently focused
 *       editable text field in {@link TextInputPlugin}, if any.
 *   <li><b>"Redispatch"</b>: if there's no currently focused text field in {@link TextInputPlugin},
 *       or the text field does not handle the {@link KeyEvent} either, the {@link KeyEvent} will be
 *       sent back to the top of the activity's view hierachy, allowing it to be "redispatched",
 *       only this time the {@link KeyboardManager} will not try to handle the redispatched {@link
 *       KeyEvent}.
 * </ul>
 */
public class KeyboardManager {
  private static final String TAG = "KeyboardManager";

  /**
   * Constructor for {@link KeyboardManager} that takes a list of {@link
   * KeyboardManager.Responder}s.
   *
   * <p>The view is used as the destination to send the synthesized key to. This means that the the
   * next thing in the focus chain will get the event when the {@link KeyboardManager.Responder}s
   * return false from onKeyDown/onKeyUp.
   *
   * <p>It is possible that that in the middle of the async round trip, the focus chain could
   * change, and instead of the native widget that was "next" when the event was fired getting the
   * event, it may be the next widget when the event is synthesized that gets it. In practice, this
   * shouldn't be a huge problem, as this is an unlikely occurrence to happen without user input,
   * and it may actually be desired behavior, but it is possible.
   *
   * @param view takes the activity to use for re-dispatching of events that were not handled by the
   *     framework.
   * @param textInputPlugin a plugin, which, if set, is given key events before the framework is,
   *     and if it has a valid input connection and is accepting text, then it will handle the event
   *     and the framework will not receive it.
   * @param responders the {@link KeyboardManager.Responder}s new {@link KeyEvent}s will be first
   *     dispatched to.
   */
  public KeyboardManager(
      View view, @NonNull TextInputPlugin textInputPlugin, Responder[] responders) {
    this.view = view;
    this.textInputPlugin = textInputPlugin;
    this.responders = responders;
  }

  /**
   * The interface for responding to a {@link KeyEvent} asynchronously.
   *
   * <p>Implementers of this interface should be owned by a {@link KeyboardManager}, in order to
   * receive key events.
   *
   * <p>After receiving a {@link KeyEvent}, the {@link Responder} must call the supplied {@link
   * OnKeyEventHandledCallback} exactly once, to inform the {@link KeyboardManager} whether it
   * wishes to handle the {@link KeyEvent}. The {@link KeyEvent} will not be propagated to the
   * {@link TextInputPlugin} or be redispatched to the view hierachy if any key responders answered
   * yes.
   *
   * <p>If a {@link Responder} fails to call the {@link OnKeyEventHandledCallback} callback, the
   * {@link KeyEvent} will never be sent to the {@link TextInputPlugin}, and the {@link
   * KeyboardManager} class can't detect such errors as there is no timeout.
   */
  interface Responder {
    interface OnKeyEventHandledCallback {
      void onKeyEventHandled(Boolean canHandleEvent);
    }

    /**
     * Informs this {@link Responder} that a new {@link KeyEvent} needs processing.
     *
     * @param keyEvent the new {@link KeyEvent} this {@link Responder} may be interested in.
     * @param onKeyEventHandledCallback the method to call when this {@link Responder} has decided
     *     whether to handle the {@link KeyEvent}.
     */
    void handleEvent(
        @NonNull KeyEvent keyEvent, @NonNull OnKeyEventHandledCallback onKeyEventHandledCallback);
  }

  private class PerEventCallbackBuilder {
    private class Callback implements OnKeyEventHandledCallback {
      boolean isCalled = false;

      @Override
      public void onKeyEventHandled(Boolean canHandleEvent) {
        if (isCalled) {
          throw new IllegalStateException(
              "The onKeyEventHandledCallback should be called exactly once.");
        }
        isCalled = true;
        unrepliedCount -= 1;
        isEventHandled |= canHandleEvent;
        if (unrepliedCount == 0 && !isEventHandled) {
          onUnhandled(keyEvent);
        }
      }
    }

    PerEventCallbackBuilder(@NonNull KeyEvent keyEvent) {
      this.keyEvent = keyEvent;
    }

    @NonNull final KeyEvent keyEvent;
    int unrepliedCount = responders.length;
    boolean isEventHandled = false;

    public OnKeyEventHandledCallback buildCallback() {
      return new Callback();
    }
  }

  @NonNull protected final Responder[] responders;
  @NonNull private final HashSet<KeyEvent> redispatchedEvents = new HashSet<>();
  @NonNull private final TextInputPlugin textInputPlugin;
  private final View view;

  public boolean handleEvent(@NonNull KeyEvent keyEvent) {
    final boolean isRedispatchedEvent = redispatchedEvents.remove(keyEvent);
    if (isRedispatchedEvent) {
      return false;
    }

    if (responders.length > 0) {
      final PerEventCallbackBuilder callbackBuilder = new PerEventCallbackBuilder(keyEvent);
      for (final Responder primaryResponder : responders) {
        primaryResponder.handleEvent(keyEvent, callbackBuilder.buildCallback());
      }
    } else {
      onUnhandled(keyEvent);
    }

    return true;
  }

  public void destroy() {
    final int remainingRedispatchCount = redispatchedEvents.size();
    if (remainingRedispatchCount > 0) {
      Log.w(
          TAG,
          "A KeyboardManager was destroyed with "
              + String.valueOf(remainingRedispatchCount)
              + " unhandled redispatch event(s).");
    }
  }

  private void onUnhandled(@NonNull KeyEvent keyEvent) {
    if (textInputPlugin.handleKeyEvent(keyEvent) || view == null) {
      return;
    }

    redispatchedEvents.add(keyEvent);
    view.getRootView().dispatchKeyEvent(keyEvent);
    if (redispatchedEvents.remove(keyEvent)) {
      Log.w(TAG, "A redispatched key event was consumed before reaching KeyboardManager");
    }
  }
}

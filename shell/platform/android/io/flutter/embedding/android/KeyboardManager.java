// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.view.KeyEvent;
import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.editing.InputConnectionAdaptor;
import io.flutter.plugin.editing.TextInputPlugin;
import java.util.HashSet;

/**
 * Processes keyboard events and cooperate with {@link TextInputPlugin}.
 *
 * <p>Flutter uses asynchronous event handling to avoid blocking the UI thread, but Android requires
 * that events are handled synchronously. So when the Android system sends new @{link KeyEvent} to
 * Flutter, Flutter responds synchronously that the key has been handled so that it won't propagate
 * to other components. It then uses "delayed event synthesis", where it sends the event to the
 * framework, and if the framework responds that it has not handled the event, then this class
 * synthesizes a new event to send to Android, without handling it this time.
 *
 * <p>Flutter processes an Android {@link KeyEvent} with several components, each can choose whether
 * to handled the event, and only unhandled events can move to the next section.
 *
 * <ul>
 *   <li><b>Keyboard</b>: Dispatch to the {@link KeyboardManager.Responder}s simultaneously. After
 *       all responders have responded (asynchronously), the event is considered handled if any
 *       responders decide to handle.
 *   <li><b>Text input</b>: Events are sent to {@link TextInputPlugin}, processed synchronously with
 *       a result of whether it is handled.
 *   <li><b>"Redispatch"</b>: If there's no currently focused text field in {@link TextInputPlugin},
 *       or the text field does not handle the {@link KeyEvent} either, the {@link KeyEvent} will be
 *       sent back to the top of the activity's view hierachy, allowing it to be "redispatched". The
 *       {@link KeyboardManager} will remember this event and skip the identical event at the next
 *       encounter.
 * </ul>
 */
public class KeyboardManager implements InputConnectionAdaptor.KeyboardDelegate {
  private static final String TAG = "KeyboardManager";

  /**
   * Construct a {@link KeyboardManager}.
   *
   * @param viewDelegate provides a set of interfaces that the keyboard manager needs to interact
   *     with other components and the platform, and is typically implements by {@link FlutterView}.
   */
  public KeyboardManager(@NonNull ViewDelegate viewDelegate) {
    this.viewDelegate = viewDelegate;
    this.responders =
        new KeyChannelResponder[] {
          new KeyChannelResponder(new KeyEventChannel(viewDelegate.getBinaryMessenger())),
        };
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
  public interface Responder {
    interface OnKeyEventHandledCallback {
      void onKeyEventHandled(boolean canHandleEvent);
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

  /**
   * A set of interfaces that the {@link KeyboardManager} needs to interact with other components
   * and the platform, and is typically implements by {@link FlutterView}.
   */
  public interface ViewDelegate {
    /** Returns a {@link BinaryMessenger} to send platform messages with. */
    public BinaryMessenger getBinaryMessenger();

    /**
     * Send a {@link KeyEvent} that is not handled by the keyboard responders to the text input
     * system.
     *
     * @param keyEvent the {@link KeyEvent} that should be processed by the text input system. It
     *     must not be null.
     * @return Whether the text input handles the key event.
     */
    public boolean onTextInputKeyEvent(@NonNull KeyEvent keyEvent);

    /** Send a {@link KeyEvent} that is not handled by Flutter back to the platform. */
    public void redispatch(@NonNull KeyEvent keyEvent);
  }

  private class PerEventCallbackBuilder {
    private class Callback implements Responder.OnKeyEventHandledCallback {
      boolean isCalled = false;

      @Override
      public void onKeyEventHandled(boolean canHandleEvent) {
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

    final KeyEvent keyEvent;
    int unrepliedCount = responders.length;
    boolean isEventHandled = false;

    public Responder.OnKeyEventHandledCallback buildCallback() {
      return new Callback();
    }
  }

  protected final Responder[] responders;
  private final HashSet<KeyEvent> redispatchedEvents = new HashSet<>();
  private final ViewDelegate viewDelegate;

  @Override
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
    if (viewDelegate == null || viewDelegate.onTextInputKeyEvent(keyEvent)) {
      return;
    }

    redispatchedEvents.add(keyEvent);
    viewDelegate.redispatch(keyEvent);
    if (redispatchedEvents.remove(keyEvent)) {
      Log.w(TAG, "A redispatched key event was consumed before reaching KeyboardManager");
    }
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Handler;
import android.os.IBinder;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;

/**
 * A fake View only exposed to InputMethodManager.
 *
 * <p>This follows a similar flow to Chromium's WebView (see
 * https://cs.chromium.org/chromium/src/content/public/android/java/src/org/chromium/content/browser/input/ThreadedInputConnectionProxyView.java).
 * WebView itself bounces its InputConnection around several different threads. We follow its logic
 * here to get the same working connection.
 *
 * <p>This exists solely to forward input creation to WebView's ThreadedInputConnectionProxyView on
 * the IME thread. The way that this is created in {@link
 * InputAwareWebView#checkInputConnectionProxy} guarantees that we have a handle to
 * ThreadedInputConnectionProxyView and {@link #onCreateInputConnection} is always called on the IME
 * thread. We delegate to ThreadedInputConnectionProxyView there to get WebView's input connection.
 */
final class ThreadedInputConnectionProxyAdapterView extends View {
  final Handler imeHandler;
  final IBinder windowToken;
  final View containerView;
  final View rootView;
  final View targetView;

  private boolean triggerDelayed = true;
  private boolean isLocked = false;
  private InputConnection cachedConnection;

  ThreadedInputConnectionProxyAdapterView(View containerView, View targetView, Handler imeHandler) {
    super(containerView.getContext());
    this.imeHandler = imeHandler;
    this.containerView = containerView;
    this.targetView = targetView;
    windowToken = containerView.getWindowToken();
    rootView = containerView.getRootView();
    setFocusable(true);
    setFocusableInTouchMode(true);
    setVisibility(VISIBLE);
  }

  /** Returns whether or not this is currently asynchronously acquiring an input connection. */
  boolean isTriggerDelayed() {
    return triggerDelayed;
  }

  /** Sets whether or not this should use its previously cached input connection. */
  void setLocked(boolean locked) {
    isLocked = locked;
  }

  /**
   * This is expected to be called on the IME thread. See the setup required for this in {@link
   * InputAwareWebView#checkInputConnectionProxy(View)}.
   *
   * <p>Delegates to ThreadedInputConnectionProxyView to get WebView's input connection.
   */
  @Override
  public InputConnection onCreateInputConnection(final EditorInfo outAttrs) {
    triggerDelayed = false;
    InputConnection inputConnection =
        (isLocked) ? cachedConnection : targetView.onCreateInputConnection(outAttrs);
    triggerDelayed = true;
    cachedConnection = inputConnection;
    return inputConnection;
  }

  @Override
  public boolean checkInputConnectionProxy(View view) {
    return true;
  }

  @Override
  public boolean hasWindowFocus() {
    // None of our views here correctly report they have window focus because of how we're embedding
    // the platform view inside of a virtual display.
    return true;
  }

  @Override
  public View getRootView() {
    return rootView;
  }

  @Override
  public boolean onCheckIsTextEditor() {
    return true;
  }

  @Override
  public boolean isFocused() {
    return true;
  }

  @Override
  public IBinder getWindowToken() {
    return windowToken;
  }

  @Override
  public Handler getHandler() {
    return imeHandler;
  }
}

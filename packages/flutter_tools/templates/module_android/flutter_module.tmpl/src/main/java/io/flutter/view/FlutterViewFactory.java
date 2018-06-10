// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.Activity;
import android.arch.lifecycle.Lifecycle;
import android.arch.lifecycle.LifecycleObserver;
import android.arch.lifecycle.OnLifecycleEvent;
import android.content.Context;
import io.flutter.app.FlutterActivityDelegate;

import static android.arch.lifecycle.Lifecycle.State.CREATED;
import static android.arch.lifecycle.Lifecycle.State.DESTROYED;
import static android.arch.lifecycle.Lifecycle.State.RESUMED;
import static android.arch.lifecycle.Lifecycle.State.STARTED;

/**
 * Factory of Flutter views.
 */
public class FlutterViewFactory implements LifecycleObserver {
  private final Context context;
  private final Lifecycle lifecycle;

  public FlutterViewFactory(Context context, Lifecycle lifecycle) {
    this.context = context;
    this.lifecycle = lifecycle;
  }

  public FlutterViewHandle createFlutterView(final Activity activity, final String route) {
    if (lifecycle.getCurrentState() == DESTROYED) {
      throw new IllegalStateException("Cannot create view for destroyed lifecycle");
    }
    FlutterMain.ensureInitializationComplete(context, null);
    final FlutterActivityDelegate delegate = new FlutterActivityDelegate(activity, new FlutterActivityDelegate.ViewFactory() {
      @Override
      public FlutterView createFlutterView(Context context) {
        final FlutterNativeView nativeView = new FlutterNativeView(context);
        final FlutterView flutterView = new FlutterView(activity, null, nativeView);
        flutterView.setInitialRoute(route);
        return flutterView;
      }

      @Override
      public boolean retainFlutterNativeView() {
        return false;
      }

      @Override
      public FlutterNativeView createFlutterNativeView() {
        throw new UnsupportedOperationException();
      }
    });
    final FlutterViewHandle handle = new FlutterViewHandle(delegate);
    if (lifecycle.getCurrentState().isAtLeast(CREATED)) {
      handle.onCreate();
      if (lifecycle.getCurrentState().isAtLeast(STARTED)) {
        handle.onStart();
        if (lifecycle.getCurrentState().isAtLeast(RESUMED)) {
          handle.onResume();
        }
      }
    }
    return handle;
  }

  @OnLifecycleEvent(Lifecycle.Event.ON_CREATE)
  public void onCreate() {
    FlutterMain.startInitialization(context);
  }
}

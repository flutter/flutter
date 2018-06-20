package io.flutter.view;

import android.app.Activity;
import android.arch.lifecycle.Lifecycle;
import android.arch.lifecycle.LifecycleObserver;
import android.arch.lifecycle.OnLifecycleEvent;
import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.View;

import io.flutter.app.FlutterActivityDelegate;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Main entry point for using Flutter in Android applications.
 *
 * TODO(mravn): Move this file to the flutter/engine repo.
 */
public final class Flutter {
  private Flutter() {
    // to prevent instantiation
  }

  public static void startInitialization(Context applicationContext) {
    FlutterMain.startInitialization(applicationContext, null);
  }

  public static Fragment createFragment(String route) {
    final FlutterFragment fragment = new FlutterFragment();
    final Bundle args = new Bundle();
    args.putString(FlutterFragment.ARG_ROUTE, route);
    fragment.setArguments(args);
    return fragment;
  }

  public static View createView(final Activity activity, final Lifecycle lifecycle, final String route) {
    FlutterMain.startInitialization(activity.getApplicationContext());
    FlutterMain.ensureInitializationComplete(activity.getApplicationContext(), null);
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
    lifecycle.addObserver(new LifecycleObserver() {
      @OnLifecycleEvent(Lifecycle.Event.ON_CREATE)
      public void onCreate() {
        delegate.onCreate(null);
        GeneratedPluginRegistrant.registerWith(delegate);
      }

      @OnLifecycleEvent(Lifecycle.Event.ON_START)
      public void onStart() {
        delegate.onStart();
      }

      @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
      public void onResume() {
        delegate.onResume();
      }

      @OnLifecycleEvent(Lifecycle.Event.ON_PAUSE)
      public void onPause() {
        delegate.onPause();
      }

      @OnLifecycleEvent(Lifecycle.Event.ON_STOP)
      public void onStop() {
        delegate.onStop();
      }

      @OnLifecycleEvent(Lifecycle.Event.ON_DESTROY)
      public void onDestroy() {
        delegate.onDestroy();
      }
    });
    return delegate.getFlutterView();
  }
}

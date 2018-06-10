package io.flutter.view;

import android.arch.lifecycle.Lifecycle;
import android.arch.lifecycle.LifecycleObserver;
import android.arch.lifecycle.OnLifecycleEvent;
import android.view.View;

import io.flutter.app.FlutterActivityDelegate;
import io.flutter.plugins.GeneratedPluginRegistrant;

public final class FlutterViewHandle implements LifecycleObserver {
  private final FlutterActivityDelegate delegate;

  FlutterViewHandle(FlutterActivityDelegate delegate) {
    this.delegate = delegate;
  }

  public View view() {
    return delegate.getFlutterView();
  }

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
}

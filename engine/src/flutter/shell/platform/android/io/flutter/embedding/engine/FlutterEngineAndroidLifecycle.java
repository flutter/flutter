// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.arch.lifecycle.DefaultLifecycleObserver;
import android.arch.lifecycle.Lifecycle;
import android.arch.lifecycle.LifecycleObserver;
import android.arch.lifecycle.LifecycleOwner;
import android.arch.lifecycle.LifecycleRegistry;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

/**
 * Android {@link Lifecycle} that is owned by a {@link FlutterEngine}.
 * <p>
 * {@code FlutterEngineAndroidLifecycle} exists so that {@code FlutterPlugin}s can monitor Android
 * lifecycle events. When the associated {@link FlutterEngine} is running in an {@code Activity},
 * that {@code Activity}'s {@link Lifecycle} can be set as the {@code backingLifecycle} of this
 * class, allowing all Flutter plugins to receive the {@code Activity}'s lifecycle events. Likewise,
 * when the associated {@link FlutterEngine} is running in a {@code Service}, that {@code Service}'s
 * {@link Lifecycle} can be set as the {@code backingLifecycle}.
 * <p>
 * Sometimes a {@link FlutterEngine} exists in a non-lifecycle location, e.g., an {@code Application},
 * {@code ContentProvider}, or {@code BroadcastReceiver}. In these cases, this lifecycle reports
 * itself in the {@link Lifecycle.State#CREATED} state.
 * <p>
 * Regardless of what happens to a backing {@code Activity} or @{code Service}, this lifecycle
 * will only report itself as {@link Lifecycle.State#DESTROYED} when the associated {@link FlutterEngine}
 * itself is destroyed. This is because a {@link Lifecycle} is not allowed to emit any events after
 * going to the {@link Lifecycle.State#DESTROYED} state. Thus, this lifecycle cannot emit such an
 * event until its associated {@link FlutterEngine} is destroyed. This then begs the question, what
 * happens when the backing {@code Activity} or {@code Service} is destroyed? This lifecycle will
 * report the process up to the {@link Lifecycle.Event#ON_STOP} event, but will ignore the
 * {@link Lifecycle.Event#ON_DESTROY} event. At that point, this lifecycle will be back in its
 * default {@link Lifecycle.State#CREATED} state until some other backing {@link Lifecycle} is
 * registered.
 */
final class FlutterEngineAndroidLifecycle extends LifecycleRegistry {
  private static final String TAG = "FlutterEngineAndroidLifecycle";

  @Nullable
  private Lifecycle backingLifecycle;
  private boolean isDestroyed = false;

  @NonNull
  private final LifecycleObserver forwardingObserver = new DefaultLifecycleObserver() {
    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {
      // No-op. The FlutterEngine's Lifecycle is always at least Created
      // until it is Destroyed, so we ignore onCreate() events from
      // backing Lifecycles.
    }

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {
      handleLifecycleEvent(Event.ON_START);
    }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
      handleLifecycleEvent(Event.ON_RESUME);
    }

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {
      handleLifecycleEvent(Event.ON_PAUSE);
    }

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
      handleLifecycleEvent(Event.ON_STOP);
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
      // No-op. We don't allow FlutterEngine's Lifecycle to report destruction
      // until the FlutterEngine itself is destroyed. This is because a Lifecycle
      // is contractually obligated to send no more event once it gets to the
      // Destroyed state, which would prevent FlutterEngine from switching to
      // the next Lifecycle that is attached.
    }
  };

  FlutterEngineAndroidLifecycle(@NonNull LifecycleOwner provider) {
    super(provider);
  }

  public void setBackingLifecycle(@Nullable Lifecycle lifecycle) {
    ensureNotDestroyed();

    // We no longer want to propagate events from the old Lifecycle. Deregister our forwarding observer.
    if (backingLifecycle != null) {
      backingLifecycle.removeObserver(forwardingObserver);
    }

    // Manually move us to the Stopped state before we switch out the underlying Lifecycle.
    handleLifecycleEvent(Event.ON_STOP);

    // Switch out the underlying lifecycle.
    backingLifecycle = lifecycle;

    if (backingLifecycle != null) {
      // Add our forwardingObserver to the new backing Lifecycle so that this PluginRegistry is
      // controlled by that backing lifecycle. Adding our forwarding observer will automatically
      // result in invocations of the necessary Lifecycle events to bring us up to speed with the
      // new backingLifecycle, e.g., onStart(), onResume().
      lifecycle.addObserver(forwardingObserver);
    }
  }

  @Override
  public void handleLifecycleEvent(@NonNull Event event) {
    ensureNotDestroyed();
    super.handleLifecycleEvent(event);
  }

  public void destroy() {
    ensureNotDestroyed();
    setBackingLifecycle(null);
    markState(State.DESTROYED);
    isDestroyed = true;
  }

  private void ensureNotDestroyed() {
    if (isDestroyed) {
      throw new IllegalStateException("Tried to invoke a method on a destroyed FlutterEngineAndroidLifecycle.");
    }
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.ViewModelStoreOwner;
import androidx.lifecycle.ViewTreeLifecycleOwner;
import androidx.lifecycle.ViewTreeViewModelStoreOwner;
import androidx.savedstate.SavedStateRegistryOwner;
import androidx.savedstate.ViewTreeSavedStateRegistryOwner;

/**
 * The androidx view-tree owners visible from one view, so they can be installed on the root of
 * another window.
 *
 * <p>A virtual display platform view lives in a {@link SingleViewPresentation}, which is its own
 * window, so it cannot see the owners that the host activity or fragment installs above the {@code
 * FlutterView}. Views such as a Jetpack Compose {@code ComposeView} look these owners up when they
 * attach to a window and throw if they are missing.
 */
final class ViewTreeOwners {
  /**
   * Looks up the owners for a presentation when it is created.
   *
   * <p>A cached {@code FlutterEngine} keeps its platform views when it moves from one host to
   * another, and presentations are recreated (for example on every host resume). Reading the owners
   * at that point, instead of once when the platform view is created, keeps the embedded view off
   * the lifecycle of a host that no longer exists.
   */
  interface Source {
    /**
     * Returns the owners visible from the attached {@code FlutterView}, or null if there is no
     * attached {@code FlutterView} or it sees no owners.
     */
    @Nullable
    ViewTreeOwners get();
  }

  @Nullable private final LifecycleOwner lifecycleOwner;
  @Nullable private final SavedStateRegistryOwner savedStateRegistryOwner;
  @Nullable private final ViewModelStoreOwner viewModelStoreOwner;

  private ViewTreeOwners(
      @Nullable LifecycleOwner lifecycleOwner,
      @Nullable SavedStateRegistryOwner savedStateRegistryOwner,
      @Nullable ViewModelStoreOwner viewModelStoreOwner) {
    this.lifecycleOwner = lifecycleOwner;
    this.savedStateRegistryOwner = savedStateRegistryOwner;
    this.viewModelStoreOwner = viewModelStoreOwner;
  }

  /**
   * Captures the owners visible from {@code anchor}: the nearest ones set on {@code anchor} or its
   * ancestors. Returns null if {@code anchor} is null or sees none of the three owners.
   */
  @Nullable
  static ViewTreeOwners findFrom(@Nullable View anchor) {
    if (anchor == null) {
      return null;
    }
    final LifecycleOwner lifecycleOwner = ViewTreeLifecycleOwner.get(anchor);
    final SavedStateRegistryOwner savedStateRegistryOwner =
        ViewTreeSavedStateRegistryOwner.get(anchor);
    final ViewModelStoreOwner viewModelStoreOwner = ViewTreeViewModelStoreOwner.get(anchor);
    if (lifecycleOwner == null && savedStateRegistryOwner == null && viewModelStoreOwner == null) {
      return null;
    }
    return new ViewTreeOwners(lifecycleOwner, savedStateRegistryOwner, viewModelStoreOwner);
  }

  /** Installs the captured owners on {@code root}, skipping any that were not found. */
  void installOn(@NonNull View root) {
    if (lifecycleOwner != null) {
      ViewTreeLifecycleOwner.set(root, lifecycleOwner);
    }
    if (savedStateRegistryOwner != null) {
      ViewTreeSavedStateRegistryOwner.set(root, savedStateRegistryOwner);
    }
    if (viewModelStoreOwner != null) {
      ViewTreeViewModelStoreOwner.set(root, viewModelStoreOwner);
    }
  }
}

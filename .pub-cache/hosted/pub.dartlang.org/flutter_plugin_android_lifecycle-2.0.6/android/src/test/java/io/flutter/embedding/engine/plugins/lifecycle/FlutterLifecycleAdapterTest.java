// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.lifecycle;

import static org.junit.Assert.assertEquals;

import android.app.Activity;
import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

public class FlutterLifecycleAdapterTest {
  @Mock Lifecycle lifecycle;

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
  }

  @Test
  public void getActivityLifecycle() {
    TestActivityPluginBinding binding = new TestActivityPluginBinding(lifecycle);

    Lifecycle parsedLifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);

    assertEquals(lifecycle, parsedLifecycle);
  }

  private static final class TestActivityPluginBinding implements ActivityPluginBinding {
    private final Lifecycle lifecycle;

    TestActivityPluginBinding(Lifecycle lifecycle) {
      this.lifecycle = lifecycle;
    }

    @NonNull
    public Object getLifecycle() {
      return new HiddenLifecycleReference(lifecycle);
    }

    @Override
    public Activity getActivity() {
      return null;
    }

    @Override
    public void addRequestPermissionsResultListener(
        @NonNull PluginRegistry.RequestPermissionsResultListener listener) {}

    @Override
    public void removeRequestPermissionsResultListener(
        @NonNull PluginRegistry.RequestPermissionsResultListener listener) {}

    @Override
    public void addActivityResultListener(
        @NonNull PluginRegistry.ActivityResultListener listener) {}

    @Override
    public void removeActivityResultListener(
        @NonNull PluginRegistry.ActivityResultListener listener) {}

    @Override
    public void addOnNewIntentListener(@NonNull PluginRegistry.NewIntentListener listener) {}

    @Override
    public void removeOnNewIntentListener(@NonNull PluginRegistry.NewIntentListener listener) {}

    @Override
    public void addOnUserLeaveHintListener(
        @NonNull PluginRegistry.UserLeaveHintListener listener) {}

    @Override
    public void removeOnUserLeaveHintListener(
        @NonNull PluginRegistry.UserLeaveHintListener listener) {}

    @Override
    public void addOnSaveStateListener(
        @NonNull ActivityPluginBinding.OnSaveInstanceStateListener listener) {}

    @Override
    public void removeOnSaveStateListener(
        @NonNull ActivityPluginBinding.OnSaveInstanceStateListener listener) {}
  }
}

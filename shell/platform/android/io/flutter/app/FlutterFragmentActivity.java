// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.app;

import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;
import androidx.fragment.app.FragmentActivity;
import io.flutter.app.FlutterActivityDelegate.ViewFactory;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterView;

/**
 * Deprecated class for activities that use Flutter who also require the use of the Android v4
 * Support library's {@link FragmentActivity}.
 *
 * <p>Applications that don't have this need will likely want to use {@link FlutterActivity}
 * instead.
 *
 * <p><strong>Important!</strong> Flutter does not bundle the necessary Android v4 Support library
 * classes for this class to work at runtime. It is the responsibility of the app developer using
 * this class to ensure that they link against the v4 support library .jar file when creating their
 * app to ensure that {@link FragmentActivity} is available at runtime.
 *
 * @see <a target="_new"
 *     href="https://developer.android.com/training/testing/set-up-project">https://developer.android.com/training/testing/set-up-project</a>
 * @deprecated this class is replaced by {@link
 *     io.flutter.embedding.android.FlutterFragmentActivity}.
 */
@Deprecated
public class FlutterFragmentActivity extends FragmentActivity
    implements FlutterView.Provider, PluginRegistry, ViewFactory {
  private final FlutterActivityDelegate delegate = new FlutterActivityDelegate(this, this);

  // These aliases ensure that the methods we forward to the delegate adhere
  // to relevant interfaces versus just existing in FlutterActivityDelegate.
  private final FlutterActivityEvents eventDelegate = delegate;
  private final FlutterView.Provider viewProvider = delegate;
  private final PluginRegistry pluginRegistry = delegate;

  /**
   * Returns the Flutter view used by this activity; will be null before {@link #onCreate(Bundle)}
   * is called.
   */
  @Override
  public FlutterView getFlutterView() {
    return viewProvider.getFlutterView();
  }

  /**
   * Hook for subclasses to customize the creation of the {@code FlutterView}.
   *
   * <p>The default implementation returns {@code null}, which will cause the activity to use a
   * newly instantiated full-screen view.
   */
  @Override
  public FlutterView createFlutterView(Context context) {
    return null;
  }

  @Override
  public FlutterNativeView createFlutterNativeView() {
    return null;
  }

  @Override
  public boolean retainFlutterNativeView() {
    return false;
  }

  @Override
  public final boolean hasPlugin(String key) {
    return pluginRegistry.hasPlugin(key);
  }

  @Override
  public final <T> T valuePublishedByPlugin(String pluginKey) {
    return pluginRegistry.valuePublishedByPlugin(pluginKey);
  }

  @Override
  public final Registrar registrarFor(String pluginKey) {
    return pluginRegistry.registrarFor(pluginKey);
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    eventDelegate.onCreate(savedInstanceState);
  }

  @Override
  protected void onDestroy() {
    eventDelegate.onDestroy();
    super.onDestroy();
  }

  @Override
  public void onBackPressed() {
    if (!eventDelegate.onBackPressed()) {
      super.onBackPressed();
    }
  }

  @Override
  protected void onStart() {
    super.onStart();
    eventDelegate.onStart();
  }

  @Override
  protected void onStop() {
    eventDelegate.onStop();
    super.onStop();
  }

  @Override
  protected void onPause() {
    super.onPause();
    eventDelegate.onPause();
  }

  @Override
  protected void onPostResume() {
    super.onPostResume();
    eventDelegate.onPostResume();
  }

  @Override
  public void onRequestPermissionsResult(
      int requestCode, String[] permissions, int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    eventDelegate.onRequestPermissionsResult(requestCode, permissions, grantResults);
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (!eventDelegate.onActivityResult(requestCode, resultCode, data)) {
      super.onActivityResult(requestCode, resultCode, data);
    }
  }

  @Override
  protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    eventDelegate.onNewIntent(intent);
  }

  @Override
  public void onUserLeaveHint() {
    eventDelegate.onUserLeaveHint();
  }

  @Override
  public void onTrimMemory(int level) {
    super.onTrimMemory(level);
    eventDelegate.onTrimMemory(level);
  }

  @Override
  public void onLowMemory() {
    eventDelegate.onLowMemory();
  }

  @Override
  public void onConfigurationChanged(Configuration newConfig) {
    super.onConfigurationChanged(newConfig);
    eventDelegate.onConfigurationChanged(newConfig);
  }
}

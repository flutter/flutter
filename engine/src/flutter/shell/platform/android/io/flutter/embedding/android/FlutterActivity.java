// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.view.FlutterMain;

/**
 * {@code Activity} which displays a fullscreen Flutter UI.
 * <p>
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 * <p>
 * {@code FlutterActivity} is the simplest and most direct way to integrate Flutter within an
 * Android app.
 * <p>
 * The Dart entrypoint executed within this {@code Activity} is "main()" by default. The entrypoint
 * may be specified explicitly by passing the name of the entrypoint method as a {@code String} in
 * {@link #EXTRA_DART_ENTRYPOINT}, e.g., "myEntrypoint".
 * <p>
 * The Flutter route that is initially loaded within this {@code Activity} is "/". The initial
 * route may be specified explicitly by passing the name of the route as a {@code String} in
 * {@link #EXTRA_INITIAL_ROUTE}, e.g., "my/deep/link".
 * <p>
 * The app bundle path, Dart entrypoint, and initial route can each be controlled in a subclass of
 * {@code FlutterActivity} by overriding their respective methods:
 * <ul>
 *   <li>{@link #getAppBundlePath()}</li>
 *   <li>{@link #getDartEntrypoint()}</li>
 *   <li>{@link #getInitialRoute()}</li>
 * </ul>
 * If Flutter is needed in a location that cannot use an {@code Activity}, consider using
 * a {@link FlutterFragment}. Using a {@link FlutterFragment} requires forwarding some calls from
 * an {@code Activity} to the {@link FlutterFragment}.
 * <p>
 * If Flutter is needed in a location that can only use a {@code View}, consider using a
 * {@link FlutterView}. Using a {@link FlutterView} requires forwarding some calls from an
 * {@code Activity}, as well as forwarding lifecycle calls from an {@code Activity} or a
 * {@code Fragment}.
 */
// TODO(mattcarroll): explain each call forwarded to Fragment (first requires resolution of PluginRegistry API).
public class FlutterActivity extends FragmentActivity {
  private static final String TAG = "FlutterActivity";

  // Meta-data arguments, processed from manifest XML.
  private static final String DART_ENTRYPOINT_META_DATA_KEY = "io.flutter.Entrypoint";
  private static final String INITIAL_ROUTE_META_DATA_KEY = "io.flutter.InitialRoute";

  // Intent extra arguments.
  public static final String EXTRA_DART_ENTRYPOINT = "dart_entrypoint";
  public static final String EXTRA_INITIAL_ROUTE = "initial_route";

  // FlutterFragment management.
  private static final String TAG_FLUTTER_FRAGMENT = "flutter_fragment";
  // TODO(mattcarroll): replace ID with R.id when build system supports R.java
  private static final int FRAGMENT_CONTAINER_ID = 609893468; // random number
  private FlutterFragment flutterFragment;

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(createFragmentContainer());
    ensureFlutterFragmentCreated();
  }

  /**
   * Creates a {@link FrameLayout} with an ID of {@code #FRAGMENT_CONTAINER_ID} that will contain
   * the {@link FlutterFragment} displayed by this {@code FlutterActivity}.
   * <p>
   * @return the FrameLayout container
   */
  @NonNull
  private View createFragmentContainer() {
    FrameLayout container = new FrameLayout(this);
    container.setId(FRAGMENT_CONTAINER_ID);
    container.setLayoutParams(new ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
    ));
    return container;
  }

  /**
   * Ensure that a {@link FlutterFragment} is attached to this {@code FlutterActivity}.
   * <p>
   * If no {@link FlutterFragment} exists in this {@code FlutterActivity}, then a {@link FlutterFragment}
   * is created and added. If a {@link FlutterFragment} does exist in this {@code FlutterActivity}, then
   * a reference to that {@link FlutterFragment} is retained in {@code #flutterFragment}.
   */
  private void ensureFlutterFragmentCreated() {
    FragmentManager fragmentManager = getSupportFragmentManager();
    flutterFragment = (FlutterFragment) fragmentManager.findFragmentByTag(TAG_FLUTTER_FRAGMENT);
    if (flutterFragment == null) {
      // No FlutterFragment exists yet. This must be the initial Activity creation. We will create
      // and add a new FlutterFragment to this Activity.
      flutterFragment = createFlutterFragment();
      fragmentManager
          .beginTransaction()
          .add(FRAGMENT_CONTAINER_ID, flutterFragment, TAG_FLUTTER_FRAGMENT)
          .commit();
    }
  }

  /**
   * Creates the instance of the {@link FlutterFragment} that this {@code FlutterActivity} displays.
   * <p>
   * Subclasses may override this method to return a specialization of {@link FlutterFragment}.
   */
  @NonNull
  protected FlutterFragment createFlutterFragment() {
    return FlutterFragment.newInstance(
        getDartEntrypoint(),
        getInitialRoute(),
        getAppBundlePath(),
        FlutterShellArgs.fromIntent(getIntent())
    );
  }

  @Override
  public void onPostResume() {
    super.onPostResume();
    flutterFragment.onPostResume();
  }

  @Override
  protected void onNewIntent(Intent intent) {
    // Forward Intents to our FlutterFragment in case it cares.
    flutterFragment.onNewIntent(intent);
  }

  @Override
  public void onBackPressed() {
    flutterFragment.onBackPressed();
  }

  @Override
  public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    flutterFragment.onRequestPermissionsResult(requestCode, permissions, grantResults);
  }

  @Override
  public void onUserLeaveHint() {
    flutterFragment.onUserLeaveHint();
  }

  @Override
  public void onTrimMemory(int level) {
    super.onTrimMemory(level);
    flutterFragment.onTrimMemory(level);
  }

  @SuppressWarnings("unused")
  @Nullable
  protected FlutterEngine getFlutterEngine() {
    return flutterFragment.getFlutterEngine();
  }

  /**
   * The path to the bundle that contains this Flutter app's resources, e.g., Dart code snapshots.
   * <p>
   * When this {@code FlutterActivity} is run by Flutter tooling and a data String is included
   * in the launching {@code Intent}, that data String is interpreted as an app bundle path.
   * <p>
   * By default, the app bundle path is obtained from {@link FlutterMain#findAppBundlePath(Context)}.
   * <p>
   * Subclasses may override this method to return a custom app bundle path.
   */
  @NonNull
  protected String getAppBundlePath() {
    // If this Activity was launched from tooling, and the incoming Intent contains
    // a custom app bundle path, return that path.
    // TODO(mattcarroll): determine if we should have an explicit FlutterTestActivity instead of conflating.
    if (isDebuggable() && Intent.ACTION_RUN.equals(getIntent().getAction())) {
      String appBundlePath = getIntent().getDataString();
      if (appBundlePath != null) {
        return appBundlePath;
      }
    }

    // Return the default app bundle path.
    // TODO(mattcarroll): move app bundle resolution into an appropriately named class.
    return FlutterMain.findAppBundlePath(getApplicationContext());
  }

  /**
   * The Dart entrypoint that will be executed as soon as the Dart snapshot is loaded.
   * <p>
   * This preference can be controlled with 2 methods:
   * <ol>
   *   <li>Pass a {@code String} as {@link #EXTRA_DART_ENTRYPOINT} with the launching {@code Intent}, or</li>
   *   <li>Set a {@code <meta-data>} called {@link #DART_ENTRYPOINT_META_DATA_KEY} for this
   *       {@code Activity} in the Android manifest.</li>
   * </ol>
   * If both preferences are set, the {@code Intent} preference takes priority.
   * <p>
   * The reason that a {@code <meta-data>} preference is supported is because this {@code Activity}
   * might be the very first {@code Activity} launched, which means the developer won't have
   * control over the incoming {@code Intent}.
   * <p>
   * Subclasses may override this method to directly control the Dart entrypoint.
   */
  @Nullable
  protected String getDartEntrypoint() {
    if (getIntent().hasExtra(EXTRA_DART_ENTRYPOINT)) {
      return getIntent().getStringExtra(EXTRA_DART_ENTRYPOINT);
    }

    try {
      ActivityInfo activityInfo = getPackageManager().getActivityInfo(
          getComponentName(),
          PackageManager.GET_META_DATA|PackageManager.GET_ACTIVITIES
      );
      Bundle metadata = activityInfo.metaData;
      return metadata != null ? metadata.getString(DART_ENTRYPOINT_META_DATA_KEY) : null;
    } catch (PackageManager.NameNotFoundException e) {
      return null;
    }
  }

  /**
   * The initial route that a Flutter app will render upon loading and executing its Dart code.
   * <p>
   * This preference can be controlled with 2 methods:
   * <ol>
   *   <li>Pass a boolean as {@link #EXTRA_INITIAL_ROUTE} with the launching {@code Intent}, or</li>
   *   <li>Set a {@code <meta-data>} called {@link #INITIAL_ROUTE_META_DATA_KEY} for this
   *    {@code Activity} in the Android manifest.</li>
   * </ol>
   * If both preferences are set, the {@code Intent} preference takes priority.
   * <p>
   * The reason that a {@code <meta-data>} preference is supported is because this {@code Activity}
   * might be the very first {@code Activity} launched, which means the developer won't have
   * control over the incoming {@code Intent}.
   * <p>
   * Subclasses may override this method to directly control the initial route.
   */
  @Nullable
  protected String getInitialRoute() {
    if (getIntent().hasExtra(EXTRA_INITIAL_ROUTE)) {
      return getIntent().getStringExtra(EXTRA_INITIAL_ROUTE);
    }

    try {
      ActivityInfo activityInfo = getPackageManager().getActivityInfo(
          getComponentName(),
          PackageManager.GET_META_DATA|PackageManager.GET_ACTIVITIES
      );
      Bundle metadata = activityInfo.metaData;
      return metadata != null ? metadata.getString(INITIAL_ROUTE_META_DATA_KEY) : null;
    } catch (PackageManager.NameNotFoundException e) {
      return null;
    }
  }

  /**
   * Returns true if Flutter is running in "debug mode", and false otherwise.
   * <p>
   * Debug mode allows Flutter to operate with hot reload and hot restart. Release mode does not.
   */
  private boolean isDebuggable() {
    return (getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
  }
}

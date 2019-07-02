// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;

import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.embedding.engine.renderer.OnFirstFrameRenderedListener;
import io.flutter.plugin.platform.PlatformPlugin;
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
public class FlutterActivity extends FragmentActivity
    implements FlutterFragment.FlutterEngineProvider,
    FlutterFragment.FlutterEngineConfigurator,
    OnFirstFrameRenderedListener {
  private static final String TAG = "FlutterActivity";

  // Meta-data arguments, processed from manifest XML.
  protected static final String DART_ENTRYPOINT_META_DATA_KEY = "io.flutter.Entrypoint";
  protected static final String INITIAL_ROUTE_META_DATA_KEY = "io.flutter.InitialRoute";

  // Intent extra arguments.
  protected static final String EXTRA_DART_ENTRYPOINT = "dart_entrypoint";
  protected static final String EXTRA_INITIAL_ROUTE = "initial_route";
  protected static final String EXTRA_BACKGROUND_MODE = "background_mode";

  // Default configuration.
  protected static final String DEFAULT_DART_ENTRYPOINT = "main";
  protected static final String DEFAULT_INITIAL_ROUTE = "/";
  protected static final String DEFAULT_BACKGROUND_MODE = BackgroundMode.opaque.name();

  // FlutterFragment management.
  private static final String TAG_FLUTTER_FRAGMENT = "flutter_fragment";
  // TODO(mattcarroll): replace ID with R.id when build system supports R.java
  private static final int FRAGMENT_CONTAINER_ID = 609893468; // random number
  @Nullable
  private FlutterFragment flutterFragment;

  // Used to cover the Activity until the 1st frame is rendered so as to
  // avoid a brief black flicker from a SurfaceView version of FlutterView.
  @Nullable
  private View coverView;

  /**
   * Creates an {@link Intent} that launches a {@code FlutterActivity}, which executes
   * a {@code main()} Dart entrypoint, and displays the "/" route as Flutter's initial route.
   */
  @NonNull
  public static Intent createDefaultIntent(@NonNull Context launchContext) {
    return createBuilder().build(launchContext);
  }

  /**
   * Creates an {@link IntentBuilder}, which can be used to configure an {@link Intent} to
   * launch a {@code FlutterActivity}.
   */
  @NonNull
  public static IntentBuilder createBuilder() {
    return new IntentBuilder(FlutterActivity.class);
  }

  /**
   * Builder to create an {@code Intent} that launches a {@code FlutterActivity} with the
   * desired configuration.
   */
  public static class IntentBuilder {
    private final Class<? extends FlutterActivity> activityClass;
    private String dartEntrypoint = DEFAULT_DART_ENTRYPOINT;
    private String initialRoute = DEFAULT_INITIAL_ROUTE;
    private String backgroundMode = DEFAULT_BACKGROUND_MODE;

    protected IntentBuilder(@NonNull Class<? extends FlutterActivity> activityClass) {
      this.activityClass = activityClass;
    }

    /**
     * The name of the initial Dart method to invoke, defaults to "main".
     */
    @NonNull
    public IntentBuilder dartEntrypoint(@NonNull String dartEntrypoint) {
      this.dartEntrypoint = dartEntrypoint;
      return this;
    }

    /**
     * The initial route that a Flutter app will render in this {@link FlutterFragment},
     * defaults to "/".
     */
    @NonNull
    public IntentBuilder initialRoute(@NonNull String initialRoute) {
      this.initialRoute = initialRoute;
      return this;
    }

    /**
     * The mode of {@code FlutterActivity}'s background, either {@link BackgroundMode#opaque} or
     * {@link BackgroundMode#transparent}.
     * <p>
     * The default background mode is {@link BackgroundMode#opaque}.
     * <p>
     * Choosing a background mode of {@link BackgroundMode#transparent} will configure the inner
     * {@link FlutterView} of this {@code FlutterActivity} to be configured with a
     * {@link FlutterTextureView} to support transparency. This choice has a non-trivial performance
     * impact. A transparent background should only be used if it is necessary for the app design
     * being implemented.
     * <p>
     * A {@code FlutterActivity} that is configured with a background mode of
     * {@link BackgroundMode#transparent} must have a theme applied to it that includes the
     * following property: {@code <item name="android:windowIsTranslucent">true</item>}.
     */
    @NonNull
    public IntentBuilder backgroundMode(@NonNull BackgroundMode backgroundMode) {
      this.backgroundMode = backgroundMode.name();
      return this;
    }

    /**
     * Creates and returns an {@link Intent} that will launch a {@code FlutterActivity} with
     * the desired configuration.
     */
    @NonNull
    public Intent build(@NonNull Context context) {
      return new Intent(context, activityClass)
          .putExtra(EXTRA_DART_ENTRYPOINT, dartEntrypoint)
          .putExtra(EXTRA_INITIAL_ROUTE, initialRoute)
          .putExtra(EXTRA_BACKGROUND_MODE, backgroundMode);
    }
  }

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    configureWindowForTransparency();
    setContentView(createFragmentContainer());
    showCoverView();
    configureStatusBarForFullscreenFlutterExperience();
    ensureFlutterFragmentCreated();
  }

  /**
   * Sets this {@code Activity}'s {@code Window} background to be transparent, and hides the status
   * bar, if this {@code Activity}'s desired {@link BackgroundMode} is {@link BackgroundMode#transparent}.
   * <p>
   * For {@code Activity} transparency to work as expected, the theme applied to this {@code Activity}
   * must include {@code <item name="android:windowIsTranslucent">true</item>}.
   */
  private void configureWindowForTransparency() {
    BackgroundMode backgroundMode = getBackgroundMode();
    if (backgroundMode == BackgroundMode.transparent) {
      getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
      getWindow().setFlags(
        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
      );
    }
  }

  /**
   * Cover all visible {@code Activity} area with a {@code View} that paints everything the same
   * color as the {@code Window}.
   * <p>
   * This cover {@code View} should be displayed at the very beginning of the {@code Activity}'s
   * lifespan and then hidden once Flutter renders its first frame. The purpose of this cover is to
   * cover {@link FlutterSurfaceView}, which briefly displays a black rectangle before it can make
   * itself transparent.
   */
  private void showCoverView() {
    if (getBackgroundMode() == BackgroundMode.transparent) {
      // Don't display an opaque cover view if the Activity is intended to be transparent.
      return;
    }

    Log.v(TAG, "Showing cover view until first frame is rendered.");

    // Create the coverView.
    if (coverView == null) {
      coverView = new View(this);
      addContentView(coverView, new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    }

    // Pain the coverView with the Window's background.
    Drawable background = createCoverViewBackground();
    if (background != null) {
      coverView.setBackground(background);
    } else {
      // If we can't obtain a window background to replicate then we'd be guessing as to the least
      // intrusive color. But there is no way to make an accurate guess. In this case we don't
      // give the coverView any color, which means a brief black rectangle will be visible upon
      // Activity launch.
    }
  }

  @Nullable
  private Drawable createCoverViewBackground() {
    TypedValue typedValue = new TypedValue();
    boolean hasBackgroundColor = getTheme().resolveAttribute(
        android.R.attr.windowBackground,
        typedValue,
        true
    );
    if (hasBackgroundColor && typedValue.resourceId != 0) {
      return getResources().getDrawable(typedValue.resourceId, getTheme());
    } else {
      return null;
    }
  }

  /**
   * Hides the cover {@code View}.
   * <p>
   * This method should be called when Flutter renders its first frame. See {@link #showCoverView()}
   * for details.
   */
  private void hideCoverView() {
    if (coverView != null) {
      coverView.setVisibility(View.GONE);
    }
  }

  private void configureStatusBarForFullscreenFlutterExperience() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      Window window = getWindow();
      window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
      window.setStatusBarColor(0x40000000);
      window.getDecorView().setSystemUiVisibility(PlatformPlugin.DEFAULT_SYSTEM_UI);
    }
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
    BackgroundMode backgroundMode = getBackgroundMode();

    Log.d(TAG, "Creating FlutterFragment:\n"
        + "Background transparency mode: " + backgroundMode + "\n"
        + "Dart entrypoint: " + getDartEntrypoint() + "\n"
        + "Initial route: " + getInitialRoute() + "\n"
        + "App bundle path: " + getAppBundlePath() + "\n"
        + "Will attach FlutterEngine to Activity: " + shouldAttachEngineToActivity());

    return new FlutterFragment.Builder()
        .dartEntrypoint(getDartEntrypoint())
        .initialRoute(getInitialRoute())
        .appBundlePath(getAppBundlePath())
        .flutterShellArgs(FlutterShellArgs.fromIntent(getIntent()))
        .renderMode(backgroundMode == BackgroundMode.opaque
            ? FlutterView.RenderMode.surface
            : FlutterView.RenderMode.texture)
        .transparencyMode(backgroundMode == BackgroundMode.opaque
            ? FlutterView.TransparencyMode.opaque
            : FlutterView.TransparencyMode.transparent)
        .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
        .build();
  }

  /**
   * Hook for subclasses to control whether or not the {@link FlutterFragment} within this
   * {@code Activity} automatically attaches its {@link FlutterEngine} to this {@code Activity}.
   * <p>
   * For an explanation of why this control exists, see {@link FlutterFragment.Builder#shouldAttachEngineToActivity()}.
   * <p>
   * This property is controlled with a protected method instead of an {@code Intent} argument because
   * the only situation where changing this value would help, is a situation in which
   * {@code FlutterActivity} is being subclassed to utilize a custom and/or cached {@link FlutterEngine}.
   * <p>
   * Defaults to {@code true}.
   */
  protected boolean shouldAttachEngineToActivity() {
    return true;
  }

  /**
   * Hook for subclasses to easily provide a custom {@code FlutterEngine}.
   */
  @Nullable
  @Override
  public FlutterEngine provideFlutterEngine(@NonNull Context context) {
    // No-op. Hook for subclasses.
    return null;
  }

  /**
   * Hook for subclasses to easily configure a {@code FlutterEngine}, e.g., register
   * plugins.
   * <p>
   * This method is called after {@link #provideFlutterEngine(Context)}.
   */
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    // No-op. Hook for subclasses.
  }

  @Override
  public void onPostResume() {
    super.onPostResume();
    flutterFragment.onPostResume();
  }

  @Override
  protected void onNewIntent(@NonNull Intent intent) {
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
  @NonNull
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
      String desiredDartEntrypoint = metadata != null ? metadata.getString(DART_ENTRYPOINT_META_DATA_KEY) : null;
      return desiredDartEntrypoint != null ? desiredDartEntrypoint : DEFAULT_DART_ENTRYPOINT;
    } catch (PackageManager.NameNotFoundException e) {
      return DEFAULT_DART_ENTRYPOINT;
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
  @NonNull
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
      String desiredInitialRoute = metadata != null ? metadata.getString(INITIAL_ROUTE_META_DATA_KEY) : null;
      return desiredInitialRoute != null ? desiredInitialRoute : DEFAULT_INITIAL_ROUTE;
    } catch (PackageManager.NameNotFoundException e) {
      return DEFAULT_INITIAL_ROUTE;
    }
  }

  /**
   * The desired window background mode of this {@code Activity}, which defaults to
   * {@link BackgroundMode#opaque}.
   */
  @NonNull
  protected BackgroundMode getBackgroundMode() {
    if (getIntent().hasExtra(EXTRA_BACKGROUND_MODE)) {
      return BackgroundMode.valueOf(getIntent().getStringExtra(EXTRA_BACKGROUND_MODE));
    } else {
      return BackgroundMode.opaque;
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

  @Override
  public void onFirstFrameRendered() {
    Log.v(TAG, "First frame has been rendered. Hiding cover view.");
    hideCoverView();
  }

  /**
   * The mode of the background of a {@code FlutterActivity}, either opaque or transparent.
   */
  public enum BackgroundMode {
    /** Indicates a FlutterActivity with an opaque background. This is the default. */
    opaque,
    /** Indicates a FlutterActivity with a transparent background. */
    transparent
  }
}

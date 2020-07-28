// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.app;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.Configuration;
import android.content.res.Resources.NotFoundException;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager.LayoutParams;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.util.Preconditions;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterRunArguments;
import io.flutter.view.FlutterView;
import java.util.ArrayList;

/**
 * Class that performs the actual work of tying Android {@link Activity} instances to Flutter.
 *
 * <p>This exists as a dedicated class (as opposed to being integrated directly into {@link
 * FlutterActivity}) to facilitate applications that don't wish to subclass {@code FlutterActivity}.
 * The most obvious example of when this may come in handy is if an application wishes to subclass
 * the Android v4 support library's {@code FragmentActivity}.
 *
 * <h3>Usage:</h3>
 *
 * <p>To wire this class up to your activity, simply forward the events defined in {@link
 * FlutterActivityEvents} from your activity to an instance of this class. Optionally, you can make
 * your activity implement {@link PluginRegistry} and/or {@link
 * io.flutter.view.FlutterView.Provider} and forward those methods to this class as well.
 */
public final class FlutterActivityDelegate
    implements FlutterActivityEvents, FlutterView.Provider, PluginRegistry {
  private static final String SPLASH_SCREEN_META_DATA_KEY =
      "io.flutter.app.android.SplashScreenUntilFirstFrame";
  private static final String TAG = "FlutterActivityDelegate";
  private static final LayoutParams matchParent =
      new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);

  /**
   * Specifies the mechanism by which Flutter views are created during the operation of a {@code
   * FlutterActivityDelegate}.
   *
   * <p>A delegate's view factory will be consulted during {@link #onCreate(Bundle)}. If it returns
   * {@code null}, then the delegate will fall back to instantiating a new full-screen {@code
   * FlutterView}.
   *
   * <p>A delegate's native view factory will be consulted during {@link #onCreate(Bundle)}. If it
   * returns {@code null}, then the delegate will fall back to instantiating a new {@code
   * FlutterNativeView}. This is useful for applications to override to reuse the FlutterNativeView
   * held e.g. by a pre-existing background service.
   */
  public interface ViewFactory {
    FlutterView createFlutterView(Context context);

    FlutterNativeView createFlutterNativeView();

    /**
     * Hook for subclasses to indicate that the {@code FlutterNativeView} returned by {@link
     * #createFlutterNativeView()} should not be destroyed when this activity is destroyed.
     */
    boolean retainFlutterNativeView();
  }

  private final Activity activity;
  private final ViewFactory viewFactory;
  private FlutterView flutterView;
  private View launchView;

  public FlutterActivityDelegate(Activity activity, ViewFactory viewFactory) {
    this.activity = Preconditions.checkNotNull(activity);
    this.viewFactory = Preconditions.checkNotNull(viewFactory);
  }

  @Override
  public FlutterView getFlutterView() {
    return flutterView;
  }

  // The implementation of PluginRegistry forwards to flutterView.
  @Override
  public boolean hasPlugin(String key) {
    return flutterView.getPluginRegistry().hasPlugin(key);
  }

  @Override
  @SuppressWarnings("unchecked")
  public <T> T valuePublishedByPlugin(String pluginKey) {
    return (T) flutterView.getPluginRegistry().valuePublishedByPlugin(pluginKey);
  }

  @Override
  public Registrar registrarFor(String pluginKey) {
    return flutterView.getPluginRegistry().registrarFor(pluginKey);
  }

  @Override
  public boolean onRequestPermissionsResult(
      int requestCode, String[] permissions, int[] grantResults) {
    return flutterView
        .getPluginRegistry()
        .onRequestPermissionsResult(requestCode, permissions, grantResults);
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    return flutterView.getPluginRegistry().onActivityResult(requestCode, resultCode, data);
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      Window window = activity.getWindow();
      window.addFlags(LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
      window.setStatusBarColor(0x40000000);
      window.getDecorView().setSystemUiVisibility(PlatformPlugin.DEFAULT_SYSTEM_UI);
    }

    String[] args = getArgsFromIntent(activity.getIntent());
    FlutterMain.ensureInitializationComplete(activity.getApplicationContext(), args);

    flutterView = viewFactory.createFlutterView(activity);
    if (flutterView == null) {
      FlutterNativeView nativeView = viewFactory.createFlutterNativeView();
      flutterView = new FlutterView(activity, null, nativeView);
      flutterView.setLayoutParams(matchParent);
      activity.setContentView(flutterView);
      launchView = createLaunchView();
      if (launchView != null) {
        addLaunchView();
      }
    }

    if (loadIntent(activity.getIntent())) {
      return;
    }

    String appBundlePath = FlutterMain.findAppBundlePath();
    if (appBundlePath != null) {
      runBundle(appBundlePath);
    }
  }

  @Override
  public void onNewIntent(Intent intent) {
    // Only attempt to reload the Flutter Dart code during development. Use
    // the debuggable flag as an indicator that we are in development mode.
    if (!isDebuggable() || !loadIntent(intent)) {
      flutterView.getPluginRegistry().onNewIntent(intent);
    }
  }

  private boolean isDebuggable() {
    return (activity.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
  }

  @Override
  public void onPause() {
    Application app = (Application) activity.getApplicationContext();
    if (app instanceof FlutterApplication) {
      FlutterApplication flutterApp = (FlutterApplication) app;
      if (activity.equals(flutterApp.getCurrentActivity())) {
        flutterApp.setCurrentActivity(null);
      }
    }
    if (flutterView != null) {
      flutterView.onPause();
    }
  }

  @Override
  public void onStart() {
    if (flutterView != null) {
      flutterView.onStart();
    }
  }

  @Override
  public void onResume() {
    Application app = (Application) activity.getApplicationContext();
    if (app instanceof FlutterApplication) {
      FlutterApplication flutterApp = (FlutterApplication) app;
      flutterApp.setCurrentActivity(activity);
    }
  }

  @Override
  public void onStop() {
    flutterView.onStop();
  }

  @Override
  public void onPostResume() {
    if (flutterView != null) {
      flutterView.onPostResume();
    }
  }

  @Override
  public void onDestroy() {
    Application app = (Application) activity.getApplicationContext();
    if (app instanceof FlutterApplication) {
      FlutterApplication flutterApp = (FlutterApplication) app;
      if (activity.equals(flutterApp.getCurrentActivity())) {
        flutterApp.setCurrentActivity(null);
      }
    }
    if (flutterView != null) {
      final boolean detach =
          flutterView.getPluginRegistry().onViewDestroy(flutterView.getFlutterNativeView());
      if (detach || viewFactory.retainFlutterNativeView()) {
        // Detach, but do not destroy the FlutterView if a plugin
        // expressed interest in its FlutterNativeView.
        flutterView.detach();
      } else {
        flutterView.destroy();
      }
    }
  }

  @Override
  public boolean onBackPressed() {
    if (flutterView != null) {
      flutterView.popRoute();
      return true;
    }
    return false;
  }

  @Override
  public void onUserLeaveHint() {
    flutterView.getPluginRegistry().onUserLeaveHint();
  }

  @Override
  public void onTrimMemory(int level) {
    // Use a trim level delivered while the application is running so the
    // framework has a chance to react to the notification.
    if (level == TRIM_MEMORY_RUNNING_LOW) {
      flutterView.onMemoryPressure();
    }
  }

  @Override
  public void onLowMemory() {
    flutterView.onMemoryPressure();
  }

  @Override
  public void onConfigurationChanged(Configuration newConfig) {}

  private static String[] getArgsFromIntent(Intent intent) {
    // Before adding more entries to this list, consider that arbitrary
    // Android applications can generate intents with extra data and that
    // there are many security-sensitive args in the binary.
    ArrayList<String> args = new ArrayList<>();
    if (intent.getBooleanExtra("trace-startup", false)) {
      args.add("--trace-startup");
    }
    if (intent.getBooleanExtra("start-paused", false)) {
      args.add("--start-paused");
    }
    if (intent.getBooleanExtra("disable-service-auth-codes", false)) {
      args.add("--disable-service-auth-codes");
    }
    if (intent.getBooleanExtra("use-test-fonts", false)) {
      args.add("--use-test-fonts");
    }
    if (intent.getBooleanExtra("enable-dart-profiling", false)) {
      args.add("--enable-dart-profiling");
    }
    if (intent.getBooleanExtra("enable-software-rendering", false)) {
      args.add("--enable-software-rendering");
    }
    if (intent.getBooleanExtra("skia-deterministic-rendering", false)) {
      args.add("--skia-deterministic-rendering");
    }
    if (intent.getBooleanExtra("trace-skia", false)) {
      args.add("--trace-skia");
    }
    if (intent.getBooleanExtra("trace-systrace", false)) {
      args.add("--trace-systrace");
    }
    if (intent.getBooleanExtra("dump-skp-on-shader-compilation", false)) {
      args.add("--dump-skp-on-shader-compilation");
    }
    if (intent.getBooleanExtra("cache-sksl", false)) {
      args.add("--cache-sksl");
    }
    if (intent.getBooleanExtra("purge-persistent-cache", false)) {
      args.add("--purge-persistent-cache");
    }
    if (intent.getBooleanExtra("verbose-logging", false)) {
      args.add("--verbose-logging");
    }
    final int observatoryPort = intent.getIntExtra("observatory-port", 0);
    if (observatoryPort > 0) {
      args.add("--observatory-port=" + Integer.toString(observatoryPort));
    }
    if (intent.getBooleanExtra("disable-service-auth-codes", false)) {
      args.add("--disable-service-auth-codes");
    }
    if (intent.getBooleanExtra("endless-trace-buffer", false)) {
      args.add("--endless-trace-buffer");
    }
    // NOTE: all flags provided with this argument are subject to filtering
    // based on a a list of allowed flags in shell/common/switches.cc. If any
    // flag provided is not allowed, the process will immediately terminate.
    if (intent.hasExtra("dart-flags")) {
      args.add("--dart-flags=" + intent.getStringExtra("dart-flags"));
    }
    if (!args.isEmpty()) {
      String[] argsArray = new String[args.size()];
      return args.toArray(argsArray);
    }
    return null;
  }

  private boolean loadIntent(Intent intent) {
    String action = intent.getAction();
    if (Intent.ACTION_RUN.equals(action)) {
      String route = intent.getStringExtra("route");
      String appBundlePath = intent.getDataString();
      if (appBundlePath == null) {
        // Fall back to the installation path if no bundle path was specified.
        appBundlePath = FlutterMain.findAppBundlePath();
      }
      if (route != null) {
        flutterView.setInitialRoute(route);
      }

      runBundle(appBundlePath);
      return true;
    }

    return false;
  }

  private void runBundle(String appBundlePath) {
    if (!flutterView.getFlutterNativeView().isApplicationRunning()) {
      FlutterRunArguments args = new FlutterRunArguments();
      args.bundlePath = appBundlePath;
      args.entrypoint = "main";
      flutterView.runFromBundle(args);
    }
  }

  /**
   * Creates a {@link View} containing the same {@link Drawable} as the one set as the {@code
   * windowBackground} of the parent activity for use as a launch splash view.
   *
   * <p>Returns null if no {@code windowBackground} is set for the activity.
   */
  private View createLaunchView() {
    if (!showSplashScreenUntilFirstFrame()) {
      return null;
    }
    final Drawable launchScreenDrawable = getLaunchScreenDrawableFromActivityTheme();
    if (launchScreenDrawable == null) {
      return null;
    }
    final View view = new View(activity);
    view.setLayoutParams(matchParent);
    view.setBackground(launchScreenDrawable);
    return view;
  }

  /**
   * Extracts a {@link Drawable} from the parent activity's {@code windowBackground}.
   *
   * <p>{@code android:windowBackground} is specifically reused instead of a other attributes
   * because the Android framework can display it fast enough when launching the app as opposed to
   * anything defined in the Activity subclass.
   *
   * <p>Returns null if no {@code windowBackground} is set for the activity.
   */
  @SuppressWarnings("deprecation")
  private Drawable getLaunchScreenDrawableFromActivityTheme() {
    TypedValue typedValue = new TypedValue();
    if (!activity.getTheme().resolveAttribute(android.R.attr.windowBackground, typedValue, true)) {
      return null;
    }
    if (typedValue.resourceId == 0) {
      return null;
    }
    try {
      return activity.getResources().getDrawable(typedValue.resourceId);
    } catch (NotFoundException e) {
      Log.e(TAG, "Referenced launch screen windowBackground resource does not exist");
      return null;
    }
  }

  /**
   * Let the user specify whether the activity's {@code windowBackground} is a launch screen and
   * should be shown until the first frame via a <meta-data> tag in the activity.
   */
  private Boolean showSplashScreenUntilFirstFrame() {
    try {
      ActivityInfo activityInfo =
          activity
              .getPackageManager()
              .getActivityInfo(
                  activity.getComponentName(),
                  PackageManager.GET_META_DATA | PackageManager.GET_ACTIVITIES);
      Bundle metadata = activityInfo.metaData;
      return metadata != null && metadata.getBoolean(SPLASH_SCREEN_META_DATA_KEY);
    } catch (NameNotFoundException e) {
      return false;
    }
  }

  /**
   * Show and then automatically animate out the launch view.
   *
   * <p>If a launch screen is defined in the user application's AndroidManifest.xml as the
   * activity's {@code windowBackground}, display it on top of the {@link FlutterView} and remove
   * the activity's {@code windowBackground}.
   *
   * <p>Fade it out and remove it when the {@link FlutterView} renders its first frame.
   */
  private void addLaunchView() {
    if (launchView == null) {
      return;
    }

    activity.addContentView(launchView, matchParent);
    flutterView.addFirstFrameListener(
        new FlutterView.FirstFrameListener() {
          @Override
          public void onFirstFrame() {
            FlutterActivityDelegate.this
                .launchView
                .animate()
                .alpha(0f)
                // Use Android's default animation duration.
                .setListener(
                    new AnimatorListenerAdapter() {
                      @Override
                      public void onAnimationEnd(Animator animation) {
                        // Views added to an Activity's addContentView is always added to its
                        // root FrameLayout.
                        ((ViewGroup) FlutterActivityDelegate.this.launchView.getParent())
                            .removeView(FlutterActivityDelegate.this.launchView);
                        FlutterActivityDelegate.this.launchView = null;
                      }
                    });

            FlutterActivityDelegate.this.flutterView.removeFirstFrameListener(this);
          }
        });

    // Resets the activity theme from the one containing the launch screen in the window
    // background to a blank one since the launch screen is now in a view in front of the
    // FlutterView.
    //
    // We can make this configurable if users want it.
    activity.setTheme(android.R.style.Theme_Black_NoTitleBar);
  }
}

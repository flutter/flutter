// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.view.FlutterMain;

import static android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW;

/**
 * {@code Fragment} which displays a Flutter UI that takes up all available {@code Fragment} space.
 * <p>
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 * <p>
 * Using a {@code FlutterFragment} requires forwarding a number of calls from an {@code Activity} to
 * ensure that the internal Flutter app behaves as expected:
 * <ol>
 *   <li>{@link android.app.Activity#onPostResume()}</li>
 *   <li>{@link android.app.Activity#onBackPressed()}</li>
 *   <li>{@link android.app.Activity#onRequestPermissionsResult(int, String[], int[])} ()}</li>
 *   <li>{@link android.app.Activity#onNewIntent(Intent)} ()}</li>
 *   <li>{@link android.app.Activity#onUserLeaveHint()}</li>
 *   <li>{@link android.app.Activity#onTrimMemory(int)}</li>
 * </ol>
 * Additionally, when starting an {@code Activity} for a result from this {@code Fragment}, be sure
 * to invoke {@link Fragment#startActivityForResult(Intent, int)} rather than
 * {@link android.app.Activity#startActivityForResult(Intent, int)}. If the {@code Activity} version
 * of the method is invoked then this {@code Fragment} will never receive its
 * {@link Fragment#onActivityResult(int, int, Intent)} callback.
 * <p>
 * If convenient, consider using a {@link FlutterActivity} instead of a {@code FlutterFragment} to
 * avoid the work of forwarding calls.
 * <p>
 * If Flutter is needed in a location that can only use a {@code View}, consider using a
 * {@link FlutterView}. Using a {@link FlutterView} requires forwarding some calls from an
 * {@code Activity}, as well as forwarding lifecycle calls from an {@code Activity} or a
 * {@code Fragment}.
 */
public class FlutterFragment extends Fragment {
  private static final String TAG = "FlutterFragment";

  private static final String ARG_DART_ENTRYPOINT = "dart_entrypoint";
  private static final String ARG_INITIAL_ROUTE = "initial_route";
  private static final String ARG_APP_BUNDLE_PATH = "app_bundle_path";
  private static final String ARG_FLUTTER_INITIALIZATION_ARGS = "initialization_args";

  /**
   * Factory method that creates a new {@link FlutterFragment} with a default configuration.
   * <ul>
   *   <li>default Dart entrypoint of "main"</li>
   *   <li>initial route of "/"</li>
   *   <li>default app bundle location</li>
   *   <li>no special engine arguments</li>
   * </ul>
   * @return new {@link FlutterFragment}
   */
  public static FlutterFragment newInstance() {
    return newInstance(
        null,
        null,
        null,
        null
    );
  }

  /**
   * Factory method that creates a new {@link FlutterFragment} with the given configuration.
   * <p>
   * @param dartEntrypoint the name of the initial Dart method to invoke, defaults to "main"
   * @param initialRoute the first route that a Flutter app will render in this {@link FlutterFragment},
   *                     defaults to "/"
   * @param appBundlePath the path to the app bundle which contains the Dart app to execute, defaults
   *                      to {@link FlutterMain#findAppBundlePath(Context)}
   * @param flutterShellArgs any special configuration arguments for the Flutter engine
   *
   * @return a new {@link FlutterFragment}
   */
  public static FlutterFragment newInstance(@Nullable String dartEntrypoint,
                                            @Nullable String initialRoute,
                                            @Nullable String appBundlePath,
                                            @Nullable FlutterShellArgs flutterShellArgs) {
    FlutterFragment frag = new FlutterFragment();

    Bundle args = createArgsBundle(
        dartEntrypoint,
        initialRoute,
        appBundlePath,
        flutterShellArgs
    );
    frag.setArguments(args);

    return frag;
  }

  /**
   * Creates a {@link Bundle} of arguments that can be used to configure a {@link FlutterFragment}.
   * This method is exposed so that developers can create subclasses of {@link FlutterFragment}.
   * Subclasses should declare static factories that use this method to create arguments that will
   * be understood by the base class, and then the subclass can add any additional arguments it
   * wants to this {@link Bundle}. Example:
   * <pre>{@code
   * public static MyFlutterFragment newInstance(String myNewArg) {
   *   // Create an instance of our subclass Fragment.
   *   MyFlutterFragment myFrag = new MyFlutterFragment();
   *
   *   // Create the Bundle or args that FlutterFragment understands.
   *   Bundle args = FlutterFragment.createArgsBundle(...);
   *
   *   // Add our new args to the bundle.
   *   args.putString(ARG_MY_NEW_ARG, myNewArg);
   *
   *   // Give the args to our subclass Fragment.
   *   myFrag.setArguments(args);
   *
   *   // Return the newly created subclass Fragment.
   *   return myFrag;
   * }
   * }</pre>
   *
   * @param dartEntrypoint the name of the initial Dart method to invoke, defaults to "main"
   * @param initialRoute the first route that a Flutter app will render in this {@link FlutterFragment}, defaults to "/"
   * @param appBundlePath the path to the app bundle which contains the Dart app to execute
   * @param flutterShellArgs any special configuration arguments for the Flutter engine
   *
   * @return Bundle of arguments that configure a {@link FlutterFragment}
   */
  protected static Bundle createArgsBundle(@Nullable String dartEntrypoint,
                                           @Nullable String initialRoute,
                                           @Nullable String appBundlePath,
                                           @Nullable FlutterShellArgs flutterShellArgs) {
    Bundle args = new Bundle();
    args.putString(ARG_INITIAL_ROUTE, initialRoute);
    args.putString(ARG_APP_BUNDLE_PATH, appBundlePath);
    args.putString(ARG_DART_ENTRYPOINT, dartEntrypoint);
    // TODO(mattcarroll): determine if we should have an explicit FlutterTestFragment instead of conflating.
    if (null != flutterShellArgs) {
      args.putStringArray(ARG_FLUTTER_INITIALIZATION_ARGS, flutterShellArgs.toArray());
    }
    return args;
  }

  @Nullable
  private FlutterEngine flutterEngine;
  @Nullable
  private FlutterView flutterView;
  @Nullable
  private PlatformPlugin platformPlugin;

  public FlutterFragment() {
    // Ensure that we at least have an empty Bundle of arguments so that we don't
    // need to continually check for null arguments before grabbing one.
    setArguments(new Bundle());
  }

  /**
   * The {@link FlutterEngine} that backs the Flutter content presented by this {@code Fragment}.
   *
   * @return the {@link FlutterEngine} held by this {@code Fragment}
   */
  @Nullable
  public FlutterEngine getFlutterEngine() {
    return flutterEngine;
  }

  @Override
  public void onAttach(Context context) {
    super.onAttach(context);

    initializeFlutter(getContextCompat());

    // When "retain instance" is true, the FlutterEngine will survive configuration
    // changes. Therefore, we create a new one only if one does not already exist.
    if (flutterEngine == null) {
      createFlutterEngine();
    }

    // Regardless of whether or not a FlutterEngine already existed, the PlatformPlugin
    // is bound to a specific Activity. Therefore, it needs to be created and configured
    // every time this Fragment attaches to a new Activity.
    // TODO(mattcarroll): the PlatformPlugin needs to be reimagined because it implicitly takes
    //                    control of the entire window. This is unacceptable for non-fullscreen
    //                    use-cases.
    platformPlugin = new PlatformPlugin(getActivity(), flutterEngine.getPlatformChannel());
  }

  private void initializeFlutter(@NonNull Context context) {
    String[] flutterShellArgsArray = getArguments().getStringArray(ARG_FLUTTER_INITIALIZATION_ARGS);
    FlutterShellArgs flutterShellArgs = new FlutterShellArgs(
        flutterShellArgsArray != null ? flutterShellArgsArray : new String[] {}
    );

    FlutterMain.ensureInitializationComplete(context.getApplicationContext(), flutterShellArgs.toArray());
  }

  /**
   * Creates a new FlutterEngine instance.
   *
   * Subclasses can instantiate their own {@link FlutterEngine} by overriding
   * {@link #onCreateFlutterEngine(Context)}.
   *
   * Subclasses can alter the {@link FlutterEngine} after creation by overriding
   * {@link #onFlutterEngineCreated(FlutterEngine)}.
   */
  private void createFlutterEngine() {
    // Create a FlutterEngine to back our FlutterView.
    flutterEngine = onCreateFlutterEngine(getActivity());

    // Allow subclasses to customize FlutterEngine as desired.
    onFlutterEngineCreated(flutterEngine);
  }

  /**
   * Hook for subclasses to customize the creation of the {@code FlutterEngine}.
   *
   * By default, this method returns a standard {@link FlutterEngine} without any modification.
   */
  @NonNull
  protected FlutterEngine onCreateFlutterEngine(@NonNull Context context) {
    Log.d(TAG, "onCreateFlutterEngine()");
    return new FlutterEngine(context);
  }

  /**
   * Hook for subclasses to customize the {@link FlutterEngine} owned by this {@link FlutterFragment}
   * after the {@link FlutterEngine} has been instantiated.
   *
   * Consider using this method to connect desired Flutter plugins to this {@code Fragment}'s
   * {@link FlutterEngine}.
   */
  protected void onFlutterEngineCreated(@NonNull FlutterEngine flutterEngine) {
    // no-op
  }

  @Nullable
  @Override
  public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
    flutterView = new FlutterView(getContext());
    flutterView.attachToFlutterEngine(flutterEngine);

    // TODO(mattcarroll): the following call should exist here, but the plugin system needs to be revamped.
    //                    The existing attach() method does not know how to handle this kind of FlutterView.
    //flutterEngine.getPluginRegistry().attach(this, getActivity());

    doInitialFlutterViewRun();

    return flutterView;
  }

  /**
   * Starts running Dart within the FlutterView for the first time.
   *
   * Reloading/restarting Dart within a given FlutterView is not supported. If this method is
   * invoked while Dart is already executing then it does nothing.
   *
   * {@code flutterEngine} must be non-null when invoking this method.
   */
  private void doInitialFlutterViewRun() {
    if (flutterEngine.getDartExecutor().isExecutingDart()) {
      // No warning is logged because this situation will happen on every config
      // change if the developer does not choose to retain the Fragment instance.
      // So this is expected behavior in many cases.
      return;
    }

    // The engine needs to receive the Flutter app's initial route before executing any
    // Dart code to ensure that the initial route arrives in time to be applied.
    if (getInitialRoute() != null) {
      flutterEngine.getNavigationChannel().setInitialRoute(getInitialRoute());
    }

    // Configure the Dart entrypoint and execute it.
    DartExecutor.DartEntrypoint entrypoint = new DartExecutor.DartEntrypoint(
        getResources().getAssets(),
        getAppBundlePath(),
        getDartEntrypointFunctionName()
    );
    flutterEngine.getDartExecutor().executeDartEntrypoint(entrypoint);
  }

  /**
   * Returns the initial route that should be rendered within Flutter, once the Flutter app starts.
   *
   * Defaults to {@code null}, which signifies a route of "/" in Flutter.
   */
  @Nullable
  protected String getInitialRoute() {
    return getArguments().getString(ARG_INITIAL_ROUTE);
  }

  /**
   * Returns the file path to the desired Flutter app's bundle of code.
   *
   * Defaults to {@link FlutterMain#findAppBundlePath(Context)}.
   */
  @NonNull
  protected String getAppBundlePath() {
    return getArguments().getString(ARG_APP_BUNDLE_PATH, FlutterMain.findAppBundlePath(getContextCompat()));
  }

  /**
   * Returns the name of the Dart method that this {@code FlutterFragment} should execute to
   * start a Flutter app.
   *
   * Defaults to "main".
   */
  @NonNull
  protected String getDartEntrypointFunctionName() {
    return getArguments().getString(ARG_DART_ENTRYPOINT, "main");
  }

  // TODO(mattcarroll): determine why this can't be in onResume(). Comment reason, or move if possible.
  public void onPostResume() {
    Log.d(TAG, "onPostResume()");
    if (flutterEngine != null) {
      flutterEngine.getLifecycleChannel().appIsResumed();

      // TODO(mattcarroll): find a better way to handle the update of UI overlays than calling through
      //                    to platformPlugin. We're implicitly entangling the Window, Activity, Fragment,
      //                    and engine all with this one call.
      platformPlugin.onPostResume();
    } else {
      Log.w(TAG, "onPostResume() invoked before FlutterFragment was attached to an Activity.");
    }
  }

  @Override
  public void onPause() {
    super.onPause();
    Log.d(TAG, "onPause()");
    flutterEngine.getLifecycleChannel().appIsInactive();
  }

  @Override
  public void onStop() {
    super.onStop();
    Log.d(TAG, "onStop()");
    flutterEngine.getLifecycleChannel().appIsPaused();
  }

  @Override
  public void onDestroyView() {
    super.onDestroyView();
    Log.d(TAG, "onDestroyView()");
    flutterView.detachFromFlutterEngine();
  }

  @Override
  public void onDetach() {
    super.onDetach();
    Log.d(TAG, "onDetach()");

    // Null out the platformPlugin to avoid a possible retain cycle between the plugin, this Fragment,
    // and this Fragment's Activity.
    platformPlugin = null;

    // Destroy our FlutterEngine if we're not set to retain it.
    if (!retainFlutterIsolateAfterFragmentDestruction()) {
      flutterEngine.destroy();
      flutterEngine = null;
    }
  }

  /**
   * Returns true if the {@link FlutterEngine} within this {@code FlutterFragment} should outlive
   * the {@code FlutterFragment}, itself.
   *
   * Defaults to false. This method can be overridden in subclasses to retain the
   * {@link FlutterEngine}.
   */
  // TODO(mattcarroll): consider a dynamic determination of this preference based on whether the
  //                    engine was created automatically, or if the engine was provided manually.
  //                    Manually provided engines should probably not be destroyed.
  protected boolean retainFlutterIsolateAfterFragmentDestruction() {
    return false;
  }

  /**
   * The hardware back button was pressed.
   *
   * See {@link android.app.Activity#onBackPressed()}
   */
  public void onBackPressed() {
    Log.d(TAG, "onBackPressed()");
    if (flutterEngine != null) {
      flutterEngine.getNavigationChannel().popRoute();
    } else {
      Log.w(TAG, "Invoked onBackPressed() before FlutterFragment was attached to an Activity.");
    }
  }

  /**
   * The result of a permission request has been received.
   *
   * See {@link android.app.Activity#onRequestPermissionsResult(int, String[], int[])}
   *
   * @param requestCode identifier passed with the initial permission request
   * @param permissions permissions that were requested
   * @param grantResults permission grants or denials
   */
  public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    if (flutterEngine != null) {
      flutterEngine.getPluginRegistry().onRequestPermissionsResult(requestCode, permissions, grantResults);
    } else {
      Log.w(TAG, "onRequestPermissionResult() invoked before FlutterFragment was attached to an Activity.");
    }
  }

  /**
   * A new Intent was received by the {@link android.app.Activity} that currently owns this
   * {@link Fragment}.
   *
   * See {@link android.app.Activity#onNewIntent(Intent)}
   *
   * @param intent new Intent
   */
  public void onNewIntent(@NonNull Intent intent) {
    if (flutterEngine != null) {
      flutterEngine.getPluginRegistry().onNewIntent(intent);
    } else {
      Log.w(TAG, "onNewIntent() invoked before FlutterFragment was attached to an Activity.");
    }
  }

  /**
   * A result has been returned after an invocation of {@link Fragment#startActivityForResult(Intent, int)}.
   *
   * @param requestCode request code sent with {@link Fragment#startActivityForResult(Intent, int)}
   * @param resultCode code representing the result of the {@code Activity} that was launched
   * @param data any corresponding return data, held within an {@code Intent}
   */
  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (flutterEngine != null) {
      flutterEngine.getPluginRegistry().onActivityResult(requestCode, resultCode, data);
    } else {
      Log.w(TAG, "onActivityResult() invoked before FlutterFragment was attached to an Activity.");
    }
  }

  /**
   * The {@link android.app.Activity} that owns this {@link Fragment} is about to go to the background
   * as the result of a user's choice/action, i.e., not as the result of an OS decision.
   *
   * See {@link android.app.Activity#onUserLeaveHint()}
   */
  public void onUserLeaveHint() {
    if (flutterEngine != null) {
      flutterEngine.getPluginRegistry().onUserLeaveHint();
    } else {
      Log.w(TAG, "onUserLeaveHint() invoked before FlutterFragment was attached to an Activity.");
    }
  }

  /**
   * Callback invoked when memory is low.
   *
   * This implementation forwards a memory pressure warning to the running Flutter app.
   *
   * @param level level
   */
  public void onTrimMemory(int level) {
    if (flutterEngine != null) {
      // Use a trim level delivered while the application is running so the
      // framework has a chance to react to the notification.
      if (level == TRIM_MEMORY_RUNNING_LOW) {
        flutterEngine.getSystemChannel().sendMemoryPressureWarning();
      }
    } else {
      Log.w(TAG, "onTrimMemory() invoked before FlutterFragment was attached to an Activity.");
    }
  }

  /**
   * Callback invoked when memory is low.
   *
   * This implementation forwards a memory pressure warning to the running Flutter app.
   */
  @Override
  public void onLowMemory() {
    super.onLowMemory();
    flutterEngine.getSystemChannel().sendMemoryPressureWarning();
  }

  @NonNull
  private Context getContextCompat() {
    return Build.VERSION.SDK_INT >= 23
      ? getContext()
      : getActivity();
  }
}

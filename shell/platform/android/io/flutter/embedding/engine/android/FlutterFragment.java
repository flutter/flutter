// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.android;

import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;

import io.flutter.embedding.engine.FlutterShellArgs;

/**
 * {@code Fragment} which displays a Flutter UI that takes up all available {@code Fragment} space.
 * <p>
 * WARNING: THIS CLASS IS EXPERIMENTAL. DO NOT SHIP A DEPENDENCY ON THIS CODE.
 * IF YOU USE IT, WE WILL BREAK YOU.
 * <p>
 * Using a {@code FlutterFragment} requires forwarding a number of calls from an {@code Activity} to
 * ensure that the internal Flutter app behaves as expected:
 * <ol>
 *   <li>{@link Activity#onPostResume()}</li>
 *   <li>{@link Activity#onBackPressed()}</li>
 *   <li>{@link Activity#onRequestPermissionsResult(int, String[], int[])} ()}</li>
 *   <li>{@link Activity#onNewIntent(Intent)} ()}</li>
 *   <li>{@link Activity#onUserLeaveHint()}</li>
 *   <li>{@link Activity#onTrimMemory(int)}</li>
 * </ol>
 * Additionally, when starting an {@code Activity} for a result from this {@code Fragment}, be sure
 * to invoke {@link Fragment#startActivityForResult(Intent, int)} rather than
 * {@link Activity#startActivityForResult(Intent, int)}. If the {@code Activity} version of the
 * method is invoked then this {@code Fragment} will never receive its
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

  public FlutterFragment() {
    // Ensure that we at least have an empty Bundle of arguments so that we don't
    // need to continually check for null arguments before grabbing one.
    setArguments(new Bundle());
  }
}

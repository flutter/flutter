// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW;

import android.app.Activity;
import android.arch.lifecycle.Lifecycle;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.Arrays;

import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.renderer.OnFirstFrameRenderedListener;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.view.FlutterMain;

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

  protected static final String ARG_DART_ENTRYPOINT = "dart_entrypoint";
  protected static final String ARG_INITIAL_ROUTE = "initial_route";
  protected static final String ARG_APP_BUNDLE_PATH = "app_bundle_path";
  protected static final String ARG_FLUTTER_INITIALIZATION_ARGS = "initialization_args";
  protected static final String ARG_FLUTTERVIEW_RENDER_MODE = "flutterview_render_mode";
  protected static final String ARG_FLUTTERVIEW_TRANSPARENCY_MODE = "flutterview_transparency_mode";
  protected static final String ARG_SHOULD_ATTACH_ENGINE_TO_ACTIVITY = "should_attach_engine_to_activity";

  /**
   * Builder that creates a new {@code FlutterFragment} with {@code arguments} that correspond
   * to the values set on this {@code Builder}.
   * <p>
   * To create a {@code FlutterFragment} with default {@code arguments}, invoke {@code build()}
   * without setting any builder properties:
   * {@code
   *   FlutterFragment fragment = new FlutterFragment.Builder().build();
   * }
   * <p>
   * Subclasses of {@code FlutterFragment} that do not introduce any new arguments can use this
   * {@code Builder} to construct instances of the subclass without subclassing this {@code Builder}.
   * {@code
   *   MyFlutterFragment f = new FlutterFragment.Builder(MyFlutterFragment.class)
   *     .someProperty(...)
   *     .someOtherProperty(...)
   *     .build<MyFlutterFragment>();
   * }
   * <p>
   * Subclasses of {@code FlutterFragment} that introduce new arguments should subclass this
   * {@code Builder} to add the new properties:
   * <ol>
   *   <li>Ensure the {@code FlutterFragment} subclass has a no-arg constructor.</li>
   *   <li>Subclass this {@code Builder}.</li>
   *   <li>Override the new {@code Builder}'s no-arg constructor and invoke the super constructor
   *   to set the {@code FlutterFragment} subclass: {@code
   *     public MyBuilder() {
   *       super(MyFlutterFragment.class);
   *     }
   *   }</li>
   *   <li>Add appropriate property methods for the new properties.</li>
   *   <li>Override {@link Builder#createArgs()}, call through to the super method, then add
   *   the new properties as arguments in the {@link Bundle}.</li>
   * </ol>
   * Once a {@code Builder} subclass is defined, the {@code FlutterFragment} subclass can be
   * instantiated as follows.
   * {@code
   *   MyFlutterFragment f = new MyBuilder()
   *     .someExistingProperty(...)
   *     .someNewProperty(...)
   *     .build<MyFlutterFragment>();
   * }
   */
  public static class Builder {
    private final Class<? extends FlutterFragment> fragmentClass;
    private String dartEntrypoint = "main";
    private String initialRoute = "/";
    private String appBundlePath = null;
    private FlutterShellArgs shellArgs = null;
    private FlutterView.RenderMode renderMode = FlutterView.RenderMode.surface;
    private FlutterView.TransparencyMode transparencyMode = FlutterView.TransparencyMode.transparent;
    private boolean shouldAttachEngineToActivity = true;

    /**
     * Constructs a {@code Builder} that is configured to construct an instance of
     * {@code FlutterFragment}.
     */
    public Builder() {
      fragmentClass = FlutterFragment.class;
    }

    /**
     * Constructs a {@code Builder} that is configured to construct an instance of
     * {@code subclass}, which extends {@code FlutterFragment}.
     */
    public Builder(@NonNull Class<? extends FlutterFragment> subclass) {
      fragmentClass = subclass;
    }

    /**
     * The name of the initial Dart method to invoke, defaults to "main".
     */
    @NonNull
    public Builder dartEntrypoint(@NonNull String dartEntrypoint) {
      this.dartEntrypoint = dartEntrypoint;
      return this;
    }

    /**
     * The initial route that a Flutter app will render in this {@link FlutterFragment},
     * defaults to "/".
     */
    @NonNull
    public Builder initialRoute(@NonNull String initialRoute) {
      this.initialRoute = initialRoute;
      return this;
    }

    /**
     * The path to the app bundle which contains the Dart app to execute, defaults
     * to {@link FlutterMain#findAppBundlePath(Context)}
     */
    @NonNull
    public Builder appBundlePath(@NonNull String appBundlePath) {
      this.appBundlePath = appBundlePath;
      return this;
    }

    /**
     * Any special configuration arguments for the Flutter engine
     */
    @NonNull
    public Builder flutterShellArgs(@NonNull FlutterShellArgs shellArgs) {
      this.shellArgs = shellArgs;
      return this;
    }

    /**
     * Render Flutter either as a {@link FlutterView.RenderMode#surface} or a
     * {@link FlutterView.RenderMode#texture}. You should use {@code surface} unless
     * you have a specific reason to use {@code texture}. {@code texture} comes with
     * a significant performance impact, but {@code texture} can be displayed
     * beneath other Android {@code View}s and animated, whereas {@code surface}
     * cannot.
     */
    @NonNull
    public Builder renderMode(@NonNull FlutterView.RenderMode renderMode) {
      this.renderMode = renderMode;
      return this;
    }

    /**
     * Support a {@link FlutterView.TransparencyMode#transparent} background within {@link FlutterView},
     * or force an {@link FlutterView.TransparencyMode#opaque} background.
     * <p>
     * See {@link FlutterView.TransparencyMode} for implications of this selection.
     */
    @NonNull
    public Builder transparencyMode(@NonNull FlutterView.TransparencyMode transparencyMode) {
      this.transparencyMode = transparencyMode;
      return this;
    }

    /**
     * Whether or not this {@code FlutterFragment} should automatically attach its
     * {@code Activity} as a control surface for its {@link FlutterEngine}.
     * <p>
     * Control surfaces are used to provide Android resources and lifecycle events to
     * plugins that are attached to the {@link FlutterEngine}. If {@code shouldAttachEngineToActivity}
     * is true then this {@code FlutterFragment} will connect its {@link FlutterEngine} to the
     * surrounding {@code Activity}, along with any plugins that are registered with that
     * {@link FlutterEngine}. This allows plugins to access the {@code Activity}, as well as
     * receive {@code Activity}-specific calls, e.g., {@link android.app.Activity#onNewIntent(Intent)}.
     * If {@code shouldAttachEngineToActivity} is false, then this {@code FlutterFragment} will not
     * automatically manage the connection between its {@link FlutterEngine} and the surrounding
     * {@code Activity}. The {@code Activity} will need to be manually connected to this
     * {@code FlutterFragment}'s {@link FlutterEngine} by the app developer. See
     * {@link FlutterEngine#getActivityControlSurface()}.
     * <p>
     * One reason that a developer might choose to manually manage the relationship between the
     * {@code Activity} and {@link FlutterEngine} is if the developer wants to move the
     * {@link FlutterEngine} somewhere else. For example, a developer might want the
     * {@link FlutterEngine} to outlive the surrounding {@code Activity} so that it can be used
     * later in a different {@code Activity}. To accomplish this, the {@link FlutterEngine} will
     * need to be disconnected from the surrounding {@code Activity} at an unusual time, preventing
     * this {@code FlutterFragment} from correctly managing the relationship between the
     * {@link FlutterEngine} and the surrounding {@code Activity}.
     * <p>
     * Another reason that a developer might choose to manually manage the relationship between the
     * {@code Activity} and {@link FlutterEngine} is if the developer wants to prevent, or explicitly
     * control when the {@link FlutterEngine}'s plugins have access to the surrounding {@code Activity}.
     * For example, imagine that this {@code FlutterFragment} only takes up part of the screen and
     * the app developer wants to ensure that none of the Flutter plugins are able to manipulate
     * the surrounding {@code Activity}. In this case, the developer would not want the
     * {@link FlutterEngine} to have access to the {@code Activity}, which can be accomplished by
     * setting {@code shouldAttachEngineToActivity} to {@code false}.
     */
    @NonNull
    public Builder shouldAttachEngineToActivity(boolean shouldAttachEngineToActivity) {
      this.shouldAttachEngineToActivity = shouldAttachEngineToActivity;
      return this;
    }

    /**
     * Creates a {@link Bundle} of arguments that are assigned to the new {@code FlutterFragment}.
     * <p>
     * Subclasses should override this method to add new properties to the {@link Bundle}. Subclasses
     * must call through to the super method to collect all existing property values.
     */
    @NonNull
    protected Bundle createArgs() {
      Bundle args = new Bundle();
      args.putString(ARG_INITIAL_ROUTE, initialRoute);
      args.putString(ARG_APP_BUNDLE_PATH, appBundlePath);
      args.putString(ARG_DART_ENTRYPOINT, dartEntrypoint);
      // TODO(mattcarroll): determine if we should have an explicit FlutterTestFragment instead of conflating.
      if (null != shellArgs) {
        args.putStringArray(ARG_FLUTTER_INITIALIZATION_ARGS, shellArgs.toArray());
      }
      args.putString(ARG_FLUTTERVIEW_RENDER_MODE, renderMode != null ? renderMode.name() : FlutterView.RenderMode.surface.name());
      args.putString(ARG_FLUTTERVIEW_TRANSPARENCY_MODE, transparencyMode != null ? transparencyMode.name() : FlutterView.TransparencyMode.transparent.name());
      args.putBoolean(ARG_SHOULD_ATTACH_ENGINE_TO_ACTIVITY, shouldAttachEngineToActivity);
      return args;
    }

    /**
     * Constructs a new {@code FlutterFragment} (or a subclass) that is configured based on
     * properties set on this {@code Builder}.
     */
    @NonNull
    public <T extends FlutterFragment> T build() {
      try {
        @SuppressWarnings("unchecked")
        T frag = (T) fragmentClass.getDeclaredConstructor().newInstance();
        if (frag == null) {
          throw new RuntimeException("The FlutterFragment subclass sent in the constructor ("
              + fragmentClass.getCanonicalName() + ") does not match the expected return type.");
        }

        Bundle args = createArgs();
        frag.setArguments(args);

        return frag;
      } catch (Exception e) {
        throw new RuntimeException("Could not instantiate FlutterFragment subclass (" + fragmentClass.getName() + ")", e);
      }
    }
  }

  @Nullable
  private FlutterEngine flutterEngine;
  private boolean isFlutterEngineFromActivity;
  @Nullable
  private FlutterSplashView flutterSplashView;
  @Nullable
  private FlutterView flutterView;
  @Nullable
  private PlatformPlugin platformPlugin;

  private final OnFirstFrameRenderedListener onFirstFrameRenderedListener = new OnFirstFrameRenderedListener() {
    @Override
    public void onFirstFrameRendered() {
      // Notify our subclasses that the first frame has been rendered.
      FlutterFragment.this.onFirstFrameRendered();

      // Notify our owning Activity that the first frame has been rendered.
      FragmentActivity fragmentActivity = getActivity();
      if (fragmentActivity != null && fragmentActivity instanceof OnFirstFrameRenderedListener) {
        OnFirstFrameRenderedListener activityAsListener = (OnFirstFrameRenderedListener) fragmentActivity;
        activityAsListener.onFirstFrameRendered();
      }
    }
  };

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
  public void onAttach(@NonNull Context context) {
    super.onAttach(context);

    initializeFlutter(getContextCompat());

    // When "retain instance" is true, the FlutterEngine will survive configuration
    // changes. Therefore, we create a new one only if one does not already exist.
    if (flutterEngine == null) {
      setupFlutterEngine();
    }

    // Regardless of whether or not a FlutterEngine already existed, the PlatformPlugin
    // is bound to a specific Activity. Therefore, it needs to be created and configured
    // every time this Fragment attaches to a new Activity.
    // TODO(mattcarroll): the PlatformPlugin needs to be reimagined because it implicitly takes
    //                    control of the entire window. This is unacceptable for non-fullscreen
    //                    use-cases.
    platformPlugin = new PlatformPlugin(getActivity(), flutterEngine.getPlatformChannel());

    if (shouldAttachEngineToActivity()) {
      // Notify any plugins that are currently attached to our FlutterEngine that they
      // are now attached to an Activity.
      //
      // Passing this Fragment's Lifecycle should be sufficient because as long as this Fragment
      // is attached to its Activity, the lifecycles should be in sync. Once this Fragment is
      // detached from its Activity, that Activity will be detached from the FlutterEngine, too,
      // which means there shouldn't be any possibility for the Fragment Lifecycle to get out of
      // sync with the Activity. We use the Fragment's Lifecycle because it is possible that the
      // attached Activity is not a LifecycleOwner.
      Log.d(TAG, "Attaching FlutterEngine to the Activity that owns this Fragment.");
      flutterEngine.getActivityControlSurface().attachToActivity(
          getActivity(),
          getLifecycle()
      );
    }

    configureFlutterEngine(flutterEngine);
  }

  private void initializeFlutter(@NonNull Context context) {
    String[] flutterShellArgsArray = getArguments().getStringArray(ARG_FLUTTER_INITIALIZATION_ARGS);
    FlutterShellArgs flutterShellArgs = new FlutterShellArgs(
        flutterShellArgsArray != null ? flutterShellArgsArray : new String[] {}
    );

    FlutterMain.ensureInitializationComplete(context.getApplicationContext(), flutterShellArgs.toArray());
  }

  /**
   * Obtains a reference to a FlutterEngine to back this {@code FlutterFragment}.
   * <p>
   * First, {@code FlutterFragment} subclasses are given an opportunity to provide a
   * {@link FlutterEngine} by overriding {@link #createFlutterEngine(Context)}.
   * <p>
   * Second, the {@link FragmentActivity} that owns this {@code FlutterFragment} is
   * given the opportunity to provide a {@link FlutterEngine} as a {@link FlutterEngineProvider}.
   * <p>
   * If subclasses do not provide a {@link FlutterEngine}, and the owning {@link FragmentActivity}
   * does not implement {@link FlutterEngineProvider} or chooses to return {@code null}, then a new
   * {@link FlutterEngine} is instantiated.
   */
  private void setupFlutterEngine() {
    Log.d(TAG, "Setting up FlutterEngine.");

    // First, defer to subclasses for a custom FlutterEngine.
    flutterEngine = createFlutterEngine(getContextCompat());
    if (flutterEngine != null) {
      return;
    }

    // Second, defer to the FragmentActivity that owns us to see if it wants to provide a
    // FlutterEngine.
    FragmentActivity attachedActivity = getActivity();
    if (attachedActivity instanceof FlutterEngineProvider) {
      // Defer to the Activity that owns us to provide a FlutterEngine.
      Log.d(TAG, "Deferring to attached Activity to provide a FlutterEngine.");
      FlutterEngineProvider flutterEngineProvider = (FlutterEngineProvider) attachedActivity;
      flutterEngine = flutterEngineProvider.provideFlutterEngine(getContext());
      if (flutterEngine != null) {
        isFlutterEngineFromActivity = true;
        return;
      }
    }

    // Neither our subclass, nor our owning Activity wanted to provide a custom FlutterEngine.
    // Create a FlutterEngine to back our FlutterView.
    Log.d(TAG, "No preferred FlutterEngine was provided. Creating a new FlutterEngine for"
        + " this FlutterFragment.");
    flutterEngine = new FlutterEngine(getContext());
    isFlutterEngineFromActivity = false;
  }

  /**
   * Hook for subclasses to return a {@link FlutterEngine} with whatever configuration
   * is desired.
   * <p>
   * This method takes precedence for creation of a {@link FlutterEngine} over any owning
   * {@code Activity} that may implement {@link FlutterEngineProvider}.
   * <p>
   * Consider returning a cached {@link FlutterEngine} instance from this method to avoid the
   * typical warm-up time that a new {@link FlutterEngine} instance requires.
   * <p>
   * If null is returned then a new default {@link FlutterEngine} will be created to back this
   * {@code FlutterFragment}.
   */
  @Nullable
  protected FlutterEngine createFlutterEngine(@NonNull Context context) {
    return null;
  }

  /**
   * Configures a {@link FlutterEngine} after its creation.
   * <p>
   * This method is called after the given {@link FlutterEngine} has been attached to the
   * owning {@code FragmentActivity}. See
   * {@link io.flutter.embedding.engine.plugins.activity.ActivityControlSurface#attachToActivity(Activity, Lifecycle)}.
   * <p>
   * It is possible that the owning {@code FragmentActivity} opted not to connect itself as
   * an {@link io.flutter.embedding.engine.plugins.activity.ActivityControlSurface}. In that
   * case, any configuration, e.g., plugins, must not expect or depend upon an available
   * {@code Activity} at the time that this method is invoked.
   * <p>
   * The default behavior of this method is to defer to the owning {@code FragmentActivity}
   * as a {@link FlutterEngineConfigurator}. Subclasses can override this method if the
   * subclass needs to override the {@code FragmentActivity}'s behavior, or add to it.
   */
  protected void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    FragmentActivity attachedActivity = getActivity();
    if (attachedActivity instanceof FlutterEngineConfigurator) {
      ((FlutterEngineConfigurator) attachedActivity).configureFlutterEngine(flutterEngine);
    }
  }

  @Nullable
  @Override
  public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
    Log.v(TAG, "Creating FlutterView.");
    flutterView = new FlutterView(getActivity(), getRenderMode(), getTransparencyMode());
    flutterView.addOnFirstFrameRenderedListener(onFirstFrameRenderedListener);

    flutterSplashView = new FlutterSplashView(getContext());
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
      flutterSplashView.setId(View.generateViewId());
    } else {
      // TODO(mattcarroll): Find a better solution to this ID. This is a random, static ID.
      // It might conflict with other Views, and it means that only a single FlutterSplashView
      // can exist in a View hierarchy at one time.
      flutterSplashView.setId(486947586);
    }
    flutterSplashView.displayFlutterViewWithSplash(flutterView, provideSplashScreen());

    return flutterSplashView;
  }

  @Nullable
  protected SplashScreen provideSplashScreen() {
    FragmentActivity parentActivity = getActivity();
    if (parentActivity instanceof SplashScreenProvider) {
      SplashScreenProvider splashScreenProvider = (SplashScreenProvider) parentActivity;
      return splashScreenProvider.provideSplashScreen();
    }

    return null;
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

    Log.d(TAG, "Executing Dart entrypoint: " + getDartEntrypointFunctionName()
        + ", and sending initial route: " + getInitialRoute());

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

  /**
   * Returns the desired {@link FlutterView.RenderMode} for the {@link FlutterView} displayed in
   * this {@code FlutterFragment}.
   *
   * Defaults to {@link FlutterView.RenderMode#surface}.
   */
  @NonNull
  protected FlutterView.RenderMode getRenderMode() {
    String renderModeName = getArguments().getString(ARG_FLUTTERVIEW_RENDER_MODE, FlutterView.RenderMode.surface.name());
    return FlutterView.RenderMode.valueOf(renderModeName);
  }

  /**
   * Returns the desired {@link FlutterView.TransparencyMode} for the {@link FlutterView} displayed in
   * this {@code FlutterFragment}.
   * <p>
   * Defaults to {@link FlutterView.TransparencyMode#transparent}.
   */
  @NonNull
  protected FlutterView.TransparencyMode getTransparencyMode() {
    String transparencyModeName = getArguments().getString(ARG_FLUTTERVIEW_TRANSPARENCY_MODE, FlutterView.TransparencyMode.transparent.name());
    return FlutterView.TransparencyMode.valueOf(transparencyModeName);
  }

  @Override
  public void onStart() {
    super.onStart();
    Log.v(TAG, "onStart()");

    // We post() the code that attaches the FlutterEngine to our FlutterView because there is
    // some kind of blocking logic on the native side when the surface is connected. That lag
    // causes launching Activitys to wait a second or two before launching. By post()'ing this
    // behavior we are able to move this blocking logic to after the Activity's launch.
    // TODO(mattcarroll): figure out how to avoid blocking the MAIN thread when connecting a surface
    new Handler().post(new Runnable() {
      @Override
      public void run() {
        Log.v(TAG, "Attaching FlutterEngine to FlutterView.");
        flutterView.attachToFlutterEngine(flutterEngine);

        doInitialFlutterViewRun();
      }
    });
  }

  @Override
  public void onResume() {
    super.onResume();
    Log.v(TAG, "onResume()");
    flutterEngine.getLifecycleChannel().appIsResumed();
  }

  // TODO(mattcarroll): determine why this can't be in onResume(). Comment reason, or move if possible.
  public void onPostResume() {
    Log.v(TAG, "onPostResume()");
    if (flutterEngine != null) {
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
    Log.v(TAG, "onPause()");
    flutterEngine.getLifecycleChannel().appIsInactive();
  }

  @Override
  public void onStop() {
    super.onStop();
    Log.v(TAG, "onStop()");
    flutterEngine.getLifecycleChannel().appIsPaused();
    flutterView.detachFromFlutterEngine();
  }

  @Override
  public void onDestroyView() {
    super.onDestroyView();
    Log.v(TAG, "onDestroyView()");
    flutterView.removeOnFirstFrameRenderedListener(onFirstFrameRenderedListener);
  }

  @Override
  public void onDetach() {
    super.onDetach();
    Log.v(TAG, "onDetach()");

    if (shouldAttachEngineToActivity()) {
      // Notify plugins that they are no longer attached to an Activity.
      Log.d(TAG, "Detaching FlutterEngine from the Activity that owns this Fragment.");
      if (getActivity().isChangingConfigurations()) {
        flutterEngine.getActivityControlSurface().detachFromActivityForConfigChanges();
      } else {
        flutterEngine.getActivityControlSurface().detachFromActivity();
      }
    }

    // Null out the platformPlugin to avoid a possible retain cycle between the plugin, this Fragment,
    // and this Fragment's Activity.
    platformPlugin.destroy();
    platformPlugin = null;

    // Destroy our FlutterEngine if we're not set to retain it.
    if (!retainFlutterEngineAfterFragmentDestruction() && !isFlutterEngineFromActivity) {
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
  protected boolean retainFlutterEngineAfterFragmentDestruction() {
    return false;
  }

  protected boolean shouldAttachEngineToActivity() {
    return getArguments().getBoolean(ARG_SHOULD_ATTACH_ENGINE_TO_ACTIVITY);
  }

  /**
   * The hardware back button was pressed.
   *
   * See {@link android.app.Activity#onBackPressed()}
   */
  public void onBackPressed() {
    if (flutterEngine != null) {
      Log.v(TAG, "Forwarding onBackPressed() to FlutterEngine.");
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
      Log.v(TAG, "Forwarding onRequestPermissionsResult() to FlutterEngine:\n"
        + "requestCode: " + requestCode + "\n"
        + "permissions: " + Arrays.toString(permissions) + "\n"
        + "grantResults: " + Arrays.toString(grantResults));
      flutterEngine.getActivityControlSurface().onRequestPermissionsResult(requestCode, permissions, grantResults);
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
      Log.v(TAG, "Forwarding onNewIntent() to FlutterEngine.");
      flutterEngine.getActivityControlSurface().onNewIntent(intent);
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
      Log.v(TAG, "Forwarding onActivityResult() to FlutterEngine:\n"
          + "requestCode: " + requestCode + "\n"
          + "resultCode: " + resultCode + "\n"
          + "data: " + data);
      flutterEngine.getActivityControlSurface().onActivityResult(requestCode, resultCode, data);
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
      Log.v(TAG, "Forwarding onUserLeaveHint() to FlutterEngine.");
      flutterEngine.getActivityControlSurface().onUserLeaveHint();
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
        Log.v(TAG, "Forwarding onTrimMemory() to FlutterEngine. Level: " + level);
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
    Log.v(TAG, "Forwarding onLowMemory() to FlutterEngine.");
    flutterEngine.getSystemChannel().sendMemoryPressureWarning();
  }

  @NonNull
  private Context getContextCompat() {
    return Build.VERSION.SDK_INT >= 23
      ? getContext()
      : getActivity();
  }

  /**
   * Invoked after the {@link FlutterView} within this {@code FlutterFragment} renders its first
   * frame.
   * <p>
   * The owning {@code Activity} is also sent this message, if it implements
   * {@link OnFirstFrameRenderedListener}. This method is invoked before the {@code Activity}'s
   * version.
   */
  protected void onFirstFrameRendered() {}

  /**
   * Provides a {@link FlutterEngine} instance to be used by a {@code FlutterFragment}.
   * <p>
   * {@link FlutterEngine} instances require significant time to warm up. Therefore, a developer
   * might choose to hold onto an existing {@link FlutterEngine} and connect it to various
   * {@link FlutterActivity}s and/or {@code FlutterFragments}.
   * <p>
   * If the {@link FragmentActivity} that owns this {@code FlutterFragment} implements
   * {@code FlutterEngineProvider}, that {@link FragmentActivity} will be given an opportunity
   * to provide a {@link FlutterEngine} instead of the {@code FlutterFragment} creating a
   * new one. The {@link FragmentActivity} can provide an existing, pre-warmed {@link FlutterEngine},
   * if desired.
   * <p>
   * See {@link #setupFlutterEngine()} for more information.
   */
  public interface FlutterEngineProvider {
    /**
     * Returns the {@link FlutterEngine} that should be used by a child {@code FlutterFragment}.
     * <p>
     * This method may return a new {@link FlutterEngine}, an existing, cached {@link FlutterEngine},
     * or null to express that the {@code FlutterEngineProvider} would like the {@code FlutterFragment}
     * to provide its own {@code FlutterEngine} instance.
     */
    @Nullable
    FlutterEngine provideFlutterEngine(@NonNull Context context);
  }

  /**
   * Configures a {@link FlutterEngine} after it is created, e.g., adds plugins.
   * <p>
   * This interface may be applied to a {@link FragmentActivity} that owns a {@code FlutterFragment}.
   */
  public interface FlutterEngineConfigurator {
    /**
     * Configures the given {@link FlutterEngine}.
     * <p>
     * This method is called after the given {@link FlutterEngine} has been attached to the
     * owning {@code FragmentActivity}. See
     * {@link io.flutter.embedding.engine.plugins.activity.ActivityControlSurface#attachToActivity(Activity, Lifecycle)}.
     * <p>
     * It is possible that the owning {@code FragmentActivity} opted not to connect itself as
     * an {@link io.flutter.embedding.engine.plugins.activity.ActivityControlSurface}. In that
     * case, any configuration, e.g., plugins, must not expect or depend upon an available
     * {@code Activity} at the time that this method is invoked.
     */
    void configureFlutterEngine(@NonNull FlutterEngine flutterEngine);
  }

  /**
   * Provides a {@link SplashScreen} to display while Flutter initializes and renders its first
   * frame.
   */
  public interface SplashScreenProvider {
    /**
     * Provides a {@link SplashScreen} to display while Flutter initializes and renders its first
     * frame.
     */
    @Nullable
    SplashScreen provideSplashScreen();
  }
}

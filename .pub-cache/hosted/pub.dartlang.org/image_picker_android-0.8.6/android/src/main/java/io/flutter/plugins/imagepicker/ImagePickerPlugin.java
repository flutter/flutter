// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import java.io.File;

@SuppressWarnings("deprecation")
public class ImagePickerPlugin
    implements MethodChannel.MethodCallHandler, FlutterPlugin, ActivityAware {

  private class LifeCycleObserver
      implements Application.ActivityLifecycleCallbacks, DefaultLifecycleObserver {
    private final Activity thisActivity;

    LifeCycleObserver(Activity activity) {
      this.thisActivity = activity;
    }

    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {}

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {}

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {}

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {}

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
      onActivityStopped(thisActivity);
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
      onActivityDestroyed(thisActivity);
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {}

    @Override
    public void onActivityStarted(Activity activity) {}

    @Override
    public void onActivityResumed(Activity activity) {}

    @Override
    public void onActivityPaused(Activity activity) {}

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {}

    @Override
    public void onActivityDestroyed(Activity activity) {
      if (thisActivity == activity && activity.getApplicationContext() != null) {
        ((Application) activity.getApplicationContext())
            .unregisterActivityLifecycleCallbacks(
                this); // Use getApplicationContext() to avoid casting failures
      }
    }

    @Override
    public void onActivityStopped(Activity activity) {
      if (thisActivity == activity) {
        activityState.getDelegate().saveStateBeforeResult();
      }
    }
  }

  /**
   * Move all activity-lifetime-bound states into this helper object, so that {@code setup} and
   * {@code tearDown} would just become constructor and finalize calls of the helper object.
   */
  private class ActivityState {
    private Application application;
    private Activity activity;
    private ImagePickerDelegate delegate;
    private MethodChannel channel;
    private LifeCycleObserver observer;
    private ActivityPluginBinding activityBinding;

    // This is null when not using v2 embedding;
    private Lifecycle lifecycle;

    // Default constructor
    ActivityState(
        final Application application,
        final Activity activity,
        final BinaryMessenger messenger,
        final MethodChannel.MethodCallHandler handler,
        final PluginRegistry.Registrar registrar,
        final ActivityPluginBinding activityBinding) {
      this.application = application;
      this.activity = activity;
      this.activityBinding = activityBinding;

      delegate = constructDelegate(activity);
      channel = new MethodChannel(messenger, CHANNEL);
      channel.setMethodCallHandler(handler);
      observer = new LifeCycleObserver(activity);
      if (registrar != null) {
        // V1 embedding setup for activity listeners.
        application.registerActivityLifecycleCallbacks(observer);
        registrar.addActivityResultListener(delegate);
        registrar.addRequestPermissionsResultListener(delegate);
      } else {
        // V2 embedding setup for activity listeners.
        activityBinding.addActivityResultListener(delegate);
        activityBinding.addRequestPermissionsResultListener(delegate);
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(activityBinding);
        lifecycle.addObserver(observer);
      }
    }

    // Only invoked by {@link #ImagePickerPlugin(ImagePickerDelegate, Activity)} for testing.
    ActivityState(final ImagePickerDelegate delegate, final Activity activity) {
      this.activity = activity;
      this.delegate = delegate;
    }

    void release() {
      if (activityBinding != null) {
        activityBinding.removeActivityResultListener(delegate);
        activityBinding.removeRequestPermissionsResultListener(delegate);
        activityBinding = null;
      }

      if (lifecycle != null) {
        lifecycle.removeObserver(observer);
        lifecycle = null;
      }

      if (channel != null) {
        channel.setMethodCallHandler(null);
        channel = null;
      }

      if (application != null) {
        application.unregisterActivityLifecycleCallbacks(observer);
        application = null;
      }

      activity = null;
      observer = null;
      delegate = null;
    }

    Activity getActivity() {
      return activity;
    }

    ImagePickerDelegate getDelegate() {
      return delegate;
    }
  }

  static final String METHOD_CALL_IMAGE = "pickImage";
  static final String METHOD_CALL_MULTI_IMAGE = "pickMultiImage";
  static final String METHOD_CALL_VIDEO = "pickVideo";
  private static final String METHOD_CALL_RETRIEVE = "retrieve";
  private static final int CAMERA_DEVICE_FRONT = 1;
  private static final int CAMERA_DEVICE_REAR = 0;
  private static final String CHANNEL = "plugins.flutter.io/image_picker_android";

  private static final int SOURCE_CAMERA = 0;
  private static final int SOURCE_GALLERY = 1;

  private FlutterPluginBinding pluginBinding;
  private ActivityState activityState;

  @SuppressWarnings("deprecation")
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    if (registrar.activity() == null) {
      // If a background flutter view tries to register the plugin, there will be no activity from the registrar,
      // we stop the registering process immediately because the ImagePicker requires an activity.
      return;
    }
    Activity activity = registrar.activity();
    Application application = null;
    if (registrar.context() != null) {
      application = (Application) (registrar.context().getApplicationContext());
    }
    ImagePickerPlugin plugin = new ImagePickerPlugin();
    plugin.setup(registrar.messenger(), application, activity, registrar, null);
  }

  /**
   * Default constructor for the plugin.
   *
   * <p>Use this constructor for production code.
   */
  // See also: * {@link #ImagePickerPlugin(ImagePickerDelegate, Activity)} for testing.
  public ImagePickerPlugin() {}

  @VisibleForTesting
  ImagePickerPlugin(final ImagePickerDelegate delegate, final Activity activity) {
    activityState = new ActivityState(delegate, activity);
  }

  @VisibleForTesting
  final ActivityState getActivityState() {
    return activityState;
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    pluginBinding = binding;
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    pluginBinding = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    setup(
        pluginBinding.getBinaryMessenger(),
        (Application) pluginBinding.getApplicationContext(),
        binding.getActivity(),
        null,
        binding);
  }

  @Override
  public void onDetachedFromActivity() {
    tearDown();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  private void setup(
      final BinaryMessenger messenger,
      final Application application,
      final Activity activity,
      final PluginRegistry.Registrar registrar,
      final ActivityPluginBinding activityBinding) {
    activityState =
        new ActivityState(application, activity, messenger, this, registrar, activityBinding);
  }

  private void tearDown() {
    if (activityState != null) {
      activityState.release();
      activityState = null;
    }
  }

  @VisibleForTesting
  final ImagePickerDelegate constructDelegate(final Activity setupActivity) {
    final ImagePickerCache cache = new ImagePickerCache(setupActivity);

    final File externalFilesDirectory = setupActivity.getCacheDir();
    final ExifDataCopier exifDataCopier = new ExifDataCopier();
    final ImageResizer imageResizer = new ImageResizer(externalFilesDirectory, exifDataCopier);
    return new ImagePickerDelegate(setupActivity, externalFilesDirectory, imageResizer, cache);
  }

  // MethodChannel.Result wrapper that responds on the platform thread.
  private static class MethodResultWrapper implements MethodChannel.Result {
    private MethodChannel.Result methodResult;
    private Handler handler;

    MethodResultWrapper(MethodChannel.Result result) {
      methodResult = result;
      handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void success(final Object result) {
      handler.post(
          new Runnable() {
            @Override
            public void run() {
              methodResult.success(result);
            }
          });
    }

    @Override
    public void error(
        final String errorCode, final String errorMessage, final Object errorDetails) {
      handler.post(
          new Runnable() {
            @Override
            public void run() {
              methodResult.error(errorCode, errorMessage, errorDetails);
            }
          });
    }

    @Override
    public void notImplemented() {
      handler.post(
          new Runnable() {
            @Override
            public void run() {
              methodResult.notImplemented();
            }
          });
    }
  }

  @Override
  public void onMethodCall(MethodCall call, MethodChannel.Result rawResult) {
    if (activityState == null || activityState.getActivity() == null) {
      rawResult.error("no_activity", "image_picker plugin requires a foreground activity.", null);
      return;
    }
    MethodChannel.Result result = new MethodResultWrapper(rawResult);
    int imageSource;
    ImagePickerDelegate delegate = activityState.getDelegate();
    if (call.argument("cameraDevice") != null) {
      ImagePickerDelegate.CameraDevice device;
      int deviceIntValue = call.argument("cameraDevice");
      if (deviceIntValue == CAMERA_DEVICE_FRONT) {
        device = ImagePickerDelegate.CameraDevice.FRONT;
      } else {
        device = ImagePickerDelegate.CameraDevice.REAR;
      }
      delegate.setCameraDevice(device);
    }
    switch (call.method) {
      case METHOD_CALL_IMAGE:
        imageSource = call.argument("source");
        switch (imageSource) {
          case SOURCE_GALLERY:
            delegate.chooseImageFromGallery(call, result);
            break;
          case SOURCE_CAMERA:
            delegate.takeImageWithCamera(call, result);
            break;
          default:
            throw new IllegalArgumentException("Invalid image source: " + imageSource);
        }
        break;
      case METHOD_CALL_MULTI_IMAGE:
        delegate.chooseMultiImageFromGallery(call, result);
        break;
      case METHOD_CALL_VIDEO:
        imageSource = call.argument("source");
        switch (imageSource) {
          case SOURCE_GALLERY:
            delegate.chooseVideoFromGallery(call, result);
            break;
          case SOURCE_CAMERA:
            delegate.takeVideoWithCamera(call, result);
            break;
          default:
            throw new IllegalArgumentException("Invalid video source: " + imageSource);
        }
        break;
      case METHOD_CALL_RETRIEVE:
        delegate.retrieveLostImage(result);
        break;
      default:
        throw new IllegalArgumentException("Unknown method " + call.method);
    }
  }
}

package io.flutter.embedding.engine.plugins;

import android.app.Activity;
import android.content.pm.PackageManager;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Conceptual implementation of the Android side for handling local area permissions. This would be
 * integrated into the Android embedder or a plugin.
 */
public class AndroidLocalAreaConfig
    implements FlutterPlugin,
        MethodChannel.MethodCallHandler,
        ActivityAware,
        PluginRegistry.RequestPermissionsResultListener {

  private static final String CHANNEL_NAME = "plugins.flutter.io/android_local_area_config";
  private static final int PERMISSION_REQUEST_CODE = 1234; // Example code
  // The permission name in Android 17
  private static final String LOCAL_AREA_PERMISSION = "android.permission.ACCESS_LOCAL_NETWORK";

  private MethodChannel channel;
  private Activity activity;
  private MethodChannel.Result pendingResult;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (call.method.equals("requestLocalAreaAccess")) {
      handleRequestLocalAreaAccess(result);
    } else {
      result.notImplemented();
    }
  }

  private void handleRequestLocalAreaAccess(MethodChannel.Result result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Plugin is not attached to an activity", null);
      return;
    }

    // Check if permission is already granted
    if (ContextCompat.checkSelfPermission(activity, LOCAL_AREA_PERMISSION)
        == PackageManager.PERMISSION_GRANTED) {
      result.success(true);
      return;
    }

    // Save the pending result to answer after the user responds to the dialog
    pendingResult = result;

    // Request the permission
    ActivityCompat.requestPermissions(
        activity, new String[] {LOCAL_AREA_PERMISSION}, PERMISSION_REQUEST_CODE);
  }

  @Override
  public boolean onRequestPermissionsResult(
      int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    if (requestCode != PERMISSION_REQUEST_CODE) {
      return false;
    }

    if (pendingResult != null) {
      if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        pendingResult.success(true);
      } else {
        pendingResult.success(false);
      }
      pendingResult = null;
      return true;
    }

    return false;
  }

  // ActivityAware methods
  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this);
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }
}

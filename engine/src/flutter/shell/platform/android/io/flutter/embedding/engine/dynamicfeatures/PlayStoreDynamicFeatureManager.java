// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.dynamicfeatures;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.AssetManager;
import android.os.Build;
import android.util.SparseArray;
import android.util.SparseIntArray;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.play.core.splitinstall.SplitInstallException;
import com.google.android.play.core.splitinstall.SplitInstallManager;
import com.google.android.play.core.splitinstall.SplitInstallManagerFactory;
import com.google.android.play.core.splitinstall.SplitInstallRequest;
import com.google.android.play.core.splitinstall.SplitInstallSessionState;
import com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener;
import com.google.android.play.core.splitinstall.model.SplitInstallErrorCode;
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.systemchannels.DynamicFeatureChannel;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Queue;

/**
 * Flutter default implementation of DynamicFeatureManager that downloads dynamic feature modules
 * from the Google Play store.
 */
public class PlayStoreDynamicFeatureManager implements DynamicFeatureManager {
  private static final String TAG = "PlayStoreDynamicFeatureManager";

  private @NonNull SplitInstallManager splitInstallManager;
  private @Nullable FlutterJNI flutterJNI;
  private @Nullable DynamicFeatureChannel channel;
  private @NonNull Context context;
  // Each request to install a feature module gets a session ID. These maps associate
  // the session ID with the loading unit and module name that was requested.
  private @NonNull SparseArray<String> sessionIdToName;
  private @NonNull SparseIntArray sessionIdToLoadingUnitId;
  private @NonNull SparseArray<String> sessionIdToState;
  private @NonNull Map<String, Integer> nameToSessionId;

  private FeatureInstallStateUpdatedListener listener;

  private class FeatureInstallStateUpdatedListener implements SplitInstallStateUpdatedListener {
    @SuppressLint("DefaultLocale")
    public void onStateUpdate(SplitInstallSessionState state) {
      int sessionId = state.sessionId();
      if (sessionIdToName.get(sessionId) != null) {
        switch (state.status()) {
          case SplitInstallSessionStatus.FAILED:
            {
              Log.e(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) install failed with: %s",
                      sessionIdToName.get(sessionId), sessionId, state.errorCode()));
              flutterJNI.dynamicFeatureInstallFailure(
                  sessionIdToLoadingUnitId.get(sessionId),
                  "Module install failed with " + state.errorCode(),
                  true);
              if (channel != null) {
                channel.completeInstallError(
                    sessionIdToName.get(sessionId), "Android Dynamic Feature failed to install.");
              }
              sessionIdToName.delete(sessionId);
              sessionIdToLoadingUnitId.delete(sessionId);
              sessionIdToState.put(sessionId, "failed");
              break;
            }
          case SplitInstallSessionStatus.INSTALLED:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) install successfully.",
                      sessionIdToName.get(sessionId), sessionId));
              loadAssets(sessionIdToLoadingUnitId.get(sessionId), sessionIdToName.get(sessionId));
              // We only load Dart shared lib for the loading unit id requested. Other loading units
              // (if present) in the dynamic feature module are not loaded, but can be loaded by
              // calling again with their loading unit id. If no valid loadingUnitId was included in
              // the installation request such as for an asset only feature, then we can skip this.
              if (sessionIdToLoadingUnitId.get(sessionId) > 0) {
                loadDartLibrary(
                    sessionIdToLoadingUnitId.get(sessionId), sessionIdToName.get(sessionId));
              }
              if (channel != null) {
                channel.completeInstallSuccess(sessionIdToName.get(sessionId));
              }
              sessionIdToName.delete(sessionId);
              sessionIdToLoadingUnitId.delete(sessionId);
              sessionIdToState.put(sessionId, "installed");
              break;
            }
          case SplitInstallSessionStatus.CANCELED:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) install canceled.",
                      sessionIdToName.get(sessionId), sessionId));
              if (channel != null) {
                channel.completeInstallError(
                    sessionIdToName.get(sessionId),
                    "Android Dynamic Feature installation canceled.");
              }
              sessionIdToName.delete(sessionId);
              sessionIdToLoadingUnitId.delete(sessionId);
              sessionIdToState.put(sessionId, "cancelled");
              break;
            }
          case SplitInstallSessionStatus.CANCELING:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) install canceling.",
                      sessionIdToName.get(sessionId), sessionId));
              sessionIdToState.put(sessionId, "canceling");
              break;
            }
          case SplitInstallSessionStatus.PENDING:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) install pending.",
                      sessionIdToName.get(sessionId), sessionId));
              sessionIdToState.put(sessionId, "pending");
              break;
            }
          case SplitInstallSessionStatus.REQUIRES_USER_CONFIRMATION:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) install requires user confirmation.",
                      sessionIdToName.get(sessionId), sessionId));
              sessionIdToState.put(sessionId, "requires_user_confirmation");
              break;
            }
          case SplitInstallSessionStatus.DOWNLOADING:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) downloading.",
                      sessionIdToName.get(sessionId), sessionId));
              sessionIdToState.put(sessionId, "downloading");
              break;
            }
          case SplitInstallSessionStatus.DOWNLOADED:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) downloaded.",
                      sessionIdToName.get(sessionId), sessionId));
              sessionIdToState.put(sessionId, "downloaded");
              break;
            }
          case SplitInstallSessionStatus.INSTALLING:
            {
              Log.d(
                  TAG,
                  String.format(
                      "Module \"%s\" (sessionId %d) installing.",
                      sessionIdToName.get(sessionId), sessionId));
              sessionIdToState.put(sessionId, "installing");
              break;
            }
          default:
            Log.d(TAG, "Unknown status: " + state.status());
        }
      }
    }
  }

  public PlayStoreDynamicFeatureManager(@NonNull Context context, @Nullable FlutterJNI flutterJNI) {
    this.context = context;
    this.flutterJNI = flutterJNI;
    splitInstallManager = SplitInstallManagerFactory.create(context);
    listener = new FeatureInstallStateUpdatedListener();
    splitInstallManager.registerListener(listener);
    sessionIdToName = new SparseArray<>();
    sessionIdToLoadingUnitId = new SparseIntArray();
    sessionIdToState = new SparseArray<>();
    nameToSessionId = new HashMap<>();
  }

  public void setJNI(@NonNull FlutterJNI flutterJNI) {
    this.flutterJNI = flutterJNI;
  }

  private boolean verifyJNI() {
    if (flutterJNI == null) {
      Log.e(
          TAG,
          "No FlutterJNI provided. `setJNI` must be called on the DynamicFeatureManager before attempting to load dart libraries or invoking with platform channels.");
      return false;
    }
    return true;
  }

  public void setDynamicFeatureChannel(DynamicFeatureChannel channel) {
    this.channel = channel;
  }

  private String loadingUnitIdToModuleName(int loadingUnitId) {
    // Loading unit id to module name mapping stored in android Strings
    // resources.
    int moduleNameIdentifier =
        context
            .getResources()
            .getIdentifier("loadingUnit" + loadingUnitId, "string", context.getPackageName());
    return context.getResources().getString(moduleNameIdentifier);
  }

  public void installDynamicFeature(int loadingUnitId, String moduleName) {
    String resolvedModuleName =
        moduleName != null ? moduleName : loadingUnitIdToModuleName(loadingUnitId);
    if (resolvedModuleName == null) {
      Log.e(
          TAG,
          "Dynamic feature module name was null and could not be resolved from loading unit id.");
      return;
    }

    SplitInstallRequest request =
        SplitInstallRequest.newBuilder().addModule(resolvedModuleName).build();

    splitInstallManager
        // Submits the request to install the module through the
        // asynchronous startInstall() task. Your app needs to be
        // in the foreground to submit the request.
        .startInstall(request)
        // Called when the install request is sent successfully. This is different than a successful
        // install which is handled in FeatureInstallStateUpdatedListener.
        .addOnSuccessListener(
            sessionId -> {
              sessionIdToName.put(sessionId, resolvedModuleName);
              sessionIdToLoadingUnitId.put(sessionId, loadingUnitId);
              if (nameToSessionId.containsKey(resolvedModuleName)) {
                sessionIdToState.remove(nameToSessionId.get(resolvedModuleName));
              }
              nameToSessionId.put(resolvedModuleName, sessionId);
              sessionIdToState.put(sessionId, "Requested");
            })
        .addOnFailureListener(
            exception -> {
              switch (((SplitInstallException) exception).getErrorCode()) {
                case SplitInstallErrorCode.NETWORK_ERROR:
                  flutterJNI.dynamicFeatureInstallFailure(
                      loadingUnitId,
                      String.format(
                          "Install of dynamic feature module \"%s\" failed with a network error",
                          moduleName),
                      true);
                  break;
                case SplitInstallErrorCode.MODULE_UNAVAILABLE:
                  flutterJNI.dynamicFeatureInstallFailure(
                      loadingUnitId,
                      String.format(
                          "Install of dynamic feature module \"%s\" failed as it is unavailable",
                          moduleName),
                      false);
                  break;
                default:
                  flutterJNI.dynamicFeatureInstallFailure(
                      loadingUnitId,
                      String.format(
                          "Install of dynamic feature module \"%s\" failed with error %d: %s",
                          moduleName,
                          ((SplitInstallException) exception).getErrorCode(),
                          ((SplitInstallException) exception).getMessage()),
                      false);
                  break;
              }
            });
  }

  public String getDynamicFeatureInstallState(int loadingUnitId, String moduleName) {
    String resolvedModuleName =
        moduleName != null ? moduleName : loadingUnitIdToModuleName(loadingUnitId);
    if (resolvedModuleName == null) {
      Log.e(
          TAG,
          "Dynamic feature module name was null and could not be resolved from loading unit id.");
      return null;
    }
    if (!nameToSessionId.containsKey(resolvedModuleName)) {
      return null;
    }
    int sessionId = nameToSessionId.get(resolvedModuleName);
    return sessionIdToState.get(sessionId);
  }

  public void loadAssets(int loadingUnitId, String moduleName) {
    if (!verifyJNI()) {
      return;
    }
    // Since android dynamic feature asset manager is handled through
    // context, neither parameter is used here. Assets are stored in
    // the apk's `assets` directory allowing them to be accessed by
    // Android's AssetManager directly.
    try {
      context = context.createPackageContext(context.getPackageName(), 0);

      AssetManager assetManager = context.getAssets();
      flutterJNI.updateAssetManager(
          assetManager,
          // TODO(garyq): Made the "flutter_assets" directory dynamic based off of DartEntryPoint.
          "flutter_assets");
    } catch (NameNotFoundException e) {
      throw new RuntimeException(e);
    }
  }

  public void loadDartLibrary(int loadingUnitId, String moduleName) {
    if (!verifyJNI()) {
      return;
    }
    // Loading unit must be specified and valid to load a dart library.
    if (loadingUnitId < 0) {
      return;
    }

    // This matches/depends on dart's loading unit naming convention, which we use unchanged.
    String aotSharedLibraryName = "app.so-" + loadingUnitId + ".part.so";

    // Possible values: armeabi, armeabi-v7a, arm64-v8a, x86, x86_64, mips, mips64
    String abi;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      abi = Build.SUPPORTED_ABIS[0];
    } else {
      abi = Build.CPU_ABI;
    }
    String pathAbi = abi.replace("-", "_"); // abis are represented with underscores in paths.

    // TODO(garyq): Optimize this apk/file discovery process to use less i/o and be more
    // performant and robust.

    // Search directly in APKs first
    List<String> apkPaths = new ArrayList<>();
    // If not found in APKs, we check in extracted native libs for the lib directly.
    List<String> soPaths = new ArrayList<>();
    Queue<File> searchFiles = new LinkedList<>();
    searchFiles.add(context.getFilesDir());
    while (!searchFiles.isEmpty()) {
      File file = searchFiles.remove();
      if (file != null && file.isDirectory()) {
        for (File f : file.listFiles()) {
          searchFiles.add(f);
        }
        continue;
      }
      String name = file.getName();
      if (name.endsWith(".apk") && name.startsWith(moduleName) && name.contains(pathAbi)) {
        apkPaths.add(file.getAbsolutePath());
        continue;
      }
      if (name.equals(aotSharedLibraryName)) {
        soPaths.add(file.getAbsolutePath());
      }
    }

    List<String> searchPaths = new ArrayList<>();
    for (String path : apkPaths) {
      searchPaths.add(path + "!lib/" + abi + "/" + aotSharedLibraryName);
    }
    for (String path : soPaths) {
      searchPaths.add(path);
    }

    flutterJNI.loadDartDeferredLibrary(
        loadingUnitId, searchPaths.toArray(new String[apkPaths.size()]));
  }

  public void uninstallFeature(int loadingUnitId, String moduleName) {
    // TODO(garyq): support uninstalling.
  }

  public void destroy() {
    splitInstallManager.unregisterListener(listener);
    channel = null;
    flutterJNI = null;
  }
}

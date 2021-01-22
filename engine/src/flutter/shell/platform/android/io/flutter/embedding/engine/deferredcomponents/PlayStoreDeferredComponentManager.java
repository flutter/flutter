// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.deferredcomponents;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.AssetManager;
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
import io.flutter.embedding.engine.loader.ApplicationInfoLoader;
import io.flutter.embedding.engine.loader.FlutterApplicationInfo;
import io.flutter.embedding.engine.systemchannels.DeferredComponentChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Flutter default implementation of DeferredComponentManager that downloads deferred component
 * modules from the Google Play store.
 */
public class PlayStoreDeferredComponentManager implements DeferredComponentManager {
  private static final String TAG = "PlayStoreDeferredComponentManager";

  private @NonNull SplitInstallManager splitInstallManager;
  private @Nullable FlutterJNI flutterJNI;
  private @Nullable DeferredComponentChannel channel;
  private @NonNull Context context;
  private @NonNull FlutterApplicationInfo flutterApplicationInfo;
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
              flutterJNI.deferredComponentInstallFailure(
                  sessionIdToLoadingUnitId.get(sessionId),
                  "Module install failed with " + state.errorCode(),
                  true);
              if (channel != null) {
                channel.completeInstallError(
                    sessionIdToName.get(sessionId),
                    "Android Deferred Component failed to install.");
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
              // (if present) in the deferred component module are not loaded, but can be loaded by
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
                    "Android Deferred Component installation canceled.");
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
              sessionIdToState.put(sessionId, "requiresUserConfirmation");
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

  public PlayStoreDeferredComponentManager(
      @NonNull Context context, @Nullable FlutterJNI flutterJNI) {
    this.context = context;
    this.flutterJNI = flutterJNI;
    this.flutterApplicationInfo = ApplicationInfoLoader.load(context);
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
          "No FlutterJNI provided. `setJNI` must be called on the DeferredComponentManager before attempting to load dart libraries or invoking with platform channels.");
      return false;
    }
    return true;
  }

  public void setDeferredComponentChannel(DeferredComponentChannel channel) {
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

  public void installDeferredComponent(int loadingUnitId, String moduleName) {
    String resolvedModuleName =
        moduleName != null ? moduleName : loadingUnitIdToModuleName(loadingUnitId);
    if (resolvedModuleName == null) {
      Log.e(
          TAG,
          "Deferred component module name was null and could not be resolved from loading unit id.");
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
                  flutterJNI.deferredComponentInstallFailure(
                      loadingUnitId,
                      String.format(
                          "Install of deferred component module \"%s\" failed with a network error",
                          moduleName),
                      true);
                  break;
                case SplitInstallErrorCode.MODULE_UNAVAILABLE:
                  flutterJNI.deferredComponentInstallFailure(
                      loadingUnitId,
                      String.format(
                          "Install of deferred component module \"%s\" failed as it is unavailable",
                          moduleName),
                      false);
                  break;
                default:
                  flutterJNI.deferredComponentInstallFailure(
                      loadingUnitId,
                      String.format(
                          "Install of deferred component module \"%s\" failed with error %d: %s",
                          moduleName,
                          ((SplitInstallException) exception).getErrorCode(),
                          ((SplitInstallException) exception).getMessage()),
                      false);
                  break;
              }
            });
  }

  public String getDeferredComponentInstallState(int loadingUnitId, String moduleName) {
    String resolvedModuleName =
        moduleName != null ? moduleName : loadingUnitIdToModuleName(loadingUnitId);
    if (resolvedModuleName == null) {
      Log.e(
          TAG,
          "Deferred component module name was null and could not be resolved from loading unit id.");
      return "unknown";
    }
    if (!nameToSessionId.containsKey(resolvedModuleName)) {
      if (splitInstallManager.getInstalledModules().contains(resolvedModuleName)) {
        return "installedPendingLoad";
      }
      return "unknown";
    }
    int sessionId = nameToSessionId.get(resolvedModuleName);
    return sessionIdToState.get(sessionId);
  }

  public void loadAssets(int loadingUnitId, String moduleName) {
    if (!verifyJNI()) {
      return;
    }
    // Since android deferred component asset manager is handled through
    // context, neither parameter is used here. Assets are stored in
    // the apk's `assets` directory allowing them to be accessed by
    // Android's AssetManager directly.
    try {
      context = context.createPackageContext(context.getPackageName(), 0);

      AssetManager assetManager = context.getAssets();
      flutterJNI.updateJavaAssetManager(assetManager, flutterApplicationInfo.flutterAssetsDir);
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
    String aotSharedLibraryName =
        flutterApplicationInfo.aotSharedLibraryName + "-" + loadingUnitId + ".part.so";

    flutterJNI.loadDartDeferredLibrary(loadingUnitId, aotSharedLibraryName);
  }

  public boolean uninstallDeferredComponent(int loadingUnitId, String moduleName) {
    String resolvedModuleName =
        moduleName != null ? moduleName : loadingUnitIdToModuleName(loadingUnitId);
    if (resolvedModuleName == null) {
      Log.e(
          TAG,
          "Deferred component module name was null and could not be resolved from loading unit id.");
      return false;
    }
    List<String> modulesToUninstall = new ArrayList<>();
    modulesToUninstall.add(resolvedModuleName);
    splitInstallManager.deferredUninstall(modulesToUninstall);
    sessionIdToState.delete(nameToSessionId.get(resolvedModuleName));
    return true;
  }

  public void destroy() {
    splitInstallManager.unregisterListener(listener);
    channel = null;
    flutterJNI = null;
  }
}

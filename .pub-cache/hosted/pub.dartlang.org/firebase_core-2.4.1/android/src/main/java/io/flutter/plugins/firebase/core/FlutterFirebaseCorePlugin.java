// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.firebase.core;

import static io.flutter.plugins.firebase.core.FlutterFirebasePlugin.cachedThreadPool;

import android.content.Context;
import android.os.Looper;
import androidx.annotation.NonNull;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import java.util.ArrayList;
import java.util.List;

/**
 * Flutter plugin implementation controlling the entrypoint for the Firebase SDK.
 *
 * <p>Instantiate this in an add to app scenario to gracefully handle activity and context changes.
 */
public class FlutterFirebaseCorePlugin
    implements FlutterPlugin,
        GeneratedAndroidFirebaseCore.FirebaseCoreHostApi,
        GeneratedAndroidFirebaseCore.FirebaseAppHostApi {
  private Context applicationContext;
  private boolean coreInitialized = false;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    GeneratedAndroidFirebaseCore.FirebaseCoreHostApi.setup(binding.getBinaryMessenger(), this);
    GeneratedAndroidFirebaseCore.FirebaseAppHostApi.setup(binding.getBinaryMessenger(), this);
    applicationContext = binding.getApplicationContext();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    applicationContext = null;
    GeneratedAndroidFirebaseCore.FirebaseCoreHostApi.setup(binding.getBinaryMessenger(), null);
    GeneratedAndroidFirebaseCore.FirebaseAppHostApi.setup(binding.getBinaryMessenger(), null);
  }

  private GeneratedAndroidFirebaseCore.PigeonFirebaseOptions firebaseOptionsToMap(
      FirebaseOptions options) {
    GeneratedAndroidFirebaseCore.PigeonFirebaseOptions.Builder firebaseOptions =
        new GeneratedAndroidFirebaseCore.PigeonFirebaseOptions.Builder();

    firebaseOptions.setApiKey(options.getApiKey());
    firebaseOptions.setAppId(options.getApplicationId());
    if (options.getGcmSenderId() != null) {
      firebaseOptions.setMessagingSenderId(options.getGcmSenderId());
    }
    if (options.getProjectId() != null) {
      firebaseOptions.setProjectId(options.getProjectId());
    }
    firebaseOptions.setDatabaseURL(options.getDatabaseUrl());
    firebaseOptions.setStorageBucket(options.getStorageBucket());
    firebaseOptions.setTrackingId(options.getGaTrackingId());

    return firebaseOptions.build();
  }

  private Task<GeneratedAndroidFirebaseCore.PigeonInitializeResponse> firebaseAppToMap(
      FirebaseApp firebaseApp) {
    TaskCompletionSource<GeneratedAndroidFirebaseCore.PigeonInitializeResponse>
        taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            GeneratedAndroidFirebaseCore.PigeonInitializeResponse.Builder initializeResponse =
                new GeneratedAndroidFirebaseCore.PigeonInitializeResponse.Builder();

            initializeResponse.setName(firebaseApp.getName());
            initializeResponse.setOptions(firebaseOptionsToMap(firebaseApp.getOptions()));

            initializeResponse.setIsAutomaticDataCollectionEnabled(
                firebaseApp.isDataCollectionDefaultEnabled());
            initializeResponse.setPluginConstants(
                Tasks.await(
                    FlutterFirebasePluginRegistry.getPluginConstantsForFirebaseApp(firebaseApp)));

            taskCompletionSource.setResult(initializeResponse.build());
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    return taskCompletionSource.getTask();
  }

  private <T> void listenToResponse(
      TaskCompletionSource<T> taskCompletionSource, GeneratedAndroidFirebaseCore.Result<T> result) {
    taskCompletionSource
        .getTask()
        .addOnCompleteListener(
            task -> {
              if (task.isSuccessful()) {
                result.success(task.getResult());
              } else {
                Exception exception = task.getException();
                result.error(exception);
              }
            });
  }

  @Override
  public void initializeApp(
      @NonNull String appName,
      @NonNull GeneratedAndroidFirebaseCore.PigeonFirebaseOptions initializeAppRequest,
      GeneratedAndroidFirebaseCore.Result<GeneratedAndroidFirebaseCore.PigeonInitializeResponse>
          result) {
    TaskCompletionSource<GeneratedAndroidFirebaseCore.PigeonInitializeResponse>
        taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {

            FirebaseOptions options =
                new FirebaseOptions.Builder()
                    .setApiKey(initializeAppRequest.getApiKey())
                    .setApplicationId(initializeAppRequest.getAppId())
                    .setDatabaseUrl(initializeAppRequest.getDatabaseURL())
                    .setGcmSenderId(initializeAppRequest.getMessagingSenderId())
                    .setProjectId(initializeAppRequest.getProjectId())
                    .setStorageBucket(initializeAppRequest.getStorageBucket())
                    .setGaTrackingId(initializeAppRequest.getTrackingId())
                    .build();
            // TODO(Salakar) hacky workaround a bug with FirebaseInAppMessaging causing the error:
            //    Can't create handler inside thread Thread[pool-3-thread-1,5,main] that has not called Looper.prepare()
            //     at com.google.firebase.inappmessaging.internal.ForegroundNotifier.<init>(ForegroundNotifier.java:61)
            try {
              Looper.prepare();
            } catch (Exception e) {
              // do nothing
            }
            FirebaseApp firebaseApp =
                FirebaseApp.initializeApp(applicationContext, options, appName);
            taskCompletionSource.setResult(Tasks.await(firebaseAppToMap(firebaseApp)));
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    listenToResponse(taskCompletionSource, result);
  }

  @Override
  public void initializeCore(
      GeneratedAndroidFirebaseCore.Result<
              List<GeneratedAndroidFirebaseCore.PigeonInitializeResponse>>
          result) {
    TaskCompletionSource<List<GeneratedAndroidFirebaseCore.PigeonInitializeResponse>>
        taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            if (!coreInitialized) {
              coreInitialized = true;
            } else {
              Tasks.await(FlutterFirebasePluginRegistry.didReinitializeFirebaseCore());
            }

            List<FirebaseApp> firebaseApps = FirebaseApp.getApps(applicationContext);
            List<GeneratedAndroidFirebaseCore.PigeonInitializeResponse> firebaseAppsList =
                new ArrayList<>(firebaseApps.size());

            for (FirebaseApp firebaseApp : firebaseApps) {
              firebaseAppsList.add(Tasks.await(firebaseAppToMap(firebaseApp)));
            }

            taskCompletionSource.setResult(firebaseAppsList);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    listenToResponse(taskCompletionSource, result);
  }

  @Override
  public void optionsFromResource(
      GeneratedAndroidFirebaseCore.Result<GeneratedAndroidFirebaseCore.PigeonFirebaseOptions>
          result) {
    TaskCompletionSource<GeneratedAndroidFirebaseCore.PigeonFirebaseOptions> taskCompletionSource =
        new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            final FirebaseOptions options = FirebaseOptions.fromResource(applicationContext);
            if (options == null) {
              taskCompletionSource.setResult(null);
              return;
            }
            taskCompletionSource.setResult(firebaseOptionsToMap(options));
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    listenToResponse(taskCompletionSource, result);
  }

  @Override
  public void setAutomaticDataCollectionEnabled(
      @NonNull String appName,
      @NonNull Boolean enabled,
      GeneratedAndroidFirebaseCore.Result<Void> result) {
    TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
            firebaseApp.setDataCollectionDefaultEnabled(enabled);

            taskCompletionSource.setResult(null);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    listenToResponse(taskCompletionSource, result);
  }

  @Override
  public void setAutomaticResourceManagementEnabled(
      @NonNull String appName,
      @NonNull Boolean enabled,
      GeneratedAndroidFirebaseCore.Result<Void> result) {
    TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
            firebaseApp.setAutomaticResourceManagementEnabled(enabled);

            taskCompletionSource.setResult(null);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    listenToResponse(taskCompletionSource, result);
  }

  @Override
  public void delete(@NonNull String appName, GeneratedAndroidFirebaseCore.Result<Void> result) {
    TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
            try {
              firebaseApp.delete();
            } catch (IllegalStateException appNotFoundException) {
              // Ignore app not found exceptions.
            }

            taskCompletionSource.setResult(null);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    listenToResponse(taskCompletionSource, result);
  }
}

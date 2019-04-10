package io.flutter.androidembedding;

import android.app.Application;
import android.os.Handler;
import android.util.Log;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.view.FlutterMain;

public class App extends Application {
  private static final String TAG = "App";

  public FlutterEngine cachedEngine;

  @Override
  public void onCreate() {
    Log.d(TAG, "onCreate()");
    super.onCreate();
    Log.d(TAG, "startInitialization");
    FlutterMain.startInitialization(this);

    Log.d(TAG, "ensureInitializationComplete");
    FlutterMain.ensureInitializationComplete(this, new String[]{});
    setupCachedEngine();

//    Log.d(TAG, "ensureInitializationCompleteAsync");
//    FlutterMain.ensureInitializationCompleteAsync(this, new String[]{}, new Handler(), new Runnable() {
//      @Override
//      public void run() {
//        setupCachedEngine();
//      }
//    });
    Log.d(TAG, "Done with onCreate");
  }

  private void setupCachedEngine() {
    cachedEngine = new FlutterEngine(this);
    doInitialFlutterViewRun();
    Log.d(TAG, "Done creating FlutterEngine");
  }

  private void doInitialFlutterViewRun() {
    cachedEngine.getNavigationChannel().setInitialRoute("/");

    // Configure the Dart entrypoint and execute it.
    DartExecutor.DartEntrypoint entrypoint = new DartExecutor.DartEntrypoint(
        getResources().getAssets(),
        FlutterMain.findAppBundlePath(this),
        "fullscreenFlutter"
    );
    cachedEngine.getDartExecutor().executeDartEntrypoint(entrypoint);
  }
}

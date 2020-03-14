package dev.flutter.scenarios;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryCodec;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;

public class TextPlatformViewActivity extends FlutterActivity {
  static final String TAG = "Scenarios";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    final Intent launchIntent = getIntent();
    if ("com.google.intent.action.TEST_LOOP".equals(launchIntent.getAction())) {
      if (Build.VERSION.SDK_INT > 22) {
        requestPermissions(new String[] {Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
      }
      // Run for one minute, get the timeline data, write it, and finish.
      final Uri logFileUri = launchIntent.getData();
      new Handler()
          .postDelayed(
              new Runnable() {
                @Override
                public void run() {
                  writeTimelineData(logFileUri);

                  testFlutterLoaderCallbackWhenInitializedTwice();
                }
              },
              20000);
    } else {
      testFlutterLoaderCallbackWhenInitializedTwice();
    }
  }

  @Override
  @NonNull
  public FlutterShellArgs getFlutterShellArgs() {
    FlutterShellArgs args = FlutterShellArgs.fromIntent(getIntent());
    args.add(FlutterShellArgs.ARG_TRACE_STARTUP);
    args.add(FlutterShellArgs.ARG_ENABLE_DART_PROFILING);
    args.add(FlutterShellArgs.ARG_VERBOSE_LOGGING);

    return args;
  }

  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    flutterEngine
        .getPlatformViewsController()
        .getRegistry()
        .registerViewFactory("scenarios/textPlatformView", new TextPlatformViewFactory());
  }

  private void writeTimelineData(Uri logFile) {
    if (logFile == null) {
      throw new IllegalArgumentException();
    }
    if (getFlutterEngine() == null) {
      Log.e(TAG, "Could not write timeline data - no engine.");
      return;
    }
    final BasicMessageChannel<ByteBuffer> channel =
        new BasicMessageChannel<>(
            getFlutterEngine().getDartExecutor(), "write_timeline", BinaryCodec.INSTANCE);
    channel.send(
        null,
        (ByteBuffer reply) -> {
          try {
            final FileDescriptor fd =
                getContentResolver().openAssetFileDescriptor(logFile, "w").getFileDescriptor();
            final FileOutputStream outputStream = new FileOutputStream(fd);
            outputStream.write(reply.array());
            outputStream.close();
          } catch (IOException ex) {
            Log.e(TAG, "Could not write timeline file: " + ex.toString());
          }
          finish();
        });
  }

  /**
   * This method verifies that {@link FlutterLoader#ensureInitializationCompleteAsync(Context,
   * String[], Handler, Runnable)} invokes its callback when called after initialization.
   */
  private void testFlutterLoaderCallbackWhenInitializedTwice() {
    FlutterLoader flutterLoader = new FlutterLoader();

    // Flutter is probably already loaded in this app based on
    // code that ran before this method. Nonetheless, invoke the
    // blocking initialization here to ensure it's initialized.
    flutterLoader.startInitialization(getApplicationContext());
    flutterLoader.ensureInitializationComplete(getApplication(), new String[] {});

    // Now that Flutter is loaded, invoke ensureInitializationCompleteAsync with
    // a callback and verify that the callback is invoked.
    Handler mainHandler = new Handler(Looper.getMainLooper());

    final AtomicBoolean didInvokeCallback = new AtomicBoolean(false);

    flutterLoader.ensureInitializationCompleteAsync(
        getApplication(),
        new String[] {},
        mainHandler,
        new Runnable() {
          @Override
          public void run() {
            didInvokeCallback.set(true);
          }
        });

    mainHandler.post(
        new Runnable() {
          @Override
          public void run() {
            if (!didInvokeCallback.get()) {
              throw new RuntimeException(
                  "Failed test: FlutterLoader#ensureInitializationCompleteAsync() did not invoke its callback.");
            }
          }
        });
  }
}

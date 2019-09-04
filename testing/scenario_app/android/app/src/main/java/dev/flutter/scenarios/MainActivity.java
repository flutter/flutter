package dev.flutter.scenarios;

import android.Manifest;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.NonNull;

import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryCodec;

public class MainActivity extends FlutterActivity {
  final static String TAG = "Scenarios";

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
      new Handler().postDelayed(() -> writeTimelineData(logFileUri), 20000);
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
    flutterEngine.getPlatformViewsController()
                 .getRegistry()
                 .registerViewFactory(
                   "scenarios/textPlatformView",
                   new TextPlatformViewFactory());
  }


  private void writeTimelineData(Uri logFile) {
    if (logFile == null) {
      throw new IllegalArgumentException();
    }
    if (getFlutterEngine() == null) {
      Log.e(TAG, "Could not write timeline data - no engine.");
      return;
    }
    final BasicMessageChannel<ByteBuffer> channel = new BasicMessageChannel<>(
        getFlutterEngine().getDartExecutor(), "write_timeline", BinaryCodec.INSTANCE);
    channel.send(null, (ByteBuffer reply) -> {
      try {
        final FileDescriptor fd = getContentResolver()
                                          .openAssetFileDescriptor(logFile, "w")
                                          .getFileDescriptor();
        final FileOutputStream outputStream = new FileOutputStream(fd);
        outputStream.write(reply.array());
        outputStream.close();
      } catch (IOException ex) {
        Log.e(TAG, "Could not write timeline file: " + ex.toString());
      }
      finish();
    });
  }
}

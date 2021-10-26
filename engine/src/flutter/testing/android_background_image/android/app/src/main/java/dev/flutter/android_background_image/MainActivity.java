// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.android_background_image;

import android.content.Intent;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import java.nio.ByteBuffer;

public class MainActivity extends FlutterActivity {
  @NonNull
  private final BinaryMessenger.BinaryMessageHandler finishHandler =
      new BinaryMessenger.BinaryMessageHandler() {
        @Override
        public void onMessage(ByteBuffer message, final BinaryMessenger.BinaryReply callback) {
          if (message != null) {
            // Make CI see that there is an error in the logs from Flutter.
            Log.e("flutter", "Images did not match.");
          }
          final Intent intent = new Intent(MainActivity.this, MainActivity.class);
          intent.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
          MainActivity.this.startActivity(intent);
          MainActivity.this.finish();
        }
      };

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    flutterEngine.getDartExecutor().getBinaryMessenger().setMessageHandler("finish", finishHandler);

    final boolean moved = moveTaskToBack(true);
    if (!moved) {
      Log.e("flutter", "Failed to move to back.");
      finish();
    }
  }
}

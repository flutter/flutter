package io.flutter.androidembedding.fullscreen;

import android.content.Context;
import android.content.Intent;
import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;

public class FullscreenFlutterActivity {
  public static Intent newIntent(@NonNull Context context) {
    return FlutterActivity.createBuilder()
        .dartEntrypoint("fullscreenFlutter")
        .build(context);
  }
}

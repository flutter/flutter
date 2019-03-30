package io.flutter.androidembedding.fullscreen;

import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;

public class FullscreenFlutterActivity {
  public static Intent newIntent(@NonNull Context context) {
    return new FlutterActivity.IntentBuilder()
        .dartEntrypoint("fullscreenFlutter")
        .build(context);
  }
}

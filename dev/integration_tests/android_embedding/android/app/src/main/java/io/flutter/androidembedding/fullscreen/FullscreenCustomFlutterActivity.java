package io.flutter.androidembedding.fullscreen;

import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import io.flutter.androidembedding.App;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.engine.FlutterEngine;

public class FullscreenCustomFlutterActivity extends FlutterActivity implements FlutterFragment.FlutterEngineProvider {
  public static Intent createDefaultIntent(@NonNull Context context) {
    return new IntentBuilder()
        .dartEntrypoint("fullscreenFlutter")
        .build(context);
  }

  private static class IntentBuilder extends FlutterActivity.IntentBuilder {
    IntentBuilder() {
      super(FullscreenCustomFlutterActivity.class);
    }
  }

  private static FlutterEngine cachedEngine;

  @Nullable
  @Override
  public FlutterEngine getFlutterEngine(@NonNull Context context) {
    return ((App) getApplication()).cachedEngine;
//    if (cachedEngine == null) {
//      cachedEngine = new FlutterEngine(context);
//    }
//    return cachedEngine;
  }
}

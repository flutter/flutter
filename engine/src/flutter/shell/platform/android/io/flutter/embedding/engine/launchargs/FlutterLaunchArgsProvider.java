package io.flutter.embedding.engine.launchargs;

import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.FlutterShellArgs;

/** Provides Flutter shell arguments from an Intent. */
public interface FlutterLaunchArgsProvider {
  /** Returns the Flutter shell arguments from the given Intent. */
  @NonNull
  FlutterShellArgs getLaunchArgs(@Nullable Intent intent);
}

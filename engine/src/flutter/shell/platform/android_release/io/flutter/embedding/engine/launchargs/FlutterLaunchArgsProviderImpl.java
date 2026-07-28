package io.flutter.embedding.engine.launchargs;

import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.FlutterShellArgs;

/** Provides Flutter shell arguments from an Intent for release builds. */
public final class FlutterLaunchArgsProviderImpl implements FlutterLaunchArgsProvider {
  /** The singleton instance of this provider. */
  public static final FlutterLaunchArgsProviderImpl INSTANCE = new FlutterLaunchArgsProviderImpl();

  @Override
  @NonNull
  public FlutterShellArgs getLaunchArgs(@Nullable Intent intent) {
    // Release builds do not support engine configuration flags from Intent.
    return new FlutterShellArgs(new String[0]);
  }
}

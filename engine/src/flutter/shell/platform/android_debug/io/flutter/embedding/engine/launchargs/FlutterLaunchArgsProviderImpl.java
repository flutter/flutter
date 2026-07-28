package io.flutter.embedding.engine.launchargs;

import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.FlutterShellArgs;

/** Provides Flutter shell arguments from an Intent for non-release builds. */
public final class FlutterLaunchArgsProviderImpl implements FlutterLaunchArgsProvider {
  /** The singleton instance of this provider. */
  public static final FlutterLaunchArgsProviderImpl INSTANCE = new FlutterLaunchArgsProviderImpl();

  @Override
  @NonNull
  public FlutterShellArgs getLaunchArgs(@Nullable Intent intent) {
    if (intent == null) {
      return new FlutterShellArgs(new String[0]);
    }
    return FlutterShellArgs.fromIntent(intent);
  }
}

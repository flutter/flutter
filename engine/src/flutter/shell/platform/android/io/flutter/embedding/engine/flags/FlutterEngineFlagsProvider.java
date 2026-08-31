package io.flutter.embedding.engine.flags;

import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.List;

public interface FlutterEngineFlagsProvider {
  @NonNull
  List<String> getFlags(@Nullable Intent intent);
}

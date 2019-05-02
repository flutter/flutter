package io.flutter.androidembedding.single_activity;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterView;

public class ExampleFlutterFragment {
  @NonNull
  public static Fragment newInstance() {
    return new FlutterFragment.Builder()
        .renderMode(FlutterView.RenderMode.texture)
        .build();
  }
}

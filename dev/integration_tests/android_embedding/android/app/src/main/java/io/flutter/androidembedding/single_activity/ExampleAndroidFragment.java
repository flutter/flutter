package io.flutter.androidembedding.single_activity;

import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import io.flutter.androidembedding.R;

public class ExampleAndroidFragment extends Fragment {
  @NonNull
  public static ExampleAndroidFragment newInstance() {
    ExampleAndroidFragment fragment = new ExampleAndroidFragment();

    Bundle args = new Bundle();
    fragment.setArguments(args);

    return fragment;
  }

  @Nullable
  @Override
  public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
    return inflater.inflate(R.layout.fragment_example_android, null);
  }
}

package io.flutter.androidembedding.partial_flow;

import android.content.Context;
import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;

public class LoginActivity {

  @NonNull
  public static Intent newIntent(@NonNull Context context) {
    return FlutterActivity.createBuilder()
        .dartEntrypoint("loginScreen")
        .build(context);
  }

}

package io.flutter.androidembedding.partial_flow;

import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
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

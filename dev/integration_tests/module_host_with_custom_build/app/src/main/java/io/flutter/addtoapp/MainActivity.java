package io.flutter.addtoapp;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import io.flutter.facade.Flutter;

public class MainActivity extends AppCompatActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(Flutter.createView(this, getLifecycle(), "route1"));
  }
}

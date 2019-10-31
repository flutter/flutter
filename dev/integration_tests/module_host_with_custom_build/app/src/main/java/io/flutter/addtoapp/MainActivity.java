package io.flutter.addtoapp;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import io.flutter.facade.Flutter;

public class MainActivity extends AppCompatActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(Flutter.createView(this, getLifecycle(), "route1"));
  }
}

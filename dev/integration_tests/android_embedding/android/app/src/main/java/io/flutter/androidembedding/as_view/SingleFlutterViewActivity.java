package io.flutter.androidembedding.as_view;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.FrameLayout;

import io.flutter.androidembedding.R;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.view.FlutterMain;

public class SingleFlutterViewActivity extends AppCompatActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_single_flutter_view);

    FlutterMain.ensureInitializationComplete(getApplicationContext(), new String[]{});

    FlutterEngine flutterEngine = new FlutterEngine(this);
    flutterEngine.getDartExecutor().executeDartEntrypoint(
        new DartExecutor.DartEntrypoint(
            getAssets(),
            FlutterMain.findAppBundlePath(getApplicationContext()),
            "main"
        )
    );

    FlutterView flutterView = new FlutterView(this);
    flutterView.attachToFlutterEngine(flutterEngine);
    FrameLayout frameLayout = findViewById(R.id.framelayout);
    frameLayout.addView(flutterView);
  }
}
